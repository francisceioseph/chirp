// lib/src/ui/pages/contacts_page.dart
//
// A tela principal desta fase: os contatos, o botão de adicionar e o perfil no canto.
// As conversas tomam o lugar da lista na fase 3.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../application/contacts_controller.dart';
import '../../core/chirp_core.dart';
import '../atoms/identity_avatar.dart';
import '../atoms/panel_text.dart';
import '../failure_text.dart';
import '../molecules/contact_tile.dart';
import '../templates/centered_panel.dart';
import 'add_contact_page.dart';
import 'contact_page.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({
    super.key,
    required this.controller,
    required this.profile,
    required this.onOpenProfile,
  });

  final ContactsController controller;
  final Profile profile;
  final VoidCallback onOpenProfile;

  void _openAdd(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AddContactPage(controller: controller),
    ),
  );

  void _openContact(BuildContext context, Contact contact) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ContactPage(controller: controller, contactId: contact.id),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final contacts = controller.contacts;
        final networkFailure = controller.networkFailure;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.appName),
            actions: [
              IconButton(
                tooltip: l10n.profileTitle,
                onPressed: onOpenProfile,
                icon: IdentityAvatar(seed: profile.avatarSeed, size: 32),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: networkFailure == null
              ? FloatingActionButton.extended(
                  onPressed: () => _openAdd(context),
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
                      onPressed: controller.start,
                      child: Text(l10n.tryAgain),
                    ),
                  ],
                ),
              Expanded(
                child: !controller.loaded
                    ? const Center(child: CircularProgressIndicator())
                    : contacts.isEmpty
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
                        itemCount: contacts.length,
                        itemBuilder: (context, i) => ContactTile(
                          contact: contacts[i],
                          onTap: () => _openContact(context, contacts[i]),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
