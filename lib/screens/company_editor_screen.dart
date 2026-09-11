import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/company.dart';
import '../state/settings_provider.dart';
import '../theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/media_image.dart';
import '../widgets/section_card.dart';

/// Fiche d'une société : ses coordonnées, ses mentions légales et son logo.
///
/// Ce qui est saisi ici habille toutes les fiches créées pour cette
/// société-là — l'en-tête, et les mentions en pied de page.
class CompanyEditorScreen extends StatefulWidget {
  const CompanyEditorScreen({super.key, required this.companyId});

  final String companyId;

  @override
  State<CompanyEditorScreen> createState() => _CompanyEditorScreenState();
}

class _CompanyEditorScreenState extends State<CompanyEditorScreen> {
  late Company _draft =
      context.read<SettingsProvider>().settings.companyFor(widget.companyId);
  bool _dirty = false;

  void _update(Company Function(Company) change) {
    setState(() {
      _draft = change(_draft);
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (!_dirty) return;
    await context.read<SettingsProvider>().updateCompany(_draft);
    _dirty = false;
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
    );
    if (picked == null || !mounted) return;

    // Le logo est enregistré tout de suite : c'est un fichier, pas un champ
    // texte, il n'a pas à attendre l'enregistrement du reste du formulaire.
    await _save();
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    await settings.setLogo(_draft.id, picked.path);
    if (!mounted) return;
    setState(() => _draft = settings.settings.companyFor(_draft.id));
  }

  Future<void> _removeLogo() async {
    final settings = context.read<SettingsProvider>();
    await _save();
    await settings.removeLogo(_draft.id);
    if (!mounted) return;
    setState(() => _draft = settings.settings.companyFor(_draft.id));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _save();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_draft.name.isEmpty ? 'Société' : _draft.name),
          actions: [
            TextButton(
              onPressed: () async {
                await _save();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Société enregistrée')),
                );
              },
              child: const Text(
                'Enregistrer',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _identityCard(),
            const SizedBox(height: 12),
            _legalCard(),
            const SizedBox(height: 12),
            _logoCard(),
          ],
        ),
      ),
    );
  }

  Widget _identityCard() {
    return SectionCard(
      title: 'Identité',
      icon: Icons.business_outlined,
      children: [
        Row(
          children: [
            SizedBox(
              width: 96,
              child: AppTextField(
                initialValue: _draft.legalForm,
                label: 'Forme',
                hint: 'SASU',
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) =>
                    _update((company) => company.copyWith(legalForm: value)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextField(
                initialValue: _draft.name,
                label: 'Nom',
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) =>
                    _update((company) => company.copyWith(name: value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _draft.addressLine,
          label: 'Adresse du siège',
          prefixIcon: Icons.home_outlined,
          onChanged: (value) =>
              _update((company) => company.copyWith(addressLine: value)),
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
                onChanged: (value) =>
                    _update((company) => company.copyWith(postalCode: value)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextField(
                initialValue: _draft.city,
                label: 'Ville',
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) =>
                    _update((company) => company.copyWith(city: value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _draft.phone,
          label: 'Téléphone',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
          onChanged: (value) =>
              _update((company) => company.copyWith(phone: value)),
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _draft.email,
          label: 'E-mail',
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
          prefixIcon: Icons.mail_outline,
          onChanged: (value) =>
              _update((company) => company.copyWith(email: value)),
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _draft.website,
          label: 'Site internet',
          textCapitalization: TextCapitalization.none,
          prefixIcon: Icons.language_outlined,
          onChanged: (value) =>
              _update((company) => company.copyWith(website: value)),
        ),
      ],
    );
  }

  Widget _legalCard() {
    return SectionCard(
      title: 'Mentions légales',
      icon: Icons.gavel_outlined,
      children: [
        const Text(
          'Elles apparaissent en pied de chaque fiche.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7785)),
        ),
        const SizedBox(height: 12),
        AppTextField(
          initialValue: _draft.siret,
          label: 'SIRET',
          hint: '14 chiffres',
          keyboardType: TextInputType.number,
          onChanged: (value) =>
              _update((company) => company.copyWith(siret: value)),
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _draft.ape,
          label: 'Code APE',
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) =>
              _update((company) => company.copyWith(ape: value)),
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _draft.rcs,
          label: 'RCS',
          hint: "Ville et numéro d'immatriculation",
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) =>
              _update((company) => company.copyWith(rcs: value)),
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _draft.vatNumber,
          label: 'N° TVA intracommunautaire',
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) =>
              _update((company) => company.copyWith(vatNumber: value)),
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _draft.capital,
          label: 'Capital social',
          hint: 'Ex. : 2 000,00 €',
          onChanged: (value) =>
              _update((company) => company.copyWith(capital: value)),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.paleBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'En pied de page',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _draft.legalLine,
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logoCard() {
    final path = _draft.logoPath;
    final hasCustomLogo = path != null && path.isNotEmpty;

    return SectionCard(
      title: 'Logo',
      icon: Icons.image_outlined,
      children: [
        Row(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD5DEE8)),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(6),
              child: MediaImage(
                path: path,
                fit: BoxFit.contain,
                fallbackAsset: _draft.logoAsset,
                placeholder: const Center(
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.brandLight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Le logo s'imprime en tête de chaque fiche de cette "
                    'société.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7785)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _pickLogo,
                        child: Text(hasCustomLogo ? 'Changer' : 'Remplacer'),
                      ),
                      if (hasCustomLogo)
                        TextButton(
                          onPressed: _removeLogo,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger,
                          ),
                          child: const Text('Par défaut'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
