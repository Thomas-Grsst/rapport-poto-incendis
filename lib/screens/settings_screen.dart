import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/enums.dart';
import '../state/settings_provider.dart';
import '../theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/preset_chips.dart';
import '../widgets/section_card.dart';
import 'company_editor_screen.dart';
import 'directory_screen.dart';

/// Réglages : les sociétés, les répertoires de coordonnées et les listes de
/// choix rapides.
///
/// Tout ce qui est saisi ici est repris automatiquement sur chaque fiche.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _companiesCard(context, settings),
          const SizedBox(height: 12),
          _directoriesCard(context, settings),
          const SizedBox(height: 12),
          const _OrderPrefixCard(),
          const SizedBox(height: 12),
          _presetsCard(context, settings),
        ],
      ),
    );
  }

  Widget _companiesCard(BuildContext context, SettingsProvider settings) {
    return SectionCard(
      title: 'Sociétés',
      icon: Icons.business_outlined,
      children: [
        const Text(
          "Celle qu'on choisit à la création d'une fiche. L'étoile marque "
          'celle proposée en premier.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7785)),
        ),
        const SizedBox(height: 6),
        for (final company in settings.companies)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(company.name.isEmpty ? company.id : company.name),
            subtitle: Text(
              company.needsSetup
                  ? 'Adresse et mentions légales à compléter'
                  : company.addressOneLine,
              style: TextStyle(
                color: company.needsSetup ? AppColors.warning : null,
              ),
            ),
            leading: IconButton(
              tooltip: 'Proposer en premier',
              onPressed: () =>
                  settings.setDefaultCompany(company.id),
              icon: Icon(
                company.id == settings.settings.defaultCompanyId
                    ? Icons.star
                    : Icons.star_border,
                color: company.id == settings.settings.defaultCompanyId
                    ? AppColors.brandDark
                    : const Color(0xFF8A97A3),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CompanyEditorScreen(companyId: company.id),
              ),
            ),
          ),
      ],
    );
  }

  Widget _directoriesCard(BuildContext context, SettingsProvider settings) {
    return SectionCard(
      title: 'Répertoires',
      icon: Icons.contacts_outlined,
      children: [
        const Text(
          'Saisis une fois, proposés ensuite sur chaque fiche : vous ne '
          'retapez plus une adresse de mairie.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7785)),
        ),
        const SizedBox(height: 6),
        for (final kind in DirectoryKind.values)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              kind == DirectoryKind.sdis
                  ? Icons.local_fire_department_outlined
                  : Icons.account_balance_outlined,
              color: AppColors.brandLight,
            ),
            title: Text(kind.plural),
            subtitle: Text('${settings.directory(kind).length} enregistrés'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DirectoryScreen(kind: kind)),
            ),
          ),
      ],
    );
  }

  Widget _presetsCard(BuildContext context, SettingsProvider settings) {
    return SectionCard(
      title: 'Listes de choix rapides',
      icon: Icons.checklist_outlined,
      children: [
        const Text(
          "Ce qu'on touche du doigt au lieu de le taper, au pied du poteau.",
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7785)),
        ),
        const SizedBox(height: 6),
        for (final list in PresetList.values)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(list.label),
            subtitle: Text('${settings.presetsOf(list).length} éléments'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _PresetEditorScreen(list: list)),
            ),
          ),
      ],
    );
  }
}

/// Le début du numéro d'ordre, commun à toute une tournée.
class _OrderPrefixCard extends StatefulWidget {
  const _OrderPrefixCard();

  @override
  State<_OrderPrefixCard> createState() => _OrderPrefixCardState();
}

class _OrderPrefixCardState extends State<_OrderPrefixCard> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final prefix = settings.settings.orderNumberPrefix;

    return SectionCard(
      title: "Numéro d'ordre",
      icon: Icons.tag,
      children: [
        AppTextField(
          initialValue: prefix,
          label: 'Début du numéro',
          hint: 'Ex. : 45',
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) => settings.update(
            settings.settings.copyWith(orderNumberPrefix: value),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          prefix.trim().isEmpty
              ? "Sans début de numéro, le n° d'ordre proposé sera simplement "
                  'celui du poteau.'
              : 'Le poteau 013 se verra proposer « ${prefix.trim()} 013 ». '
                  'Le champ reste modifiable sur chaque fiche.',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A97A3)),
        ),
      ],
    );
  }
}

/// Édition d'une liste de choix rapides.
class _PresetEditorScreen extends StatefulWidget {
  const _PresetEditorScreen({required this.list});

  final PresetList list;

  @override
  State<_PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends State<_PresetEditorScreen> {
  late List<String> _values = [
    ...context.read<SettingsProvider>().presetsOf(widget.list),
  ];

  Future<void> _persist() =>
      context.read<SettingsProvider>().replacePresets(widget.list, _values);

  Future<void> _add() async {
    final value = await showTextInputDialog(
      context,
      title: 'Ajouter à « ${widget.list.label} »',
    );
    if (value == null || value.isEmpty) return;
    setState(() => _values = [..._values, value]);
    await _persist();
  }

  Future<void> _edit(int index) async {
    final value = await showTextInputDialog(
      context,
      title: 'Modifier',
      initialValue: _values[index],
    );
    if (value == null || value.isEmpty) return;
    setState(() => _values[index] = value);
    await _persist();
  }

  Future<void> _remove(int index) async {
    setState(() => _values.removeAt(index));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.list.label)),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: AppColors.brandDark,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _values.isEmpty
          ? const Center(
              child: Text(
                'Aucun élément. Appuyez sur + pour en ajouter.',
                style: TextStyle(color: Color(0xFF8A97A3)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _values.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => ListTile(
                title: Text(_values[index]),
                onTap: () => _edit(index),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _remove(index),
                ),
              ),
            ),
    );
  }
}
