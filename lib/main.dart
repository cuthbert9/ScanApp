import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ProviderScope is the root of all app state. Nothing above it holds any.
  runApp(const ProviderScope(child: ScanApp()));
}
