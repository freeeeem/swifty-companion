import 'dart:convert';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

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

    return response;
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
            'scope': 'public',
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

  /// 5. Déconnexion (suppression de tous les tokens stockés)
  static Future<void> logout() async {
    await _clearTokens();
  }
}
