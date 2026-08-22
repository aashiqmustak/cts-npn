// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildGoogleMapsIframe({
  required String mapQuery,
  required String viewId,
}) {
  final encoded = Uri.encodeComponent(mapQuery);
  final src = 'https://maps.google.com/maps?q=$encoded&t=&z=15&ie=UTF8&iwloc=B&output=embed';

  // Register Google Maps iframe view factory for Flutter Web
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int id) {
      final iframe = html.IFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true;
      return iframe;
    },
  );

  return HtmlElementView(viewType: viewId);
}
