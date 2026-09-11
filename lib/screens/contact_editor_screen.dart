import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contact_entry.dart';
import '../models/enums.dart';
import '../state/settings_provider.dart';
import '../theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/section_card.dart';

/// Saisie d'une entrée du répertoire — un centre du SDISS ou une collectivité.
///
/// Le même écran sert depuis les réglages et depuis l'assistant : une mairie
/// découverte au milieu d'une tournée s'enregistre sur-le-champ, et se
/// retrouve dans la liste pour tous les poteaux suivants de la commune. C'est
/// tout l'intérêt du répertoire : ces coordonnées ne se tapent qu'une fois.
///
/// L'écran renvoie l'entrée telle qu'elle a été enregistrée, pour que
/// l'appelant puisse la sélectionner dans la foulée.
class ContactEditorScreen extends StatefulWidget {
  const ContactEditorScreen({
    super.key,
    required this.kind,
    this.entry,
  });

  final DirectoryKind kind;

  /// L'entrée à modifier, ou null pour en créer une.
  final ContactEntry? entry;

  @override
  State<ContactEditorScreen> createState() => _ContactEditorScreenState();
}

class _ContactEditorScreenState extends State<ContactEditorScreen> {
  late ContactEntry _draft = widget.entry ??
      ContactEntry(id: context.read<SettingsProvider>().newContactId());

  bool _saving = false;

  bool get _isNew => widget.entry == null;

  /// Une entrée sans nom ni adresse ne se retrouverait pas dans la liste :
  /// on demande au moins de quoi la reconnaître.
  bool get _canSave =>
      _draft.name.trim().isNotEmpty || _draft.addressLine.trim().isNotEmpty;

  void _update(ContactEntry Function(ContactEntry) change) {
    setState(() => _draft = change(_draft));
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    final settings = context.read<SettingsProvider>();
    final stored = await settings.saveContact(widget.kind, _draft);
    if (!mounted) return;
    Navigator.of(context).pop(stored);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isNew
              ? 'Nouveau — ${widget.kind.singular}'
              : widget.kind.singular,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          SectionCard(
            title: 'Adresse principale',
            icon: Icons.place_outlined,
            children: [
              AppTextField(
                initialValue: _draft.name,
                label: 'Nom',
                hint: widget.kind.hint,
                autofocus: _isNew,
                onChanged: (value) =>
                    _update((entry) => entry.copyWith(name: value)),
              ),
              const SizedBox(height: 10),
              AppTextField(
                initialValue: _draft.addressLine,
                label: 'Adresse',
                hint: 'Ex. : 999, route de St Rémy',
                prefixIcon: Icons.home_outlined,
                onChanged: (value) =>
                    _update((entry) => entry.copyWith(addressLine: value)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 138,
                    child: AppTextField(
                      initialValue: _draft.postalCode,
                      label: 'Code postal',
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _update(
                        (entry) => entry.copyWith(postalCode: value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      initialValue: _draft.city,
                      label: 'Ville',
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) =>
                          _update((entry) => entry.copyWith(city: value)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Contact',
            icon: Icons.phone_outlined,
            children: [
              AppTextField(
                initialValue: _draft.phone,
                label: 'Téléphone',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                onChanged: (value) =>
                    _update((entry) => entry.copyWith(phone: value)),
              ),
              const SizedBox(height: 10),
              AppTextField(
                initialValue: _draft.fax,
                label: 'Fax',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.print_outlined,
                onChanged: (value) =>
                    _update((entry) => entry.copyWith(fax: value)),
              ),
              const SizedBox(height: 10),
              AppTextField(
                initialValue: _draft.mobile,
                label: 'Portable',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.smartphone_outlined,
                onChanged: (value) =>
                    _update((entry) => entry.copyWith(mobile: value)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Ces coordonnées seront proposées sur toutes vos prochaines '
            'fiches : vous n’aurez plus qu’à les choisir dans la liste.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7785)),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: _canSave && !_saving ? _save : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandDark,
            disabledBackgroundColor: const Color(0xFFC8D3DF),
          ),
          child: Text(_isNew ? 'Enregistrer et choisir' : 'Enregistrer'),
        ),
      ),
    );
  }
}
