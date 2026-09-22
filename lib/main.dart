import 'package:flutter/widgets.dart';

import 'app/zephyr_app.dart';
import 'data/services/purewriter_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = PureWriterDatabase();
  await database.openDefaultLibrary();
  runZephyr(database);
}
