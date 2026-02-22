import 'package:chirp/app/controllers/friendship_controller.dart';
import 'package:chirp/app/controllers/presence_controller.dart';
import 'package:chirp/app/themes/symbian_themes/symbian_night_theme.dart';
import 'package:chirp/config/dependency_manager.dart';
import 'package:chirp/app/controllers/chirp_controller.dart';
import 'package:chirp/app/routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await DependencyManager().setup();

  runApp(
    MultiProvider(
      providers: [
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
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Chirp Talk",
      theme: SymbianNightSlateTheme.theme,
      darkTheme: SymbianNightSlateTheme.theme,
      themeMode: ThemeMode.system,
      initialRoute: ChirpRoutes.home,
      onGenerateRoute: ChirpRoutes.generateRoute,
    );
  }
}
