// lib/src/platform/background.dart
//
// Receber com a janela fechada (docs/PLANO.md, 7.5).
//
// No desktop, o ícone na bandeja, fechar a janela sem sair (o nó continua recebendo),
// abrir ao entrar no computador e trazer a janela à frente (pela bandeja ou pela
// notificação). No Linux, a bandeja é o StatusNotifierItem pelo D-Bus, sem o
// AppIndicator.
//
// No Android, o ReceiveService (em Kotlin): um serviço em primeiro plano, com uma
// notificação fixa e discreta, segura o processo e o motor do Flutter que a
// MainActivity guarda; o Dart continua com o nó e as notificações com a tela fechada.
// E o pedido, opcional, para o Chirp ficar fora da economia de bateria.
//
// Atrás de uma interface para os testes trocarem; no iOS, não faz nada (a Apple não
// deixa um app manter conexões abertas).
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nativeapi/nativeapi.dart' as n;
import 'package:nativeapi/nativeapi.dart' show LaunchAtLogin;
import 'package:nativeapi_flutter/nativeapi_flutter.dart' show ImageAsset;

/// O argumento de quem abre ao entrar no computador: a janela começa escondida.
const startHiddenArg = '--hidden';

/// Os textos do segundo plano, no idioma de quem usa.
typedef BackgroundTexts = ({
  /// O nome do app (a dica da bandeja, o título da notificação fixa).
  String name,

  /// "Abrir o Psito Chirp" e "Sair", no menu da bandeja.
  String open,
  String quit,

  /// O texto da notificação fixa do Android, e o nome do canal dela.
  String receiving,
  String channel,
});

abstract interface class Background {
  /// Dá para receber com a janela fechada (desktop e Android).
  bool get supported;

  /// No desktop, pela bandeja; no Android, pela notificação fixa.
  bool get tray;

  /// Com [keepRunning], fechar a janela só esconde (o ícone fica na bandeja, ou a
  /// notificação fixa no Android); sem, fechar sai, e a janela aparece se estava
  /// escondida.
  Future<void> setup({
    required bool keepRunning,
    required BackgroundTexts texts,
  });

  /// Mostra a janela e dá o foco.
  Future<void> bringToFront();

  /// Esconde a janela (ao abrir com o computador).
  Future<void> hide();

  /// O sistema deixa abrir o app ao entrar.
  bool get canStartAtLogin;

  bool get startsAtLogin;

  /// Liga ou desliga; diz se o sistema aceitou.
  bool setStartAtLogin(bool on);

  /// A economia de bateria do sistema pode atrasar a rede (no Android).
  Future<bool> batteryRestricted();

  /// Pede ao sistema para o Chirp ficar fora da economia de bateria.
  Future<void> askUnrestrictedBattery();
}

/// No iOS e onde não há como receber com o app fechado.
class NoBackground implements Background {
  const NoBackground();

  @override
  bool get supported => false;

  @override
  bool get tray => false;

  @override
  Future<void> setup({
    required bool keepRunning,
    required BackgroundTexts texts,
  }) async {}

  @override
  Future<void> bringToFront() async {}

  @override
  Future<void> hide() async {}

  @override
  bool get canStartAtLogin => false;

  @override
  bool get startsAtLogin => false;

  @override
  bool setStartAtLogin(bool on) => false;

  @override
  Future<bool> batteryRestricted() async => false;

  @override
  Future<void> askUnrestrictedBattery() async {}
}

/// O de cada sistema: o desktop, o Android, ou nada (no iOS).
Background systemBackground() {
  if (kIsWeb) return const NoBackground();
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    return DesktopBackground();
  }
  if (Platform.isAndroid) return const AndroidBackground();
  return const NoBackground();
}

/// O Android: o serviço em primeiro plano e a bateria, pelo canal da MainActivity.
class AndroidBackground implements Background {
  const AndroidBackground();

  static const _channel = MethodChannel('org.psito.chirp/background');

  @override
  bool get supported => true;

  @override
  bool get tray => false;

  @override
  Future<void> setup({
    required bool keepRunning,
    required BackgroundTexts texts,
  }) async {
    try {
      if (keepRunning) {
        await _channel.invokeMethod<void>('start', {
          'title': texts.name,
          'text': texts.receiving,
          'channel': texts.channel,
        });
      } else {
        await _channel.invokeMethod<void>('stop');
      }
    } on PlatformException catch (error) {
      debugPrint('segundo plano: ${error.code}');
    }
  }

  @override
  Future<void> bringToFront() async {}

  @override
  Future<void> hide() async {}

  @override
  bool get canStartAtLogin => false;

  @override
  bool get startsAtLogin => false;

  @override
  bool setStartAtLogin(bool on) => false;

  @override
  Future<bool> batteryRestricted() async {
    try {
      return await _channel.invokeMethod<bool>('batteryRestricted') ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> askUnrestrictedBattery() async {
    try {
      await _channel.invokeMethod<void>('askUnrestrictedBattery');
    } on PlatformException catch (error) {
      debugPrint('bateria: ${error.code}');
    }
  }
}

class DesktopBackground implements Background {
  DesktopBackground();

  bool _keepRunning = false;
  n.Window? _window;
  n.TrayIcon? _tray;
  final List<Object> _keep = [];
  LaunchAtLogin? _login;

  n.Window? get _current {
    if (_window != null) return _window;
    try {
      final window = n.WindowManager.instance.getCurrent();
      window?.addListener(_onWindow);
      return _window = window;
    } on Object {
      return null;
    }
  }

  @override
  bool get supported => true;

  @override
  bool get tray => true;

  @override
  Future<bool> batteryRestricted() async => false;

  @override
  Future<void> askUnrestrictedBattery() async {}

  @override
  Future<void> setup({
    required bool keepRunning,
    required BackgroundTexts texts,
  }) async {
    _keepRunning = keepRunning;
    final window = _current;
    if (keepRunning) {
      _showTray(tooltip: texts.name, open: texts.open, quit: texts.quit);
    } else {
      _hideTray();
      // Sem a bandeja, uma janela escondida ficaria sem caminho de volta.
      if (window != null && !window.isVisible) await bringToFront();
    }
  }

  void _showTray({
    required String tooltip,
    required String open,
    required String quit,
  }) {
    try {
      var tray = _tray;
      if (tray == null) {
        tray = n.TrayIcon.create();
        if (tray == null) return;
        final icon = ImageAsset.fromAsset('assets/images/tray.png');
        if (icon != null) {
          tray.icon = icon;
          _keep.add(icon);
        }
        tray.addListener((event) {
          if (event is n.TrayIconClickedEvent) unawaited(bringToFront());
        });
        _tray = tray;
      }
      tray.setTooltip(tooltip);
      final menu = n.Menu.create();
      if (menu != null) {
        menu
          ..addItem(_item(open, () => unawaited(bringToFront())))
          ..addSeparator()
          ..addItem(_item(quit, _quit));
        tray.setContextMenu(menu);
        // No Linux, o painel mostra o menu exportado só com isso.
        if (Platform.isLinux) {
          tray.setContextMenuTrigger(n.ContextMenuTrigger.rightClicked);
        }
        _keep.add(menu);
      }
      tray.setVisible(true);
    } on Object catch (error) {
      debugPrint('bandeja: $error');
    }
  }

  n.MenuItem _item(String label, VoidCallback onClick) {
    final item = n.MenuItem.createWithLabelAndType(
      label,
      n.MenuItemType.normal,
    )!;
    item.addListener((event) {
      if (event is n.MenuItemClickedEvent) onClick();
    });
    _keep.add(item);
    return item;
  }

  void _hideTray() {
    _tray?.setVisible(false);
  }

  void _onWindow(n.WindowEvent event) {
    if (event case n.WindowCloseRequestedEvent(:final request)) {
      if (_keepRunning) {
        request.cancel();
        _current?.hide();
      }
    }
  }

  void _quit() {
    _keepRunning = false;
    _hideTray();
    n.Application.instance.quit(0);
  }

  @override
  Future<void> bringToFront() async {
    final window = _current;
    if (window == null) return;
    if (window.isMinimized) window.restore();
    window
      ..show()
      ..focus();
  }

  @override
  Future<void> hide() async => _current?.hide();

  LaunchAtLogin? get _launch {
    if (_login != null) return _login;
    try {
      if (!LaunchAtLogin.isSupported()) return null;
      final login = LaunchAtLogin.createWithIdAndDisplayName(
        'org.psito.chirp',
        'Psito Chirp',
      );
      login?.setProgram(Platform.resolvedExecutable, const [startHiddenArg]);
      return _login = login;
    } on Object {
      return null;
    }
  }

  @override
  bool get canStartAtLogin => _launch != null;

  @override
  bool get startsAtLogin => _launch?.isEnabled ?? false;

  @override
  bool setStartAtLogin(bool on) {
    final launch = _launch;
    if (launch == null) return false;
    return on ? launch.enable() : launch.disable();
  }
}

/// O segundo plano, para as telas.
class BackgroundScope extends InheritedWidget {
  const BackgroundScope({
    super.key,
    required this.background,
    required super.child,
  });

  final Background background;

  static Background of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BackgroundScope>()
          ?.background ??
      const NoBackground();

  @override
  bool updateShouldNotify(BackgroundScope oldWidget) =>
      background != oldWidget.background;
}
