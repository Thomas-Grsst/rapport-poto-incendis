import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contact_entry.dart';
import '../models/enums.dart';
import '../state/settings_provider.dart';
import '../theme.dart';
import 'contact_editor_screen.dart';

/// Le répertoire d'un type de coordonnées : les centres du SDISS ou les
/// collectivités.
///
/// C'est l'endroit où l'on corrige un numéro de téléphone ou où l'on prépare
/// une tournée la veille, au calme, plutôt qu'au pied d'un poteau.
class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key, required this.kind});

  final DirectoryKind kind;

  Future<void> _add(BuildContext context) async {
    await Navigator.of(context).push<ContactEntry>(
      MaterialPageRoute(builder: (_) => ContactEditorScreen(kind: kind)),
    );
  }

  Future<void> _edit(BuildContext context, ContactEntry entry) async {
    await Navigator.of(context).push<ContactEntry>(
      MaterialPageRoute(
        builder: (_) => ContactEditorScreen(kind: kind, entry: entry),
      ),
    );
  }

  /// Retirer une entrée ne touche pas aux fiches déjà émises : elles en
  /// gardent une copie, et continuent de s'imprimer telles qu'elles ont été
  /// établies.
  Future<void> _remove(BuildContext context, ContactEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Retirer ${entry.displayLine} ?'),
        content: const Text(
          'Ces coordonnées ne seront plus proposées. Les fiches déjà établies '
          'ne changent pas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<SettingsProvider>().removeContact(kind, entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<SettingsProvider>().directory(kind);

    return Scaffold(
      appBar: AppBar(title: Text(kind.plural)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context),
        backgroundColor: AppColors.brandDark,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      kind == DirectoryKind.sdis
                          ? Icons.local_fire_department_outlined
                          : Icons.account_balance_outlined,
                      size: 52,
                      color: AppColors.brandLight,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucune entrée',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vous pouvez aussi les saisir au fil des fiches : elles '
                      'viennent se ranger ici toutes seules.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 14, color: Color(0xFF6B7785)),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.displayLine),
                  subtitle: Text(
                    [entry.addressLine, entry.phone]
                        .where((line) => line.trim().isNotEmpty)
                        .join('  •  '),
                  ),
                  onTap: () => _edit(context, entry),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _remove(context, entry),
                  ),
                );
              },
            ),
    );
  }
}
