import 'package:chirp/config/service_locator.dart';
import 'package:chirp/app/controllers/chirp_controller.dart';
import 'package:chirp/app/routes.dart';
import 'package:chirp/infrastructure/services/identity_service.dart';
import 'package:flutter/material.dart';
import 'package:chirp/app/themes/theme.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await Hive.initFlutter();
    await setupGlobalLocator();

    final identityService = getIt<IdentityService>();
    final currentIdentity = await identityService.loadOrCreateIdentity();
    await configureSession(currentIdentity);

    runApp(const ChirpBootstrapper());
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text("Erro ao iniciar bando: $e"))),
      ),
    );
  }
}

class ChirpBootstrapper extends StatefulWidget {
  const ChirpBootstrapper({super.key});

  @override
  State<ChirpBootstrapper> createState() => _ChirpBootstrapperState();
}

class _ChirpBootstrapperState extends State<ChirpBootstrapper> {
  Key _appKey = UniqueKey();

  void rebuildSession() {
    setState(() {
      _appKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _appKey,
      child: MultiProvider(
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
      initialRoute: ChirpRoutes.login,
      onGenerateRoute: ChirpRoutes.generateRoute,
    );
  }
}
