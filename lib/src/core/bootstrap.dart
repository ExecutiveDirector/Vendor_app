import 'package:hive_flutter/hive_flutter.dart';
import 'config.dart';
import 'router.dart';
import 'theme.dart';
import 'services/local_storage.dart';

late final appRouter = createRouter();
late final AppTheme theme = AppTheme();

Future<void> bootstrap() async {
  await Hive.initFlutter();
  await LocalStorage.init();
}
