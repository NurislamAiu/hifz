import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/app_paths.dart';
import 'data/hive/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.nurislam.hifz.audio',
    androidNotificationChannelName: 'Hifz audio',
    androidNotificationOngoing: true,
  );
  await AppPaths.init();
  await HiveBoxes.init();
  runApp(const ProviderScope(child: QuranMemoApp()));
}
