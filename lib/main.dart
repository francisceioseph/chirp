import 'package:chirp/config/service_locator.dart';
import 'package:chirp/controllers/chirp_controller.dart';
import 'package:chirp/widgets/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:chirp/themes/theme.dart';
import 'package:provider/provider.dart';

void main() async {
  await setupLocator();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => getIt<ChirpController>()..startServices(),
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
      theme: ChirpThemes.sunnyLutino,
      darkTheme: ChirpThemes.greyWild,
      themeMode: ThemeMode.system,
      home: HomeScreen(),
    );
  }
}
