import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fiche_pi.dart';
import '../theme.dart';
import 'media_image.dart';
import 'status_chip.dart';

/// Ligne de la liste des fiches : la photo de l'hydrant, la commune, le
/// poteau, son état et son dernier relevé.
///
/// La vignette est la photo de l'appareil et non un pictogramme : une tournée
/// de contrôle, c'est cent poteaux qui se ressemblent tous sur le papier mais
/// qu'on reconnaît au premier coup d'œil sur une photo.
class FicheCard extends StatelessWidget {
  FicheCard({super.key, required this.fiche, required this.onTap});

  final FichePi fiche;
  final VoidCallback onTap;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final latest = fiche.latestControl;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _thumbnail(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fiche.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fiche.displaySubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF35414D),
                      ),
                    ),
                    if (latest != null &&
                        latest.flowAtOneBar.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.water_drop_outlined,
                            size: 14,
                            color: Color(0xFF8A97A3),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${latest.flowAtOneBar.trim()} m³/h à 1 bar',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF6B7785),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusChip(status: fiche.status, compact: true),
                        const SizedBox(width: 8),
                        Text(
                          _dateFormat.format(latest?.date ?? fiche.editionDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A97A3),
                          ),
                        ),
                        if (fiche.photos.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.photo_camera_outlined,
                            size: 13,
                            color: Color(0xFF8A97A3),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${fiche.photos.length}/3',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8A97A3),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() {
    final photo = fiche.hydrantPhoto ?? fiche.environmentPhoto;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 66,
        height: 66,
        child: MediaImage(
          path: photo?.filePath,
          placeholder: Container(
            color: AppColors.paleBlue,
            child: const Icon(
              Icons.local_fire_department_outlined,
              color: AppColors.brandLight,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
