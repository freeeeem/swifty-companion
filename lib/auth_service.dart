import 'dart:convert';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'models/correction_models.dart';

class AuthService {
  // Clés d'API 42 chargées dynamiquement depuis le fichier .env
  static final String _clientId = dotenv.env['CLIENT_ID'] ?? '';
  static final String _clientSecret = dotenv.env['CLIENT_SECRET'] ?? '';
  static final String _webRedirectUri =
      dotenv.env['REDIRECT_URI_WEB'] ?? '${Uri.base.origin}/auth.html';

  // L'URI de redirection configuré sur votre application Intra 42.
  static String get _redirectUri =>
      kIsWeb ? _webRedirectUri : 'mycompanion://oauth-callback';

  static const String _tokenUrl = 'https://api.intra.42.fr/oauth/token';

  // Marge de sécurité avant expiration (30 s) pour rafraîchir à l'avance.
  static const Duration _expiryMargin = Duration(seconds: 30);

  // ==========================================================================
  // Gestion du cycle de vie du token (stockage + refresh automatique)
  // ==========================================================================

  /// Sauvegarde les tokens et la date d'expiration calculée.
  static Future<void> _persistTokens(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final String accessToken = data['access_token'] as String;
    final String? refreshToken = data['refresh_token'] as String?;
    final int expiresIn = (data['expires_in'] as num?)?.toInt() ?? 7200;
    final int createdAt =
        (data['created_at'] as num?)?.toInt() ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000);

    final DateTime expiresAt = DateTime.fromMillisecondsSinceEpoch(
      createdAt * 1000,
    ).add(Duration(seconds: expiresIn));

    await prefs.setString('access_token', accessToken);
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }
    await prefs.setInt('token_expires_at', expiresAt.millisecondsSinceEpoch);
  }

  /// Retourne un token d'accès valide :
  /// - le token courant s'il n'est pas (bientôt) expiré ;
  /// - sinon, un token fraîchement obtenu via le refresh token ;
  /// - sinon null (l'appelant doit considérer l'utilisateur déconnecté).
  ///
  /// En cas d'échec réseau du refresh, le token courant est retourné tel quel
  /// (best effort) afin que l'application continue de fonctionner si possible.
  static Future<String?> _getValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('access_token');
    final String? refreshToken = prefs.getString('refresh_token');
    final int? expiresAtMs = prefs.getInt('token_expires_at');

    // Token encore valide (avec marge de sécurité) ?
    if (accessToken != null && expiresAtMs != null) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMs);
      if (DateTime.now().isBefore(expiresAt.subtract(_expiryMargin))) {
        return accessToken;
      }
    }

    // Pas de refresh token possible : on garde le token courant en dernier
    // recours (l'API répondra 401 si elle le refuse vraiment).
    if (refreshToken == null) return accessToken;

    // Tentative de refresh
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        body: {
          'grant_type': 'refresh_token',
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        await _persistTokens(data);
        debugPrint('Token rafraîchi avec succès.');
        return data['access_token'] as String;
      }

      // Refresh token révoqué / invalide : la session est morte.
      debugPrint(
        'Refresh refusé (${response.statusCode}), déconnexion implicite.',
      );
      await _clearTokens();
      return null;
    } catch (e) {
      // Erreur réseau : on retente avec l'ancien token (best effort).
      debugPrint('Erreur réseau durant le refresh : $e');
      return accessToken;
    }
  }

  /// Requête GET authentifiée avec retry automatique en cas de 401
  /// (token invalide côté serveur malgré une expiration locale correcte).
  static Future<http.Response?> _authorizedGet(Uri uri) async {
    String? token = await _getValidAccessToken();
    if (token == null) return null;

    http.Response response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    // 401 : le token a été révoqué côté serveur -> refresh forcé + 1 retry.
    if (response.statusCode == 401) {
      await _clearTokens();
      token = await _getValidAccessToken();
      if (token == null) return null;
      response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
    }

    // 429 : rate limit -> on attend (Retry-After, 1 s par défaut) puis
    // on retente une seule fois.
    if (response.statusCode == 429) {
      response = await _retryOnRateLimit(
        response,
        () => http.get(uri, headers: {'Authorization': 'Bearer $token'}),
      );
    }

    // 5xx : erreurs transitoires de l'API intra (elle est notoirement
    // capricieuse) -> 1 retry après 1 s.
    if (response.statusCode >= 500) {
      await Future.delayed(const Duration(seconds: 1));
      response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
    }

    return response;
  }

  /// Attend la durée indiquée par l'en-tête Retry-After (1 s par défaut,
  /// plafonnée à 5 s) puis retente une seule fois la requête.
  static Future<http.Response> _retryOnRateLimit(
    http.Response response,
    Future<http.Response> Function() perform,
  ) async {
    final int? retryAfterSeconds =
        int.tryParse(response.headers['retry-after'] ?? '');
    final int delayMs =
        ((retryAfterSeconds ?? 1) * 1000).clamp(1000, 5000);
    await Future.delayed(Duration(milliseconds: delayMs));
    return perform();
  }

  static Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expires_at');
  }

  // ==========================================================================
  // Flux OAuth2
  // ==========================================================================

  /// 1. Lancer le flux d'authentification OAuth2
  static Future<String?> loginWith42() async {
    try {
      // Construction de l'URL d'autorisation
      final Uri authorizeUrl =
          Uri.https('api.intra.42.fr', '/oauth/authorize', {
            'client_id': _clientId,
            'redirect_uri': _redirectUri,
            'response_type': 'code',
            // 'projects' : requis pour les créneaux de correction (slots)
            // et les scale_teams (cf. message d'erreur "Insufficient scope").
            'scope': 'public projects',
          });

      // Ouvre le navigateur sécurisé et attend que l'utilisateur se connecte
      final String callbackUrl = await FlutterWebAuth2.authenticate(
        url: authorizeUrl.toString(),
        callbackUrlScheme: kIsWeb ? 'http' : 'mycompanion',
      );

      // Extraction du code d'autorisation depuis l'URL de retour
      final String? code = Uri.parse(callbackUrl).queryParameters['code'];
      if (code == null) return null;

      // Échange du code d'autorisation contre le token d'accès
      return await _exchangeCodeForToken(code);
    } catch (e) {
      debugPrint('Erreur d\'authentification: $e');
      return null;
    }
  }

  /// 2. Échanger le code temporaire contre le token final
  static Future<String?> _exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        body: {
          'grant_type': 'authorization_code',
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': code,
          'redirect_uri': _redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        await _persistTokens(data);
        return data['access_token'] as String;
      }

      debugPrint('Échec de l\'échange de token : ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Erreur réseau durant l\'échange de token : $e');
      return null;
    }
  }

  /// Indique si une session utilisable existe (token présent, même expiré :
  /// un refresh token valide permettra de le rafraîchir).
  static Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }

  // ==========================================================================
  // Appels API
  // ==========================================================================

  /// 3. Récupérer les données de l'utilisateur connecté (/v2/me)
  static Future<Map<String, dynamic>?> getMe() async {
    return _apiGet(Uri.parse('https://api.intra.42.fr/v2/me'), '/v2/me');
  }

  /// 4. Récupérer les données d'un étudiant par son login (/v2/users/login)
  static Future<Map<String, dynamic>?> getUserProfile(String login) async {
    return _apiGet(
      Uri.parse('https://api.intra.42.fr/v2/users/$login'),
      '/v2/users/$login',
    );
  }

  /// Requête GET authentifiée renvoyant une liste JSON (endpoints "collection").
  /// [onResponse] permet à l'appelant de réagir au code HTTP brut.
  /// [quiet] désactive les logs d'échec — pour les endpoints d'une chaîne
  /// de repli dont l'échec est attendu (un repli réussit derrière).
  static Future<List<dynamic>?> _apiGetList(
    Uri uri,
    String label, {
    void Function(int statusCode)? onResponse,
    bool quiet = false,
  }) async {
    try {
      final response = await _authorizedGet(uri);
      if (response == null) {
        if (!quiet) {
          debugPrint('Session invalide pour $label (token non disponible).');
        }
        return null;
      }
      onResponse?.call(response.statusCode);
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      if (!quiet) {
        // On logge un extrait du corps : les messages d'erreur de l'API 42
        // expliquent souvent le refus (filtre non supporté, scope, etc.).
        final body = response.body;
        debugPrint(
          'Échec de $label : ${response.statusCode} '
          '${body.length > 300 ? '${body.substring(0, 300)}…' : body}',
        );
      }
      return null;
    } catch (e) {
      if (!quiet) debugPrint('Erreur réseau sur $label : $e');
      return null;
    }
  }

  /// Circuit breaker : /v2/users/:id/slots renvoie 500 sur certains comptes
  /// (données anciennes cassées côté intra). On mémorise l'échec en mémoire
  /// pour ne pas retenter l'endpoint — et subir son délai de retry — à
  /// chaque chargement pendant la session.
  static bool _slotsEndpointBroken = false;

  /// 5. Récupérer les créneaux de correction d'un étudiant
  /// (/v2/users/:id/slots). Appelé sans paramètre : cet endpoint renvoie
  /// des 500 quand on lui passe un range[begin_at] ; le filtrage par
  /// fenêtre de dates est donc fait côté client.
  static Future<List<dynamic>?> getUserSlots(int userId) {
    if (_slotsEndpointBroken) {
      return Future.value(null);
    }
    return _apiGetList(
      Uri.parse('https://api.intra.42.fr/v2/users/$userId/slots'),
      '/v2/users/$userId/slots',
      // quiet : ce premier maillon échoue souvent (500 sur comptes avec
      // données anciennes) mais la chaîne de repli prend le relais —
      // inutile de polluer la console.
      quiet: true,
      onResponse: (statusCode) {
        if (statusCode >= 500) _slotsEndpointBroken = true;
      },
    );
  }

  /// 5b. /v2/me/slots : variante qui cible directement l'utilisateur du
  /// token — utile quand /v2/users/:id/slots plante côté intra.
  static Future<List<dynamic>?> getMeSlots() {
    return _apiGetList(
      Uri.parse('https://api.intra.42.fr/v2/me/slots'),
      '/v2/me/slots',
      // quiet : maillon intermédiaire de la chaîne de repli, l'échec est
      // attendu si le repli suivant réussit (cf. getSlotsByIds).
      quiet: true,
    );
  }

  /// 5c. Récupère des slots précis par IDs (filtre accepté sur l'index
  /// /v2/slots). Utilisé avec les IDs des slots créés depuis l'app.
  static Future<List<dynamic>?> getSlotsByIds(List<int> ids) {
    if (ids.isEmpty) {
      return Future.value(null);
    }
    final label = '/v2/slots?filter[id]=${ids.join(',')}';
    return _apiGetList(
      Uri.https('api.intra.42.fr', '/v2/slots', {
        'filter[id]': ids.join(','),
        'page[size]': '100',
      }),
      label,
    );
  }

  /// Requête authentifiée non-GET (POST, DELETE) avec retry 401,
  /// en miroir de _authorizedGet.
  static Future<http.Response?> _authorizedSend(
    Future<http.Response> Function(String token) perform,
  ) async {
    String? token = await _getValidAccessToken();
    if (token == null) return null;

    http.Response response = await perform(token);

    // 401 : le token a été révoqué côté serveur -> refresh forcé + 1 retry.
    if (response.statusCode == 401) {
      await _clearTokens();
      token = await _getValidAccessToken();
      if (token == null) return null;
      response = await perform(token);
    }

    // 429 : rate limit -> on attend puis on retente une seule fois.
    if (response.statusCode == 429) {
      final String currentToken = token;
      response = await _retryOnRateLimit(response, () => perform(currentToken));
    }

    return response;
  }

  /// Extrait le message d'erreur renvoyé par l'API 42 (formats variés selon
  /// l'endpoint : {"error": "..."}, {"errors": {...}} ou {"errors": [...]}).
  static String _extractApiError(http.Response response) {
    try {
      final dynamic data = json.decode(response.body);
      if (data is Map) {
        final dynamic error = data['error'];
        if (error is String && error.isNotEmpty) return error;
        final dynamic errors = data['errors'];
        if (errors is Map) {
          return errors.entries
              .map((e) =>
                  '${e.key} : ${e.value is List ? e.value.join(', ') : e.value}')
              .join(' · ');
        }
        if (errors is List) return errors.join(', ');
      }
    } catch (_) {}
    return 'erreur ${response.statusCode}';
  }

  /// 8. Proposer un créneau de correction (POST /v2/slots) : rend
  /// l'utilisateur disponible en tant que correcteur sur ce créneau.
  /// L'API exige slot[user_id] (sinon 404), un créneau futur, une fin
  /// postérieure au début, et pas de chevauchement avec un créneau existant.
  /// Retourne (error: null, created: le slot) en cas de succès, sinon
  /// (error: message de l'API, created: null).
  static Future<(String? error, CorrectionSlot? created)> createSlot(
    int userId,
    DateTime beginAt,
    DateTime endAt,
  ) async {
    try {
      final response = await _authorizedSend((token) {
        return http.post(
          Uri.parse('https://api.intra.42.fr/v2/slots'),
          headers: {'Authorization': 'Bearer $token'},
          body: {
            'slot[user_id]': '$userId',
            'slot[begin_at]': beginAt.toUtc().toIso8601String(),
            'slot[end_at]': endAt.toUtc().toIso8601String(),
          },
        );
      });
      if (response == null) {
        return ('session invalide, reconnectez-vous', null);
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // L'API 42 peut renvoyer un corps vide ou non conforme alors que
        // le créneau a bien été créé : on considère quand même le succès,
        // le slot apparaîtra au rechargement.
        CorrectionSlot? slot;
        try {
          final dynamic data = json.decode(response.body);
          if (data is Map<String, dynamic>) {
            slot = CorrectionSlot.fromJson(data);
          }
        } catch (_) {}
        return (null, slot);
      }
      debugPrint(
        'Échec de création de slot (${response.statusCode}) : ${response.body}',
      );
      return (_extractApiError(response), null);
    } catch (e) {
      debugPrint('Erreur réseau sur POST /v2/slots : $e');
      return ('erreur réseau : $e', null);
    }
  }

  /// 9. Supprimer un créneau de correction (DELETE /v2/slots/:id).
  /// L'API n'accepte que ses propres créneaux, non réservés et futurs.
  /// Retourne null en cas de succès, sinon le message d'erreur de l'API.
  static Future<String?> deleteSlot(int slotId) async {
    try {
      final response = await _authorizedSend((token) {
        return http.delete(
          Uri.parse('https://api.intra.42.fr/v2/slots/$slotId'),
          headers: {'Authorization': 'Bearer $token'},
        );
      });
      if (response == null) return 'session invalide, reconnectez-vous';
      if (response.statusCode == 204 || response.statusCode == 200) {
        return null;
      }
      debugPrint(
        'Échec de suppression de slot ($slotId, ${response.statusCode}) : '
        '${response.body}',
      );
      return _extractApiError(response);
    } catch (e) {
      debugPrint('Erreur réseau sur DELETE /v2/slots/$slotId : $e');
      return 'erreur réseau : $e';
    }
  }

  static Future<Map<String, dynamic>?> _apiGet(Uri uri, String label) async {
    try {
      final response = await _authorizedGet(uri);
      if (response == null) {
        debugPrint('Session invalide pour $label (token non disponible).');
        return null;
      }
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      debugPrint('Échec de $label : ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Erreur réseau sur $label : $e');
      return null;
    }
  }

  /// 7. Déconnexion (suppression de tous les tokens stockés)
  static Future<void> logout() async {
    await _clearTokens();
  }
}
