import 'package:chirp/app/widgets/screens/chat/chat_screen.dart';
import 'package:chirp/app/widgets/screens/chirp_qr/chirp_qr_screen.dart';
import 'package:chirp/app/widgets/screens/home/home_screen.dart';
import 'package:chirp/app/widgets/screens/profile/profile_screen.dart';
import 'package:chirp/domain/entities/chirp_member.dart';
import 'package:flutter/material.dart';

class ChirpRoutes {
  static const String home = '/';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String chirpQR = '/chirpqr';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case chat:
        {
          if (args is String) {
            return MaterialPageRoute(
              builder: (_) => ChatScreen(conversationId: args),
            );
          }
          return _errorRoute();
        }

      case profile:
        {
          if (args is ChirpMember) {
            return MaterialPageRoute(
              builder: (_) => ProfileScreen(member: args),
            );
          }

          return _errorRoute();
        }

      case chirpQR:
        {
          if (args is ChirpMember) {
            return MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => ChirpQRScreen(member: args),
            );
          }

          return _errorRoute();
        }

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
