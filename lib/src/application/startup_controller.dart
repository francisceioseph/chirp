// lib/src/application/startup_controller.dart
//
// A abertura do Chirp, como máquina de estados: do núcleo ao banco, e do banco ao
// perfil. Junta o núcleo e o cofre; a UI só desenha o estado e chama as intenções.
//
// Sem banco, a chave nova vai para o cofre; sem cofre, o banco nasce com uma senha.
// Com o banco, a chave vem do cofre (ou o problema: cofre mudo, chave perdida) ou da
// senha digitada. Aberto o banco, ou já existe um perfil (pronto) ou ele é criado.

import 'package:flutter/foundation.dart';

import '../core/chirp_core.dart';
import '../platform/key_vault.dart';

/// Por que a abertura parou.
enum StartupProblem {
  /// A biblioteca nativa não abriu.
  coreMissing,

  /// O cofre do sistema não respondeu (trancado, sem serviço).
  vaultUnavailable,

  /// O banco existe, mas a chave sumiu do cofre ou não abre mais.
  keyLost,

  /// O banco é de uma versão mais nova do Chirp.
  newerStore,

  /// Falha de disco ou do banco.
  storage,
}

@immutable
sealed class StartupState {
  const StartupState();
}

class StartupLoading extends StartupState {
  const StartupLoading();
}

class StartupProblemState extends StartupState {
  const StartupProblemState(this.problem);

  final StartupProblem problem;
}

/// Sem cofre: criar uma senha ([creating]) ou digitar a que já existe.
class StartupNeedsPassphrase extends StartupState {
  const StartupNeedsPassphrase({required this.creating, this.failure});

  final bool creating;

  /// O erro da última tentativa (senha errada ou curta).
  final CoreFailure? failure;
}

class StartupOnboarding extends StartupState {
  const StartupOnboarding({this.failure});

  final CoreFailure? failure;
}

class StartupReady extends StartupState {
  const StartupReady(this.profile);

  final Profile profile;
}

class StartupController extends ChangeNotifier {
  StartupController({required this.core, required this.vault});

  final ChirpCore core;
  final KeyVault vault;

  StartupState _state = const StartupLoading();
  StartupState get state => _state;

  /// Uma intenção em andamento (os botões ficam desligados).
  bool _busy = false;
  bool get busy => _busy;

  ProfileStore? _store;

  Future<void> start() async {
    _store = null;
    _set(const StartupLoading());
    if (core.info == null) {
      return _set(const StartupProblemState(StartupProblem.coreMissing));
    }
    try {
      switch (core.storeState()) {
        case StoreState.missing:
          await _createWithVault();
        case StoreState.keyInVault:
          await _openWithVault();
        case StoreState.passphrase:
          _set(const StartupNeedsPassphrase(creating: false));
      }
    } on CoreException catch (error) {
      _set(StartupProblemState(_problem(error.failure)));
    }
  }

  Future<void> _createWithVault() async {
    final Uint8List key;
    try {
      key = core.newStoreKey();
      await vault.write(key);
    } on VaultUnavailable {
      return _set(const StartupNeedsPassphrase(creating: true));
    }
    await _opened(await core.openWithKey(key));
  }

  Future<void> _openWithVault() async {
    final Uint8List? key;
    try {
      key = await vault.read();
    } on VaultUnavailable {
      return _set(const StartupProblemState(StartupProblem.vaultUnavailable));
    }
    if (key == null) {
      return _set(const StartupProblemState(StartupProblem.keyLost));
    }
    await _opened(await core.openWithKey(key));
  }

  Future<void> _opened(ProfileStore store) async {
    _store = store;
    final profile = await store.profile();
    _set(profile == null ? const StartupOnboarding() : StartupReady(profile));
  }

  /// Cria ou digita a senha, conforme o estado.
  Future<void> submitPassphrase(String passphrase) async {
    final state = _state;
    if (state is! StartupNeedsPassphrase || _busy) return;
    await _run(() async {
      try {
        final store = state.creating
            ? await core.createWithPassphrase(passphrase)
            : await core.openWithPassphrase(passphrase);
        await _opened(store);
      } on CoreException catch (error) {
        switch (error.failure) {
          case CoreFailure.wrongKey || CoreFailure.weakPassphrase:
            _set(
              StartupNeedsPassphrase(
                creating: state.creating,
                failure: error.failure,
              ),
            );
          default:
            _set(StartupProblemState(_problem(error.failure)));
        }
      }
    });
  }

  Future<void> createProfile(String name) async {
    final store = _store;
    if (_state is! StartupOnboarding || store == null || _busy) return;
    await _run(() async {
      try {
        _set(StartupReady(await store.createProfile(name)));
      } on CoreException catch (error) {
        _set(StartupOnboarding(failure: error.failure));
      }
    });
  }

  /// Troca o nome. Devolve a falha, ou nulo se deu certo.
  Future<CoreFailure?> rename(String name) async {
    final store = _store;
    if (_state is! StartupReady || store == null) return CoreFailure.storage;
    try {
      _set(StartupReady(await store.rename(name)));
      return null;
    } on CoreException catch (error) {
      return error.failure;
    }
  }

  /// Apaga o banco e tira a chave do cofre, e começa de novo.
  Future<void> wipeAndRestart() async {
    if (_busy) return;
    var wiped = false;
    await _run(() async {
      _store = null;
      try {
        await vault.delete();
      } on VaultUnavailable {
        // Sem o banco, uma chave que sobrou no cofre não abre nada.
      }
      try {
        await core.wipe();
        wiped = true;
      } on CoreException catch (error) {
        _set(StartupProblemState(_problem(error.failure)));
      }
    });
    if (wiped) await start();
  }

  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _set(StartupState state) {
    _state = state;
    notifyListeners();
  }

  static StartupProblem _problem(CoreFailure failure) => switch (failure) {
    CoreFailure.wrongKey || CoreFailure.badKey => StartupProblem.keyLost,
    CoreFailure.newerStore => StartupProblem.newerStore,
    _ => StartupProblem.storage,
  };
}
