// lib/src/platform/notifier.dart
//
// As notificações do sistema (o D-Bus no Linux, o Windows, o macOS, o Android e o iOS,
// pelo flutter_local_notifications), atrás de uma interface para os testes trocarem.
// Uma notificação por contato: a nova troca a anterior, e abrir a conversa tira.
// O que vai nela (nada, o nome ou o texto) quem decide é a tela, pelo modo escolhido.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract interface class Notifier {
  /// Prepara (e pede a permissão onde o sistema pede: Android 13+, macOS e iOS).
  /// [open] é o nome da ação de abrir, e [channel] o do canal no Android. Diz se
  /// o sistema tem onde mostrar.
  Future<bool> init({required String open, required String channel});

  Future<void> show({
    required int contactId,
    required String title,
    required String body,
  });

  /// Tira a notificação do contato (a conversa foi aberta ou lida).
  Future<void> clear(int contactId);

  /// Os contatos cujas notificações foram clicadas.
  Stream<int> get opened;
}

class SystemNotifier implements Notifier {
  SystemNotifier();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _opened = StreamController<int>.broadcast();
  Future<bool>? _ready;
  String _channel = '';

  @override
  Stream<int> get opened => _opened.stream;

  @override
  Future<bool> init({required String open, required String channel}) {
    _channel = channel;
    return _ready ??= _init(open).catchError((Object _) => false);
  }

  Future<bool> _init(String open) async {
    const darwin = DarwinInitializationSettings();
    final ok = await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: darwin,
        macOS: darwin,
        linux: LinuxInitializationSettings(defaultActionName: open),
        windows: const WindowsInitializationSettings(
          appName: 'Psito Chirp',
          appUserModelId: 'Psito.Chirp',
          guid: '6f7d2c55-3a59-4f0e-9a37-1c1b5a1e8c42',
        ),
      ),
      onDidReceiveNotificationResponse: (response) => _tapped(response.payload),
    );
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
    // O app foi aberto pela notificação (no celular, com ele fechado). O Linux não
    // tem isso: lá, a notificação de um app fechado nem chega a ser clicável.
    if (defaultTargetPlatform != TargetPlatform.linux) {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _tapped(launch!.notificationResponse?.payload);
      }
    }
    return ok ?? false;
  }

  void _tapped(String? payload) {
    final id = int.tryParse(payload ?? '');
    if (id != null) _opened.add(id);
  }

  @override
  Future<void> show({
    required int contactId,
    required String title,
    required String body,
  }) async {
    if (!(await (_ready ?? Future.value(false)))) return;
    await _plugin.show(
      id: contactId,
      title: title,
      body: body,
      payload: '$contactId',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'messages',
          _channel,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.message,
          // Na tela bloqueada, o sistema esconde o texto (a menos que quem usa
          // tenha liberado nos ajustes do Android).
          visibility: NotificationVisibility.private,
        ),
        linux: const LinuxNotificationDetails(
          category: LinuxNotificationCategory.imReceived,
        ),
      ),
    );
  }

  @override
  Future<void> clear(int contactId) async {
    if (!(await (_ready ?? Future.value(false)))) return;
    await _plugin.cancel(id: contactId);
  }
}

/// Quem mostra as notificações, para as telas. Sem ele (os testes de integração), não
/// há notificações.
class NotifierScope extends InheritedWidget {
  const NotifierScope({
    super.key,
    required this.notifier,
    required super.child,
  });

  final Notifier? notifier;

  static Notifier? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NotifierScope>()?.notifier;

  @override
  bool updateShouldNotify(NotifierScope oldWidget) =>
      notifier != oldWidget.notifier;
}
