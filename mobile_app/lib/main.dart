import 'package:flutter/material.dart';

import 'app/app_bootstrap.dart';
import 'app/app_root.dart';

Future<void> main() async {
  final bootstrap = await AppBootstrap.initialize();
  runApp(AppRoot(bootstrap: bootstrap));
}
