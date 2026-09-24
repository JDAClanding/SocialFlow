import 'package:flutter/widgets.dart';

/// Web / unsupported platforms: no embedded browser.
bool get canEmbedWeb => false;

Widget embeddedWeb(String url, {double height = 640}) => const SizedBox.shrink();
