import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/company.dart';
import '../models/fiche_pi.dart';
import '../state/fiches_provider.dart';
import '../state/settings_provider.dart';
import '../theme.dart';
import '../widgets/fiche_card.dart';
import 'fiche_detail_screen.dart';
import 'fiche_wizard_screen.dart';
import 'settings_screen.dart';

/// Écran d'accueil : recherche, filtres et liste des fiches.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Demande d'abord pour quelle société : c'est elle qui habille la fiche,
  /// et le même intervenant travaille pour les deux.
  Future<void> _createFiche() async {
    final settings = context.read<SettingsProvider>().settings;

    final companyId = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pour quelle société ?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
            ),
            for (final company in settings.companies)
              ListTile(
                leading: const Icon(Icons.business_outlined),
                title: Text(company.name.isEmpty ? company.id : company.name),
                subtitle: company.addressOneLine.isNotEmpty
                    ? Text(company.addressOneLine)
                    : (company.website.isNotEmpty
                        ? Text(company.website)
                        : null),
                trailing: company.id == settings.defaultCompanyId
                    ? const Icon(Icons.star, size: 18, color: AppColors.brandLight)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(company.id),
              ),
          ],
        ),
      ),
    );

    if (companyId == null || !mounted) return;

    final fiches = context.read<FichesProvider>();
    final draft = fiches.createDraft(settings, companyId: companyId);

    final saved = await Navigator.of(context).push<FichePi>(
      MaterialPageRoute(
        builder: (_) => FicheWizardScreen(fiche: draft, isNew: true),
      ),
    );

    if (saved != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FicheDetailScreen(ficheId: saved.id),
        ),
      );
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fiches = context.watch<FichesProvider>();
    final visible = fiches.visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poteaux incendie'),
        actions: [
          IconButton(
            tooltip: 'Réglages',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createFiche,
        backgroundColor: AppColors.brandDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle fiche'),
      ),
      body: Column(
        children: [
          _searchBar(fiches),
          _filterBar(fiches),
          _setupBanner(),
          Expanded(
            child: visible.isEmpty
                ? _emptyState(fiches)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final fiche = visible[index];
                      return FicheCard(
                        fiche: fiche,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                FicheDetailScreen(ficheId: fiche.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Invitation à compléter les sociétés tant qu'elles n'ont pas d'adresse.
  ///
  /// Ter2eaux et Rezeau sont livrées avec leur nom et leur logo, mais sans
  /// adresse ni mentions légales : personne ne les a saisies, et il vaut
  /// mieux le dire ici qu'imprimer trente fiches à en-tête vide.
  Widget _setupBanner() {
    final companies = context.watch<SettingsProvider>().companies;
    final incomplete =
        companies.where((company) => company.needsSetup).toList();
    if (incomplete.isEmpty) return const SizedBox.shrink();

    final names = incomplete
        .map((Company company) => company.name.isEmpty ? company.id : company.name)
        .join(' et ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: const Color(0xFFFDF1DC),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _openSettings,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.business_outlined,
                    color: AppColors.warning, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complétez $names',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Adresse et mentions légales : elles apparaîtront en '
                        'tête et en pied de toutes vos fiches.',
                        style: TextStyle(fontSize: 13, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.warning),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBar(FichesProvider fiches) {
    return Container(
      color: AppColors.brandDark,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: fiches.setQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Commune, rue, n° de poteau…',
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: fiches.query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    fiches.setQuery('');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }

  Widget _filterBar(FichesProvider fiches) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          for (final filter in FicheFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${filter.label} (${fiches.countFor(filter)})'),
                selected: fiches.filter == filter,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: fiches.filter == filter
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: fiches.filter == filter
                      ? AppColors.brandDark
                      : const Color(0xFF5A6773),
                ),
                onSelected: (_) => fiches.setFilter(filter),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(FichesProvider fiches) {
    final isFiltered =
        fiches.query.isNotEmpty || fiches.filter != FicheFilter.toutes;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered
                  ? Icons.search_off
                  : Icons.local_fire_department_outlined,
              size: 56,
              color: AppColors.brandLight,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'Aucune fiche ne correspond'
                  : 'Aucune fiche pour le moment',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Essayez une autre commune ou changez de filtre.'
                  : 'Appuyez sur « Nouvelle fiche » pour contrôler votre '
                      'premier poteau.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7785)),
            ),
          ],
        ),
      ),
    );
  }
}
