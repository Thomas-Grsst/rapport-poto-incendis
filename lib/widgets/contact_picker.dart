import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contact_entry.dart';
import '../models/enums.dart';
import '../screens/contact_editor_screen.dart';
import '../state/settings_provider.dart';
import '../theme.dart';

/// Le champ qui choisit un centre du SDISS ou une collectivité dans le
/// répertoire.
///
/// Sur le modèle papier, ces deux cadres sont les plus longs à remplir et les
/// plus répétitifs : les vingt poteaux d'une commune portent la même mairie
/// et le même centre de secours. Ils se saisissent donc une fois puis se
/// choisissent ici d'un geste — et la fiche en garde une copie, pour qu'un
/// changement de numéro l'an prochain ne réécrive pas les fiches déjà émises.
class ContactPicker extends StatelessWidget {
  const ContactPicker({
    super.key,
    required this.kind,
    required this.selected,
    required this.onChanged,
  });

  final DirectoryKind kind;
  final ContactEntry? selected;
  final ValueChanged<ContactEntry?> onChanged;

  @override
  Widget build(BuildContext context) {
    final entry = selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry == null)
          _EmptyCard(kind: kind, onTap: () => _choose(context))
        else
          _SelectedCard(
            entry: entry,
            onChange: () => _choose(context),
            onEdit: () => _edit(context, entry),
          ),
      ],
    );
  }

  /// La liste des entrées enregistrées, plus « Nouvelle… ».
  Future<void> _choose(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final entries = settings.directory(kind);

    final picked = await showModalBottomSheet<_PickResult>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    kind.plural,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandDark,
                    ),
                  ),
                ),
              ),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Votre répertoire est vide. La première saisie sera '
                    'la seule : elle sera ensuite proposée ici.',
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7785)),
                  ),
                ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in entries)
                      ListTile(
                        leading: Icon(
                          kind == DirectoryKind.sdis
                              ? Icons.local_fire_department_outlined
                              : Icons.account_balance_outlined,
                          color: AppColors.brandLight,
                        ),
                        title: Text(item.displayLine),
                        subtitle:
                            item.phone.isEmpty ? null : Text(item.phone),
                        selected: item.id == selected?.id,
                        onTap: () => Navigator.of(sheetContext)
                            .pop(_PickResult.existing(item)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add, color: AppColors.brandDark),
                title: Text('Nouvelle ${kind.singular.toLowerCase()}…'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(const _PickResult.create()),
              ),
              if (selected != null)
                ListTile(
                  leading: const Icon(Icons.close, color: AppColors.danger),
                  title: const Text('Retirer de la fiche'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(const _PickResult.clear()),
                ),
            ],
          ),
        ),
      ),
    );

    if (picked == null || !context.mounted) return;

    switch (picked.action) {
      case _PickAction.existing:
        onChanged(picked.entry);
      case _PickAction.clear:
        onChanged(null);
      case _PickAction.create:
        final created = await Navigator.of(context).push<ContactEntry>(
          MaterialPageRoute(
            builder: (_) => ContactEditorScreen(kind: kind),
          ),
        );
        if (created != null) onChanged(created);
    }
  }

  /// Modifier l'entrée met à jour le répertoire **et** la copie de la fiche :
  /// on corrige un numéro de téléphone là où on s'aperçoit qu'il est faux,
  /// c'est-à-dire sur la fiche qu'on est en train de remplir.
  Future<void> _edit(BuildContext context, ContactEntry entry) async {
    final updated = await Navigator.of(context).push<ContactEntry>(
      MaterialPageRoute(
        builder: (_) => ContactEditorScreen(kind: kind, entry: entry),
      ),
    );
    if (updated != null) onChanged(updated);
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.kind, required this.onTap});

  final DirectoryKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paleBlue,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.playlist_add, color: AppColors.brandDark),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Choisir ${kind == DirectoryKind.sdis ? 'un centre' : 'une collectivité'}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.brandDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedCard extends StatelessWidget {
  const _SelectedCard({
    required this.entry,
    required this.onChange,
    required this.onEdit,
  });

  final ContactEntry entry;
  final VoidCallback onChange;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.brandLight, width: 1.4),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in entry.addressLines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          line,
                          style: const TextStyle(fontSize: 14, height: 1.3),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Modifier',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              if (entry.phone.trim().isNotEmpty)
                _Contact(icon: Icons.phone_outlined, value: entry.phone),
              if (entry.fax.trim().isNotEmpty)
                _Contact(icon: Icons.print_outlined, value: entry.fax),
              if (entry.mobile.trim().isNotEmpty)
                _Contact(icon: Icons.smartphone_outlined, value: entry.mobile),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onChange,
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Changer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8A97A3)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: Color(0xFF35414D)),
        ),
      ],
    );
  }
}

enum _PickAction { existing, create, clear }

/// Ce que la feuille de choix renvoie : une entrée, une demande de création,
/// ou le retrait de celle qui était choisie.
class _PickResult {
  const _PickResult.existing(this.entry) : action = _PickAction.existing;
  const _PickResult.create()
      : action = _PickAction.create,
        entry = null;
  const _PickResult.clear()
      : action = _PickAction.clear,
        entry = null;

  final _PickAction action;
  final ContactEntry? entry;
}
