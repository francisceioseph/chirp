// lib/src/ui/pages/search_page.dart
//
// A busca no histórico de todas as conversas (o FTS5 do banco cifrado). Tocar num
// resultado abre a conversa.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../application/contacts_controller.dart';
import '../../core/chirp_core.dart';
import '../atoms/identity_avatar.dart';
import '../atoms/panel_text.dart';
import '../molecules/conversation_tile.dart';
import '../time_format.dart';
import 'conversation_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.contacts, this.onOpen});

  final ContactsController contacts;

  /// Abre a conversa de um resultado ao lado da lista (com duas colunas); sem isso,
  /// ela abre por cima da busca.
  final ValueChanged<int>? onOpen;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<ChatMessage>? _results;

  void _open(BuildContext context, int contactId) {
    if (widget.onOpen case final open?) {
      Navigator.of(context).pop();
      return open(contactId);
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ConversationPage(contacts: widget.contacts, contactId: contactId),
      ),
    );
  }

  int _asked = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _changed(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _search(text));
  }

  Future<void> _search(String text) async {
    final ask = ++_asked;
    if (text.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    try {
      final found = await widget.contacts.store.search(text);
      if (mounted && ask == _asked) setState(() => _results = found);
    } on CoreException {
      if (mounted && ask == _asked) setState(() => _results = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final results = _results;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: true,
          onChanged: _changed,
          onSubmitted: _search,
          textInputAction: TextInputAction.search,
          enableIMEPersonalizedLearning: false,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: l10n.searchMessages,
            border: InputBorder.none,
          ),
        ),
      ),
      body: results == null
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: PanelBody(l10n.searchHelp),
              ),
            )
          : results.isEmpty
          ? Center(child: PanelBody(l10n.searchNothing))
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, i) {
                final message = results[i];
                final contact = widget.contacts.byId(message.contactId);
                final name = contact == null
                    ? l10n.contactUnnamed
                    : contactName(l10n, contact);
                return ListTile(
                  leading: contact == null
                      ? null
                      : IdentityAvatar(
                          seed: contact.avatarSeed,
                          size: 40,
                          photo: contact.photo,
                        ),
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    message.outgoing
                        ? '${l10n.you}: ${message.text}'
                        : message.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    messageTime(context, message.sentAt),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  onTap: () => _open(context, message.contactId),
                );
              },
            ),
    );
  }
}
