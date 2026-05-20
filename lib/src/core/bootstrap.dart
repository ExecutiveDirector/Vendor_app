import 'package:hive_flutter/hive_flutter.dart';
import 'config.dart';
import 'services/local_storage.dart';

Future<void> bootstrap() async {
  await Hive.initFlutter();
  await LocalStorage.init();
}
