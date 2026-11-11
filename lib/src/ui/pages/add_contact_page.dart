// lib/src/ui/pages/add_contact_page.dart
//
// Adicionar um contato: mostrar o meu convite (QR ou link) ou colar o de outra pessoa.
// Quando alguém lê o meu QR, a tela fecha sozinha e avisa.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../application/contacts_controller.dart';
import '../../core/chirp_core.dart';
import '../failure_text.dart';
import '../organisms/invite_qr_card.dart';
import '../organisms/paste_invite_form.dart';

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key, required this.controller});

  final ContactsController controller;

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
    final text = context.l10n.contactAdded(contact.displayName);
    Navigator.of(context).maybePop();
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<Contact> _add(String link) async {
    final contact = await widget.controller.add(link, scanned: false);
    _known.add(contact.id);
    _done(contact);
    return contact;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = _inviteFailure;
    return DefaultTabController(
      length: 2,
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
            _Pane(
              child: failure != null
                  ? Text(
                      failureText(l10n, failure),
                      textAlign: TextAlign.center,
                    )
                  : InviteQrCard(
                      link: _link,
                      onNewCode: _newCode,
                      createLink: () =>
                          widget.controller.createInvite(qr: false),
                    ),
            ),
            _Pane(child: PasteInviteForm(onAdd: _add)),
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
