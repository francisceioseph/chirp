// lib/src/ui/pages/contacts_page.dart
//
// A tela principal: as conversas (a mais recente primeiro, com as não lidas), a busca,
// o botão de adicionar contato e o perfil no canto. Um contato sem mensagens aparece
// com o estado dele (verificado ou não).
//
// Pela largura (o ShellTemplate): estreita, a conversa abre por cima; larga, ao lado,
// e o contato num terceiro painel. Atalhos: Ctrl+N adicionar, Ctrl+K buscar,
// Alt+setas trocar de conversa e Esc fechar o painel.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../application/contacts_controller.dart';
import '../../core/chirp_core.dart';
import '../atoms/identity_avatar.dart';
import '../atoms/panel_text.dart';
import '../failure_text.dart';
import '../molecules/conversation_tile.dart';
import '../templates/centered_panel.dart';
import '../templates/shell_template.dart';
import 'add_contact_page.dart';
import 'contact_page.dart';
import 'conversation_page.dart';
import 'search_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({
    super.key,
    required this.controller,
    required this.profile,
    required this.onOpenProfile,
  });

  final ContactsController controller;
  final Profile profile;
  final VoidCallback onOpenProfile;

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  /// A conversa aberta ao lado (com duas colunas ou mais).
  int? _selected;

  /// O painel do contato aberto (com três colunas).
  bool _details = false;

  ContactsController get _controller => widget.controller;

  int _columns(BuildContext context) =>
      ShellTemplate.columnsFor(MediaQuery.sizeOf(context).width);

  void _openAdd() {
    if (_controller.networkFailure != null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddContactPage(controller: _controller),
      ),
    );
  }

  void _openConversation(int contactId) {
    if (_columns(context) > 1) {
      setState(() {
        if (_selected != contactId) _details = false;
        _selected = contactId;
      });
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ConversationPage(contacts: _controller, contactId: contactId),
      ),
    );
  }

  void _openSearch() {
    if (_controller.conversations.isEmpty) return;
    final wide = _columns(context) > 1;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchPage(
          contacts: _controller,
          onOpen: wide ? _openConversation : null,
        ),
      ),
    );
  }

  /// Alt+seta: a conversa de cima ou de baixo na lista.
  void _step(int delta) {
    final ids = [for (final c in _controller.conversations) c.contact.id];
    if (ids.isEmpty || _columns(context) == 1) return;
    final at = _selected == null ? -1 : ids.indexOf(_selected!);
    final next = at == -1
        ? (delta > 0 ? 0 : ids.length - 1)
        : (at + delta).clamp(0, ids.length - 1);
    _openConversation(ids[next]);
  }

  void _closeDetails() {
    if (_details) setState(() => _details = false);
  }

  Map<ShortcutActivator, VoidCallback> get _shortcuts => {
    const SingleActivator(LogicalKeyboardKey.keyN, control: true): _openAdd,
    const SingleActivator(LogicalKeyboardKey.keyN, meta: true): _openAdd,
    const SingleActivator(LogicalKeyboardKey.keyK, control: true): _openSearch,
    const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _openSearch,
    const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): () =>
        _step(-1),
    const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): () =>
        _step(1),
    const SingleActivator(LogicalKeyboardKey.escape): _closeDetails,
  };

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: _shortcuts,
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final selected = _selected;
            final threeColumns = _columns(context) == 3;
            return ShellTemplate(
              list: _list(context),
              placeholder: _Placeholder(
                empty: _controller.conversations.isEmpty,
              ),
              conversation: selected == null
                  ? null
                  : ConversationPage(
                      key: ValueKey(selected),
                      contacts: _controller,
                      contactId: selected,
                      onOpenDetails: threeColumns
                          ? () => setState(() => _details = true)
                          : null,
                    ),
              details: selected == null || !_details
                  ? null
                  : ContactPage(
                      key: ValueKey(selected),
                      controller: _controller,
                      contactId: selected,
                      onClose: _closeDetails,
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _list(BuildContext context) {
    final l10n = context.l10n;
    final conversations = _controller.conversations;
    final networkFailure = _controller.networkFailure;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          if (conversations.isNotEmpty)
            IconButton(
              tooltip: l10n.searchMessages,
              onPressed: _openSearch,
              icon: const Icon(Icons.search),
            ),
          IconButton(
            tooltip: l10n.profileTitle,
            onPressed: widget.onOpenProfile,
            icon: IdentityAvatar(seed: widget.profile.avatarSeed, size: 32),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: networkFailure == null
          ? FloatingActionButton.extended(
              onPressed: _openAdd,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l10n.addContact),
            )
          : null,
      body: Column(
        children: [
          if (networkFailure != null)
            MaterialBanner(
              content: Text(
                '${l10n.networkUnavailable} '
                '${failureText(l10n, networkFailure)}',
              ),
              actions: [
                TextButton(
                  onPressed: _controller.start,
                  child: Text(l10n.tryAgain),
                ),
              ],
            ),
          Expanded(
            child: !_controller.loaded
                ? const Center(child: CircularProgressIndicator())
                : conversations.isEmpty
                ? CenteredPanel(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      PanelTitle(l10n.contactsEmptyTitle),
                      const SizedBox(height: 8),
                      PanelBody(l10n.contactsEmptyBody),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: conversations.length,
                    itemBuilder: (context, i) {
                      final contact = conversations[i].contact;
                      return ConversationTile(
                        key: ValueKey(contact.id),
                        conversation: conversations[i],
                        typing: _controller.isTyping(contact.id),
                        selected: contact.id == _selected,
                        onTap: () => _openConversation(contact.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// O lado da conversa antes de escolher uma.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.empty});

  /// Sem conversas, o lado fica só com a marca (o texto de adicionar está na lista).
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined, size: 56, color: scheme.primary),
              if (!empty) ...[
                const SizedBox(height: 12),
                PanelBody(context.l10n.conversationPick),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
