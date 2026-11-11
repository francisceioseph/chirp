// A máquina de estados da abertura, com o núcleo e o cofre falsos.
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/src/application/startup_controller.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';

import 'helpers.dart';

void main() {
  Future<StartupController> started(FakeCore core, FakeVault vault) async {
    final controller = StartupController(core: core, vault: vault);
    addTearDown(controller.dispose);
    await controller.start();
    return controller;
  }

  test('a primeira abertura guarda a chave no cofre e pede o perfil', () async {
    final core = FakeCore();
    final vault = FakeVault();
    final c = await started(core, vault);
    expect(c.state, isA<StartupOnboarding>());
    expect(vault.key, core.storedKey);
    await c.createProfile('  Lutino ');
    expect((c.state as StartupReady).profile.displayName, 'Lutino');
  });

  test('a segunda abertura vai direto ao perfil', () async {
    final (core, vault) = await withProfile();
    final c = await started(core, vault);
    expect((c.state as StartupReady).profile.displayName, 'Lutino');
  });

  test('um nome inválido volta ao cadastro com o erro', () async {
    final c = await started(FakeCore(), FakeVault());
    await c.createProfile('   ');
    expect((c.state as StartupOnboarding).failure, CoreFailure.invalidName);
  });

  test('sem cofre, a primeira abertura pede uma senha nova', () async {
    final core = FakeCore();
    final c = await started(core, FakeVault(available: false));
    expect(c.state, isA<StartupNeedsPassphrase>());
    expect((c.state as StartupNeedsPassphrase).creating, isTrue);
    await c.submitPassphrase('curta');
    expect(
      (c.state as StartupNeedsPassphrase).failure,
      CoreFailure.weakPassphrase,
    );
    await c.submitPassphrase('calopsita lutino');
    expect(c.state, isA<StartupOnboarding>());
    expect(core.storeState(), StoreState.passphrase);
  });

  test('com senha, abre só com a certa', () async {
    final core = FakeCore();
    await (await core.createWithPassphrase('calopsita lutino'))
        .createProfile('Lutino');
    final c = await started(core, FakeVault(available: false));
    expect((c.state as StartupNeedsPassphrase).creating, isFalse);
    await c.submitPassphrase('outra coisa');
    expect((c.state as StartupNeedsPassphrase).failure, CoreFailure.wrongKey);
    await c.submitPassphrase('calopsita lutino');
    expect(c.state, isA<StartupReady>());
  });

  test('o cofre mudo com o banco existente não apaga nada', () async {
    final (core, vault) = await withProfile();
    vault.available = false;
    final c = await started(core, vault);
    expect(
      (c.state as StartupProblemState).problem,
      StartupProblem.vaultUnavailable,
    );
    expect(core.store, isNotNull);
    vault.available = true;
    await c.start();
    expect(c.state, isA<StartupReady>());
  });

  test('a chave fora do cofre é chave perdida', () async {
    final (core, vault) = await withProfile();
    vault.key = null;
    final c = await started(core, vault);
    expect((c.state as StartupProblemState).problem, StartupProblem.keyLost);
  });

  test('a chave errada no cofre também é chave perdida', () async {
    final (core, vault) = await withProfile();
    vault.key = core.newStoreKey();
    final c = await started(core, vault);
    expect((c.state as StartupProblemState).problem, StartupProblem.keyLost);
  });

  test('apagar tudo começa de novo, com chave nova', () async {
    final (core, vault) = await withProfile();
    final old = vault.key;
    vault.key = null;
    final c = await started(core, vault);
    await c.wipeAndRestart();
    expect(c.state, isA<StartupOnboarding>());
    expect(vault.key, isNot(old));
  });

  test('o banco de uma versão mais nova para com o aviso', () async {
    final (core, vault) = await withProfile();
    core.failOpen = CoreFailure.newerStore;
    final c = await started(core, vault);
    expect((c.state as StartupProblemState).problem, StartupProblem.newerStore);
  });

  test('sem a biblioteca nativa, para no começo', () async {
    final c = await started(FakeCore(info: null), FakeVault());
    expect(
      (c.state as StartupProblemState).problem,
      StartupProblem.coreMissing,
    );
  });

  test('trocar o nome devolve o erro sem sair do perfil', () async {
    final (core, vault) = await withProfile();
    final c = await started(core, vault);
    expect(await c.rename(''), CoreFailure.invalidName);
    expect(c.state, isA<StartupReady>());
    expect(await c.rename('Arlequim'), isNull);
    expect((c.state as StartupReady).profile.displayName, 'Arlequim');
  });
}
