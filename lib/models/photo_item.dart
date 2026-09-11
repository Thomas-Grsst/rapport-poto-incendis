import 'enums.dart';

/// Une des trois photos de la fiche.
///
/// [filePath] pointe vers une copie du fichier dans le dossier de
/// l'application : la photo reste disponible meme si l'intervenant vide sa
/// galerie en rentrant du terrain.
class PhotoItem {
  PhotoItem({
    required this.id,
    required this.filePath,
    required this.slot,
    this.caption = '',
  });

  final String id;
  String filePath;

  /// Le cadre de la fiche ou cette photo s'imprime.
  PhotoSlot slot;

  String caption;

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'slot': slot.name,
        'caption': caption,
      };

  factory PhotoItem.fromJson(Map<String, dynamic> json) => PhotoItem(
        id: json['id'] as String,
        filePath: json['filePath'] as String,
        slot: PhotoSlot.fromName(json['slot'] as String?),
        caption: json['caption'] as String? ?? '',
      );
}
