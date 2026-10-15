import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth_service.dart';

/// Avatar d'un utilisateur 42, compatible toutes plateformes.
///
/// **Pourquoi ce widget n'utilise pas `Image.network`.**
/// Le CDN de 42 (`cdn.intra.42.fr`) exige désormais un en-tête
/// `Authorization: Bearer <token>` : sans lui — ou avec un token invalide — il
/// répond `403 Forbidden`, y compris sur `/` et `/robots.txt`. Vérifié en
/// direct : `200 image/jpeg` avec l'en-tête, `403` sans, et le paramètre
/// `?access_token=` n'est pas accepté non plus.
///
/// Or `Image.network` ne permet pas d'envoyer cet en-tête de façon portable :
/// sur le web, le paramètre `headers` est ignoré. On télécharge donc les octets
/// nous-mêmes avec `package:http`, puis on les affiche via `Image.memory`.
/// Résultat : un seul code pour iOS, Android, desktop et web, sans vue de
/// plateforme ni `HtmlElementView`.
class AvatarImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Widget affiché tant que l'image n'est pas disponible (chargement en cours,
  /// URL invalide, CDN en erreur, utilisateur sans photo).
  final Widget fallback;

  const AvatarImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  /// Cache mémoire partagé entre toutes les instances : une liste de résultats
  /// réutilise souvent les mêmes URLs, on évite ainsi un aller-retour réseau à
  /// chaque reconstruction.
  static final Map<String, Uint8List> _cache = <String, Uint8List>{};

  /// Les avatars pèsent ~15 ko : 64 entrées restent négligeables en mémoire,
  /// tout en bornant la croissance sur les longues sessions.
  static const int _maxCacheEntries = 64;

  static void _remember(String url, Uint8List bytes) {
    if (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[url] = bytes;
  }

  @override
  State<AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<AvatarImage> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytes = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final String url = widget.url;

    final Uint8List? cached = AvatarImage._cache[url];
    if (cached != null) {
      if (mounted) setState(() => _bytes = cached);
      return;
    }

    // Sans session utilisable, inutile d'appeler le CDN : il répondrait 403.
    final String? token = await AuthService.getValidAccessToken();
    if (token == null) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    try {
      final http.Response response = await http.get(
        Uri.parse(url),
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw http.ClientException('HTTP ${response.statusCode}', Uri.parse(url));
      }
      AvatarImage._remember(url, response.bodyBytes);
      // Le widget a pu être retiré (recherche relancée, onglet changé) pendant
      // l'appel réseau : setState sur un State démonté lèverait une exception.
      if (mounted) setState(() => _bytes = response.bodyBytes);
    } catch (e) {
      debugPrint('Avatar indisponible ($url) : $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = _bytes;
    if (_failed || bytes == null) {
      return widget.fallback;
    }
    return Image.memory(
      bytes,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      // Évite un flash blanc quand le même widget change d'image.
      gaplessPlayback: true,
    );
  }
}