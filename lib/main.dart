import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap.dart';
import 'app/app.dart';

Future<void> main() async {
  final container = await bootstrap();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DoodhKhataApp(),
    ),
  );
}
