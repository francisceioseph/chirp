// lib/src/ui/organisms/profile_photo_card.dart
//
// A foto do perfil: escolher, tirar e quem vê (ninguém, todos os contatos ou só os
// marcados, um a um na página de cada contato). A foto é feita quadrada e sai sem a
// localização nem outros dados, e o cartão diz, sem enfeite, que tirar alguém apaga a
// foto do app dele, mas não uma cópia que ele já tenha guardado.
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../../platform/file_picker.dart';
import '../atoms/identity_avatar.dart';
import '../failure_text.dart';

class ProfilePhotoCard extends StatefulWidget {
  const ProfilePhotoCard({
    super.key,
    required this.profile,
    required this.change,
  });

  final Profile profile;

  /// Muda o perfil pelo núcleo; devolve a falha, ou nulo.
  final Future<CoreFailure?> Function(
    Future<Profile> Function(ProfileStore store) change,
  )
  change;

  @override
  State<ProfilePhotoCard> createState() => _ProfilePhotoCardState();
}

class _ProfilePhotoCardState extends State<ProfilePhotoCard> {
  bool _busy = false;

  Future<void> _run(Future<Profile> Function(ProfileStore store) change) async {
    setState(() => _busy = true);
    final failure = await widget.change(change);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(failureText(context.l10n, failure))),
        );
    }
  }

  Future<void> _pick() async {
    final path = await FilePickerScope.of(context).pickFile();
    if (path == null || !mounted) return;
    await _run((store) => store.setProfilePhoto(path));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final profile = widget.profile;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final hasPhoto = profile.photo != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.photoTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(l10n.photoHelp, style: muted),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IdentityAvatar(
                        seed: profile.avatarSeed,
                        size: 56,
                        photo: profile.photo,
                      ),
                      FilledButton.tonal(
                        onPressed: _busy ? null : _pick,
                        child: Text(
                          hasPhoto ? l10n.photoChange : l10n.photoChoose,
                        ),
                      ),
                      if (hasPhoto)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _run((s) => s.removeProfilePhoto()),
                          child: Text(l10n.photoRemove),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.photoWhoSees, style: theme.textTheme.labelLarge),
                ],
              ),
            ),
            RadioGroup<PhotoVisibility>(
              groupValue: profile.photoVisibility,
              onChanged: (value) {
                if (_busy || value == null) return;
                _run((s) => s.setPhotoVisibility(value));
              },
              child: Column(
                children: [
                  for (final (value, label) in [
                    (PhotoVisibility.everyone, l10n.photoEveryone),
                    (PhotoVisibility.chosen, l10n.photoChosen),
                    (PhotoVisibility.nobody, l10n.photoNobody),
                  ])
                    RadioListTile<PhotoVisibility>(
                      value: value,
                      title: Text(label),
                      subtitle: value == PhotoVisibility.chosen
                          ? Text(l10n.photoChosenHelp)
                          : null,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.photoRevokeNote, style: muted),
            ),
          ],
        ),
      ),
    );
  }
}
