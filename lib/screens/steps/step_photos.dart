import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/fiche_pi.dart';
import '../../models/photo_item.dart';
import '../../services/storage_service.dart';
import '../../state/fiches_provider.dart';
import '../../theme.dart';
import '../../widgets/media_image.dart';
import '../../widgets/preset_chips.dart';
import '../../widgets/question_block.dart';

/// Étape 5 — les trois vues de la fiche.
///
/// Le modèle papier ne laisse pas l'intervenant ranger ses photos comme il
/// l'entend : chaque cadre attend une vue précise — le plan, l'appareil,
/// l'environnement — et le lecteur sait où regarder. L'application demande
/// donc les trois nommément, plutôt qu'un tas de photos à trier plus tard.
///
/// Les photos sont redimensionnées à la prise de vue : une tournée de
/// cinquante fiches doit rester envoyable depuis le bord d'une route.
class PhotosStep extends StatefulWidget {
  const PhotosStep({super.key, required this.draft, required this.onChanged});

  final FichePi draft;
  final VoidCallback onChanged;

  @override
  State<PhotosStep> createState() => _PhotosStepState();
}

class _PhotosStepState extends State<PhotosStep> {
  static const int _maxWidth = 1600;
  static const int _quality = 82;

  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  FichePi get _draft => widget.draft;

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  Future<void> _capture(PhotoSlot slot, ImageSource source) async {
    final storage = context.read<StorageService>();
    final fiches = context.read<FichesProvider>();
    final previous = _draft.photoOf(slot);

    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: _maxWidth.toDouble(),
        imageQuality: _quality,
      );
      if (picked == null) return;

      final stored = await storage.importMedia(picked.path, prefix: slot.name);
      if (!mounted) return;
      _update(() => _draft.setPhoto(slot, fiches.buildPhoto(stored, slot)));

      // L'ancienne vue n'est effacée qu'une fois la nouvelle en place : une
      // photo de terrain ne se reprend pas, et une erreur d'import ne doit
      // pas laisser le cadre vide.
      await storage.deleteFileIfExists(previous?.filePath);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Impossible d'ajouter la photo : $error")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickSource(PhotoSlot slot) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null && mounted) await _capture(slot, source);
  }

  Future<void> _editPhoto(PhotoSlot slot, PhotoItem photo) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Ajouter une légende'),
              subtitle: photo.caption.isEmpty ? null : Text(photo.caption),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final caption = await showTextInputDialog(
                  context,
                  title: 'Légende de la photo',
                  hint: 'Ex. : capot repeint en 2024',
                  initialValue: photo.caption,
                );
                if (caption != null) _update(() => photo.caption = caption);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Remplacer la photo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickSource(slot);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Supprimer'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final storage = context.read<StorageService>();
                _update(() => _draft.setPhoto(slot, null));
                await storage.deleteFileIfExists(photo.filePath);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final slot in PhotoSlot.values)
          QuestionBlock(
            question: slot.label,
            hint: slot.hint,
            optional: true,
            child: _PhotoSlotCard(
              photo: _draft.photoOf(slot),
              busy: _busy,
              onAdd: () => _pickSource(slot),
              onEdit: (photo) => _editPhoto(slot, photo),
            ),
          ),
      ],
    );
  }
}

/// Le cadre d'une vue : la photo si elle est là, l'invitation sinon.
class _PhotoSlotCard extends StatelessWidget {
  const _PhotoSlotCard({
    required this.photo,
    required this.busy,
    required this.onAdd,
    required this.onEdit,
  });

  final PhotoItem? photo;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<PhotoItem> onEdit;

  @override
  Widget build(BuildContext context) {
    final current = photo;

    if (current == null) {
      return Material(
        color: AppColors.paleBlue,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: busy ? null : onAdd,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  busy ? Icons.hourglass_empty : Icons.add_a_photo_outlined,
                  size: 30,
                  color: AppColors.brandDark,
                ),
                const SizedBox(height: 8),
                Text(
                  busy ? 'Import en cours…' : 'Ajouter la photo',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onEdit(current),
            child: SizedBox(
              height: 190,
              width: double.infinity,
              child: MediaImage(path: current.filePath),
            ),
          ),
        ),
        if (current.caption.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            current.caption.trim(),
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7785)),
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => onEdit(current),
            icon: const Icon(Icons.more_horiz, size: 20),
            label: const Text('Légende, remplacer, supprimer'),
          ),
        ),
      ],
    );
  }
}
