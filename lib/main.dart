import 'package:chirp/app/controllers/friendship_controller.dart';
import 'package:chirp/app/controllers/presence_controller.dart';
import 'package:chirp/config/service_locator.dart';
import 'package:chirp/app/controllers/chirp_controller.dart';
import 'package:chirp/app/routes.dart';
import 'package:flutter/material.dart';
import 'package:chirp/app/themes/theme.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await setupLocator();

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
      theme: ChirpThemes.slateFlat,
      darkTheme: ChirpThemes.slateFlat,
      themeMode: ThemeMode.system,
      initialRoute: ChirpRoutes.home,
      onGenerateRoute: ChirpRoutes.generateRoute,
    );
  }
}
