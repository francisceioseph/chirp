import 'package:flutter/material.dart';
import 'package:chirp/themes/theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Chirp",
      theme: ChirpThemes.sunnyLutino,
      darkTheme: ChirpThemes.greyWild,
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: Center(
          child: Text(
            'Chirp',
            style: TextStyle(fontSize: 56.0, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
