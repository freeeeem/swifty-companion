import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class AvatarImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget fallback;

  const AvatarImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  @override
  State<AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<AvatarImage> {
  static int _viewTypeSeed = 0;

  late String _viewType;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'avatar-image-${_viewTypeSeed++}';
    _registerViewFactory();
  }

  @override
  void didUpdateWidget(covariant AvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _failed = false;
      _viewType = 'avatar-image-${_viewTypeSeed++}';
      _registerViewFactory();
    }
  }

  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final image = html.ImageElement()
        ..src = widget.url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.display = 'block'
        ..style.pointerEvents = 'none'
        ..style.borderRadius = '50%';

      image.onError.first.then((_) {
        if (mounted) {
          setState(() => _failed = true);
        }
      });

      return image;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.fallback;
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}