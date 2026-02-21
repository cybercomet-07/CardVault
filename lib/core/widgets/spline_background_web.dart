// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

class SplineBackground extends StatefulWidget {
  const SplineBackground({super.key});

  @override
  State<SplineBackground> createState() => _SplineBackgroundState();
}

class _SplineBackgroundState extends State<SplineBackground> {
  static const String _viewType = 'cardvault-spline-bg';
  static bool _registered = false;

  @override
  void initState() {
    super.initState();
    if (!_registered) {
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
        final iframe = html.IFrameElement()
          ..src = 'https://my.spline.design/interactivecardsbyahmadi-QYbRLNozeUZIWFiqARuFklaf/'
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.pointerEvents = 'none'
          ..allow = 'autoplay; fullscreen';
        return iframe;
      });
      _registered = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: _viewType);
  }
}
