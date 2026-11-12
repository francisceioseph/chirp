// lib/src/ui/pages/group_page.dart
//
// Os detalhes de um grupo (fase 9): o nome, os membros (o admin marcado, e quem não é
// contato avisado: as minhas mensagens não chegam a ele), e o que dá para fazer. Só o
// admin renomeia, adiciona e tira; qualquer um sai, perguntando antes.
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../application/contacts_controller.dart';
import '../../core/chirp_core.dart';
import '../atoms/identity_avatar.dart';
import '../atoms/panel_text.dart';
import '../failure_text.dart';
import '../organisms/rename_dialog.dart';
import '../templates/centered_panel.dart';
import 'pick_members_page.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({
    super.key,
    required this.controller,
    required this.groupId,
    this.onClose,
  });

  final ContactsController controller;
  final int groupId;

  /// Fecha o painel ao lado (em três colunas); sem ele, a seta de voltar.
  final VoidCallback? onClose;

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  GroupInfo? _group;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final group = await widget.controller.store.group(widget.groupId);
      if (mounted) setState(() => _group = group);
    } on CoreException {
      // Fica o de antes.
    }
  }

  void _tell(CoreFailure failure) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(failureText(context.l10n, failure))),
      );
  }

  Future<CoreFailure?> _change(
    Future<void> Function(ProfileStore store) change,
  ) async {
    try {
      await widget.controller.changeGroup(change);
      await _load();
      return null;
    } on CoreException catch (error) {
      return error.failure;
    }
  }

  Future<void> _rename(GroupInfo group) => showRenameDialog(
    context,
    current: group.name,
    title: context.l10n.groupRename,
    label: context.l10n.groupName,
    rename: (name) => _change((s) => s.renameGroup(group.id, name)),
  );

  Future<void> _add(GroupInfo group) {
    final inIt = {for (final m in group.members) m.contactId};
    final people = [
      for (final c in widget.controller.people)
        if (!inIt.contains(c.id)) c,
    ];
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PickMembersPage(
          people: people,
          creating: false,
          onDone: (_, ids) => _change((s) => s.addGroupMembers(group.id, ids)),
        ),
      ),
    );
  }

  Future<void> _remove(GroupInfo group, GroupMember member) async {
    final failure = await _change((s) => s.removeGroupMember(group.id, member));
    if (failure != null && mounted) _tell(failure);
  }

  Future<void> _leave(GroupInfo group) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout),
        title: Text(l10n.groupLeaveTitle(group.name)),
        content: Text(l10n.groupLeaveBody),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.groupLeave),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final failure = await _change((s) => s.leaveGroup(group.id));
    if (failure != null && mounted) _tell(failure);
  }

  Widget? _close(BuildContext context) => switch (widget.onClose) {
    final close? => IconButton(
      tooltip: context.l10n.close,
      onPressed: close,
      icon: const Icon(Icons.close),
    ),
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final group = _group;
    final contact = widget.controller.byId(widget.groupId);
    if (group == null || contact == null) {
      return Scaffold(appBar: AppBar(leading: _close(context)));
    }
    final admin = group.iAmAdmin && group.active;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return CenteredPanel(
      appBar: AppBar(leading: _close(context), title: Text(group.name)),
      children: [
        Center(child: IdentityAvatar(seed: contact.avatarSeed, size: 88)),
        const SizedBox(height: 12),
        PanelTitle(group.name),
        const SizedBox(height: 4),
        PanelBody(
          group.active
              ? l10n.groupMemberCount(group.members.length)
              : l10n.groupClosed,
        ),
        if (admin) ...[
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _add(group),
                icon: const Icon(Icons.group_add_outlined),
                label: Text(l10n.groupAddMembers),
              ),
              TextButton.icon(
                onPressed: () => _rename(group),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.groupRename),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        if (group.active)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.you),
            subtitle: group.iAmAdmin ? Text(l10n.groupAdmin) : null,
          ),
        for (final member in group.members)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: IdentityAvatar(seed: member.avatarSeed, size: 40),
            title: Text(
              member.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: switch ([
              if (member.isAdmin) l10n.groupAdmin,
              if (member.contactId == null) l10n.groupNotConnected,
            ]) {
              [] => null,
              final parts => Text(
                parts.join(' · '),
                style: member.contactId == null ? muted : null,
              ),
            },
            trailing: admin
                ? IconButton(
                    tooltip: '${l10n.groupRemove}: ${member.name}',
                    onPressed: () => _remove(group, member),
                    icon: const Icon(Icons.person_remove_outlined),
                  )
                : null,
          ),
        const SizedBox(height: 8),
        Text(l10n.groupHelp, style: muted),
        if (group.active) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: () => _leave(group),
              icon: const Icon(Icons.logout),
              label: Text(l10n.groupLeave),
            ),
          ),
        ],
      ],
    );
  }
}
