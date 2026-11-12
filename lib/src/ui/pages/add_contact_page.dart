// lib/src/ui/pages/add_contact_page.dart
//
// Adicionar um contato: mostrar o meu convite (QR ou link) ou colar o de outra pessoa.
// Quando alguém lê o meu QR, a tela fecha sozinha e avisa. Numa janela estreita, uma
// aba para cada; a partir de 840 px, os dois lado a lado.
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../application/contacts_controller.dart';
import '../../core/chirp_core.dart';
import '../failure_text.dart';
import '../organisms/invite_qr_card.dart';
import '../organisms/paste_invite_form.dart';
import '../templates/shell_template.dart';

class AddContactPage extends StatefulWidget {
  const AddContactPage({
    super.key,
    required this.controller,
    this.startOnPaste = false,
  });

  final ContactsController controller;

  /// Abre no colar (o "Usar um link" do início vazio).
  final bool startOnPaste;

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  String? _link;
  CoreFailure? _inviteFailure;

  /// Os contatos de quando a tela abriu: um que apareça depois é quem leu o código.
  final Set<int> _known = {};

  @override
  void initState() {
    super.initState();
    _known.addAll([
      for (final c in widget.controller.contacts)
        if (c.established) c.id,
    ]);
    widget.controller.addListener(_onContacts);
    _newCode();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onContacts);
    super.dispose();
  }

  Future<void> _newCode() async {
    setState(() {
      _link = null;
      _inviteFailure = null;
    });
    try {
      final link = await widget.controller.createInvite(qr: true);
      if (mounted) setState(() => _link = link);
    } on CoreException catch (error) {
      if (mounted) setState(() => _inviteFailure = error.failure);
    }
  }

  /// Alguém leu um convite nosso: fecha e avisa.
  void _onContacts() {
    for (final contact in widget.controller.contacts) {
      if (contact.established && !_known.contains(contact.id)) {
        _known.add(contact.id);
        _done(contact);
        return;
      }
    }
  }

  void _done(Contact contact) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    // Quem convidou estava desligado: o pedido ficou na caixa postal dele.
    final text = contact.established
        ? context.l10n.contactAdded(contact.displayName)
        : context.l10n.contactRequestLeft;
    Navigator.of(context).maybePop();
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<Contact> _add(String link) async {
    final contact = await widget.controller.add(link, scanned: false);
    _known.add(contact.id);
    _done(contact);
    return contact;
  }

  Widget _show(BuildContext context) {
    final failure = _inviteFailure;
    return failure != null
        ? Text(failureText(context.l10n, failure), textAlign: TextAlign.center)
        : InviteQrCard(
            link: _link,
            onNewCode: _newCode,
            createLink: () => widget.controller.createInvite(qr: false),
          );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ShellTemplate.twoColumns) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.addContact)),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _Side(
                              icon: Icons.qr_code_2,
                              title: l10n.inviteTabShow,
                              child: _show(context),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _Side(
                              icon: Icons.link,
                              tonal: true,
                              title: l10n.inviteTabPaste,
                              child: PasteInviteForm(onAdd: _add),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return DefaultTabController(
          length: 2,
          initialIndex: widget.startOnPaste ? 1 : 0,
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.addContact),
              bottom: TabBar(
                tabs: [
                  Tab(text: l10n.inviteTabShow),
                  Tab(text: l10n.inviteTabPaste),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _Pane(child: _show(context)),
                _Pane(child: PasteInviteForm(onAdd: _add)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Um dos dois lados, na janela larga: o título e o conteúdo, num cartão.
class _Side extends StatelessWidget {
  const _Side({
    required this.icon,
    required this.title,
    required this.child,
    this.tonal = false,
  });

  final IconData icon;
  final String title;
  final Widget child;

  /// O ícone no tom secundário (o colar), e não no primário (o meu código).
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tonal
                          ? scheme.secondaryContainer
                          : scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: tonal
                          ? scheme.onSecondaryContainer
                          : scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: child,
        ),
      ),
    ),
  );
}
