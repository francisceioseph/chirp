// lib/src/platform/desktop.dart
//
// O que o app faz no desktop além da janela (docs/PLANO.md, 7.5): o ícone na bandeja,
// fechar a janela sem sair (o nó continua recebendo), abrir ao entrar no computador e
// trazer a janela à frente (pela bandeja ou pela notificação). No Linux, a bandeja é o
// StatusNotifierItem pelo D-Bus, sem o AppIndicator. Atrás de uma interface para os
// testes trocarem; no celular, não faz nada.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nativeapi/nativeapi.dart' as n;
import 'package:nativeapi/nativeapi.dart' show LaunchAtLogin;
import 'package:nativeapi_flutter/nativeapi_flutter.dart' show ImageAsset;

/// O argumento de quem abre ao entrar no computador: a janela começa escondida.
const startHiddenArg = '--hidden';

abstract interface class Desktop {
  /// Há bandeja e janela para esconder (Linux, Windows e macOS).
  bool get supported;

  /// Com [keepRunning], fechar a janela só esconde e o ícone fica na bandeja; sem,
  /// fechar sai, e a janela aparece se estava escondida. [tooltip], [open] e [quit]
  /// são os textos da bandeja.
  Future<void> setup({
    required bool keepRunning,
    required String tooltip,
    required String open,
    required String quit,
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
}

/// No celular e onde não há janela de desktop.
class NoDesktop implements Desktop {
  const NoDesktop();

  @override
  bool get supported => false;

  @override
  Future<void> setup({
    required bool keepRunning,
    required String tooltip,
    required String open,
    required String quit,
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
}

class SystemDesktop implements Desktop {
  SystemDesktop();

  /// Só no desktop; no celular, o [NoDesktop].
  static Desktop create() =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
      ? SystemDesktop()
      : const NoDesktop();

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
  Future<void> setup({
    required bool keepRunning,
    required String tooltip,
    required String open,
    required String quit,
  }) async {
    _keepRunning = keepRunning;
    final window = _current;
    if (keepRunning) {
      _showTray(tooltip: tooltip, open: open, quit: quit);
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

/// O desktop, para as telas.
class DesktopScope extends InheritedWidget {
  const DesktopScope({super.key, required this.desktop, required super.child});

  final Desktop desktop;

  static Desktop of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DesktopScope>()?.desktop ??
      const NoDesktop();

  @override
  bool updateShouldNotify(DesktopScope oldWidget) =>
      desktop != oldWidget.desktop;
}
