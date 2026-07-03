import 'dart:convert';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // Vos clés d'API 42 chargées dynamiquement depuis le fichier .env
  static final String _clientId = dotenv.env['CLIENT_ID'] ?? '';
  static final String _clientSecret = dotenv.env['CLIENT_SECRET'] ?? '';

  // L'URI de redirection configuré sur votre application Intra 42.
  static String get _redirectUri => kIsWeb
      ? 'http://localhost:8080/auth.html'
      : 'mycompanion://oauth-callback';

  // 1. Lancer le flux d'authentification OAuth2
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

      // Échange du code d'autorisation contre le Token d'accès
      return await _exchangeCodeForToken(code);
    } catch (e) {
      debugPrint('Erreur d\'authentification: $e');
      return null;
    }
  }

  // 2. Échanger le code temporaire contre le token final
  static Future<String?> _exchangeCodeForToken(String code) async {
    final Uri tokenUrl = Uri.parse('https://api.intra.42.fr/oauth/token');

    final response = await http.post(
      tokenUrl,
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
      final String accessToken = data['access_token'];

      // Sauvegarde locale du token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);

      return accessToken;
    } else {
      debugPrint('Échec de l\'échange de token : ${response.body}');
      return null;
    }
  }

  // 3. Récupérer les données de l'utilisateur connecté (/v2/me)
  static Future<Map<String, dynamic>?> getMe() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('https://api.intra.42.fr/v2/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      debugPrint('Échec de la récupération de /v2/me : ${response.statusCode}');
      return null;
    }
  }

  // 4. Récupérer les données d'un étudiant par son login (/v2/users/login)
  static Future<Map<String, dynamic>?> getUserProfile(String login) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('https://api.intra.42.fr/v2/users/$login'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      debugPrint(
        'Échec de la récupération du profil de $login : ${response.statusCode}',
      );
      return null;
    }
  }

  // 5. Déconnexion (Supprimer le token stocké)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }
}
