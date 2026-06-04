import 'dart:io';

import 'package:chirp/app/controllers/chat_controller.dart';
import 'package:chirp/app/controllers/friendship_controller.dart';
import 'package:chirp/app/controllers/presence_controller.dart';
import 'package:chirp/app/controllers/theme_controller.dart';
import 'package:chirp/config/dependency_manager.dart';
import 'package:chirp/app/controllers/chirp_controller.dart';
import 'package:chirp/app/routes.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final docDir = await getApplicationDocumentsDirectory();

  final appDirPath = p.join(docDir.path, "chirp-app");
  final appDir = Directory(appDirPath);

  if (!await appDir.exists()) {
    await appDir.create(recursive: true);
  }

  await Hive.initFlutter(appDir.path);
  await DependencyManager().setup();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          lazy: true,
          create: (_) => getIt<ChatController>(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => getIt<ChirpController>()..startServices(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => getIt<FriendshipController>(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => getIt<PresenceController>()..start(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => getIt<ThemeController>(),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      title: "Chirp Talk",
      theme: themeController.lightTheme,
      darkTheme: themeController.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: ChirpRoutes.home,
      onGenerateRoute: ChirpRoutes.generateRoute,
    );
  }
}
