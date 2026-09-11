import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/contact_entry.dart';
import '../models/enums.dart';
import '../models/fiche_pi.dart';
import '../services/pdf_download.dart';
import '../services/pdf_service.dart';
import '../state/fiches_provider.dart';
import '../state/settings_provider.dart';
import '../theme.dart';
import '../widgets/media_image.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';
import 'fiche_wizard_screen.dart';

/// La fiche complète d'un poteau, avec génération et envoi du PDF.
class FicheDetailScreen extends StatefulWidget {
  const FicheDetailScreen({super.key, required this.ficheId});

  final String ficheId;

  @override
  State<FicheDetailScreen> createState() => _FicheDetailScreenState();
}

class _FicheDetailScreenState extends State<FicheDetailScreen> {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  bool _generating = false;

  Future<void> _edit(FichePi fiche) async {
    await Navigator.of(context).push<FichePi>(
      MaterialPageRoute(builder: (_) => FicheWizardScreen(fiche: fiche)),
    );
  }

  Future<void> _delete(FichePi fiche) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette fiche ?'),
        content: const Text(
          'La fiche et ses photos seront définitivement supprimées du '
          'téléphone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await context.read<FichesProvider>().delete(fiche);
    if (mounted) Navigator.of(context).pop();
  }

  /// Le poteau suivant de la même rue : tout est déjà rempli sauf son numéro,
  /// ses mesures et ses photos.
  Future<void> _duplicate(FichePi fiche) async {
    final fiches = context.read<FichesProvider>();
    final copy = fiches.duplicate(fiche);
    await Navigator.of(context).push<FichePi>(
      MaterialPageRoute(
        builder: (_) => FicheWizardScreen(fiche: copy, isNew: true),
      ),
    );
  }

  /// Génère le PDF puis propose de le prévisualiser, l'imprimer ou l'envoyer.
  Future<void> _generatePdf(FichePi fiche) async {
    final pdfService = context.read<PdfService>();
    final company = context.read<SettingsProvider>().companyFor(fiche.companyId);
    final fiches = context.read<FichesProvider>();

    setState(() => _generating = true);
    try {
      final pdf = await pdfService.saveFichePdf(fiche: fiche, company: company);
      fiche.lastPdfPath = pdf.path;
      await fiches.save(fiche);

      if (!mounted) return;
      await _showPdfActions(fiche, pdf);
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la génération du PDF : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  /// Enregistre le PDF là où l'utilisateur le retrouvera.
  ///
  /// Sur iOS, l'appareil n'a pas de dossier de téléchargements : on ouvre
  /// alors la feuille de partage du système, qui propose « Enregistrer dans
  /// Fichiers » — plutôt que de dire que ce n'est pas possible.
  Future<void> _downloadPdf(FichePi fiche, SavedPdf pdf) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await downloadPdf(pdf.bytes, pdf.fileName);
      if (!mounted) return;

      if (!result.done) {
        await _sharePdf(fiche, pdf);
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.path == null
                ? 'PDF téléchargé : ${pdf.fileName}'
                : 'PDF enregistré dans ${result.path}',
          ),
        ),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Téléchargement impossible : $error')),
      );
    }
  }

  /// Ouvre la feuille de partage du système avec le PDF en pièce jointe.
  ///
  /// Le partage passe par `printing`, déjà utilisé pour l'aperçu, plutôt que
  /// par un second paquet. On partage les octets plutôt qu'un chemin, car
  /// dans un navigateur le PDF n'existe pas comme fichier sur le disque.
  Future<void> _sharePdf(FichePi fiche, SavedPdf pdf) async {
    await Printing.sharePdf(
      bytes: pdf.bytes,
      filename: pdf.fileName,
      subject: 'Fiche poteau incendie — ${fiche.displayTitle} '
          '${fiche.displaySubtitle}',
      body: 'Bonjour,\n\nVeuillez trouver ci-joint la fiche de contrôle du '
          'poteau d\'incendie ${fiche.displaySubtitle}, '
          'commune de ${fiche.displayTitle}.\n\nCordialement,',
    );
  }

  Future<void> _showPdfActions(FichePi fiche, SavedPdf pdf) async {
    await showModalBottomSheet<void>(
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
                  'Fiche générée',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Aperçu / Imprimer'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await Printing.layoutPdf(
                  onLayout: (_) async => pdf.bytes,
                  name: pdf.fileName,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Télécharger le PDF'),
              subtitle: const Text("Garder le fichier sur l'appareil"),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _downloadPdf(fiche, pdf);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send_outlined),
              title: const Text('Envoyer'),
              subtitle: const Text('E-mail, SMS, messagerie…'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _sharePdf(fiche, pdf);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fiche = context.watch<FichesProvider>().byId(widget.ficheId);

    if (fiche == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fiche')),
        body: const Center(child: Text('Cette fiche a été supprimée.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(fiche.displayTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'duplicate') _duplicate(fiche);
              if (value == 'delete') _delete(fiche);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'duplicate',
                child: Text('Poteau suivant (dupliquer)'),
              ),
              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _summaryCard(fiche),
          const SizedBox(height: 12),
          _contactCard(
            title: 'Centre du SDISS',
            icon: Icons.local_fire_department_outlined,
            contact: fiche.sdisCenter,
          ),
          const SizedBox(height: 12),
          _contactCard(
            title: 'Collectivité',
            icon: Icons.account_balance_outlined,
            contact: fiche.collectivity,
          ),
          const SizedBox(height: 12),
          _hydrantCard(fiche),
          const SizedBox(height: 12),
          _controlsCard(fiche),
          const SizedBox(height: 12),
          _photosCard(fiche),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Observations',
            icon: Icons.notes_outlined,
            children: [
              InfoParagraph(
                text: fiche.observations,
                emptyLabel: 'Aucune observation.',
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _actionBar(fiche),
    );
  }

  Widget _summaryCard(FichePi fiche) {
    final company = context.watch<SettingsProvider>().companyFor(fiche.companyId);

    return SectionCard(
      title: fiche.displayTitle,
      icon: Icons.description_outlined,
      trailing: StatusChip(status: fiche.status),
      children: [
        InfoLine(label: 'N° ordre', value: fiche.orderNumber),
        InfoLine(
          label: 'Édition du',
          value: _dateFormat.format(fiche.editionDate),
        ),
        InfoLine(
          label: 'Société',
          value: company.name.isEmpty ? company.id : company.name,
        ),
      ],
    );
  }

  Widget _contactCard({
    required String title,
    required IconData icon,
    required ContactEntry? contact,
  }) {
    return SectionCard(
      title: title,
      icon: icon,
      children: [
        if (contact == null)
          const Text(
            'Non renseigné.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF8A97A3),
              fontStyle: FontStyle.italic,
            ),
          )
        else ...[
          InfoLine(label: 'Adresse', value: contact.addressLines.join('\n')),
          InfoLine(label: 'Tél.', value: contact.phone),
          InfoLine(label: 'Fax', value: contact.fax),
          InfoLine(label: 'Portable', value: contact.mobile),
        ],
      ],
    );
  }

  Widget _hydrantCard(FichePi fiche) {
    return SectionCard(
      title: "Caractéristiques de l'appareil",
      icon: Icons.settings_outlined,
      children: [
        InfoLine(label: 'Poteau n°', value: fiche.hydrantNumber),
        InfoLine(label: 'Localisation', value: fiche.location),
        InfoLine(label: 'Marque', value: fiche.brand),
        InfoLine(label: 'Modèle', value: fiche.model),
        InfoLine(label: 'Type', value: fiche.hydrantType),
        InfoLine(label: 'DN canalisation', value: fiche.pipeDiameter),
      ],
    );
  }

  /// Le tableau des relevés, tel qu'il s'imprimera — en plus étroit.
  Widget _controlsCard(FichePi fiche) {
    final filled = fiche.controls.where((row) => row.isFilled).toList();

    return SectionCard(
      title: 'Contrôles',
      icon: Icons.speed_outlined,
      children: [
        if (filled.isEmpty)
          const Text(
            'Aucun relevé pour le moment.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF8A97A3),
              fontStyle: FontStyle.italic,
            ),
          )
        else
          for (final row in filled) ...[
            Row(
              children: [
                Text(
                  row.year.trim(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(width: 10),
                if (row.date != null)
                  Text(
                    _dateFormat.format(row.date!),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7785),
                    ),
                  ),
                const Spacer(),
                _verdict('Fonctionnement', row.goodOperation),
                const SizedBox(width: 8),
                _verdict('Disponible', row.available),
              ],
            ),
            const SizedBox(height: 6),
            InfoLine(label: 'Débit max.', value: _unit(row.maxFlow, 'm³/h')),
            InfoLine(
              label: 'Pression dyn.',
              value: _unit(row.dynamicPressure, 'bar'),
            ),
            InfoLine(
              label: 'Pression stat.',
              value: _unit(row.staticPressure, 'bar'),
            ),
            InfoLine(
              label: 'Débit à 1 bar',
              value: _unit(row.flowAtOneBar, 'm³/h'),
            ),
            if (row != filled.last) const Divider(height: 20),
          ],
      ],
    );
  }

  static String _unit(String value, String unit) =>
      value.trim().isEmpty ? '' : '${value.trim()} $unit';

  Widget _verdict(String label, bool? value) {
    if (value == null) return const SizedBox.shrink();
    final color = value ? AppColors.success : AppColors.danger;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(value ? Icons.check_circle : Icons.cancel, size: 15, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _photosCard(FichePi fiche) {
    return SectionCard(
      title: 'Photographies (${fiche.photos.length}/3)',
      icon: Icons.photo_camera_outlined,
      children: [
        for (final slot in PhotoSlot.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: MediaImage(
                      path: fiche.photoOf(slot)?.filePath,
                      placeholder: Container(
                        color: AppColors.paleBlue,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.brandLight,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fiche.photoOf(slot) == null
                            ? 'Manquante'
                            : (fiche.photoOf(slot)!.caption.trim().isEmpty
                                ? 'Présente'
                                : fiche.photoOf(slot)!.caption.trim()),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: fiche.photoOf(slot) == null
                              ? AppColors.warning
                              : const Color(0xFF6B7785),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _actionBar(FichePi fiche) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _edit(fiche),
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Modifier'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _generating ? null : () => _generatePdf(fiche),
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined, size: 20),
              label: Text(_generating ? 'Génération…' : 'Générer le PDF'),
            ),
          ),
        ],
      ),
    );
  }
}
