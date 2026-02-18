import 'package:chirp/app/widgets/screens/chat/chat_screen.dart';
import 'package:chirp/app/widgets/screens/home/home_screen.dart';
import 'package:chirp/app/widgets/screens/login/login_screen.dart';
import 'package:flutter/material.dart';

class ChirpRoutes {
  static const String home = '/home';
  static const String chat = '/chat';
  static const String login = '/login';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case chat:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => ChatScreen(conversationId: args),
          );
        }
        return _errorRoute();

      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text('Rota não encontrada! O bando se perdeu.')),
      ),
    );
  }
}
