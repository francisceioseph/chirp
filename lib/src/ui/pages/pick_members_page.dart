// lib/src/ui/pages/pick_members_page.dart
//
// Escolher contatos para um grupo (fase 9): para criar (com o nome do grupo) ou para
// adicionar a um que já existe. Só entram contatos com o aperto de mão feito, e o
// botão só acende com alguém marcado (e o nome, ao criar).
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../atoms/identity_avatar.dart';
import '../failure_text.dart';
import '../molecules/conversation_tile.dart';
import '../molecules/name_field.dart';

class PickMembersPage extends StatefulWidget {
  const PickMembersPage({
    super.key,
    required this.people,
    required this.onDone,
    this.creating = true,
  });

  /// Quem dá para escolher.
  final List<Contact> people;

  /// Cria (com o nome) ou adiciona. Devolve a falha, ou nulo se deu certo.
  final Future<CoreFailure?> Function(String name, List<int> ids) onDone;

  /// Criar um grupo novo (pede o nome) ou adicionar a um.
  final bool creating;

  @override
  State<PickMembersPage> createState() => _PickMembersPageState();
}

class _PickMembersPageState extends State<PickMembersPage> {
  final _name = TextEditingController();
  final Set<int> _chosen = {};
  bool _busy = false;
  CoreFailure? _failure;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _ready =>
      !_busy &&
      _chosen.isNotEmpty &&
      (!widget.creating || _name.text.trim().isNotEmpty);

  Future<void> _done() async {
    if (!_ready) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final ids = [
      for (final c in widget.people)
        if (_chosen.contains(c.id)) c.id,
    ];
    final failure = await widget.onDone(_name.text, ids);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final failure = _failure;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.creating ? l10n.groupNew : l10n.groupAddMembers),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilledButton(
              onPressed: _ready ? _done : null,
              child: Text(widget.creating ? l10n.groupCreate : l10n.groupAdd),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (widget.creating)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: NameField(
                    controller: _name,
                    autofocus: true,
                    label: l10n.groupName,
                    onSubmitted: (_) => _done(),
                  ),
                ),
              if (failure != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    failureText(l10n, failure),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  l10n.groupPickMembers,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (widget.people.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.groupNoOneToAdd),
                ),
              for (final contact in widget.people)
                CheckboxListTile(
                  value: _chosen.contains(contact.id),
                  onChanged: _busy
                      ? null
                      : (on) => setState(
                          () => on == true
                              ? _chosen.add(contact.id)
                              : _chosen.remove(contact.id),
                        ),
                  secondary: IdentityAvatar(
                    seed: contact.avatarSeed,
                    size: 36,
                    photo: contact.photo,
                  ),
                  title: Text(
                    contactName(l10n, contact),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.groupHelp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
