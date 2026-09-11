import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/fiche_pi.dart';
import '../../widgets/contact_picker.dart';
import '../../widgets/question_block.dart';

/// Étape 2 — les deux cadres de coordonnées de la fiche.
///
/// Rien ne se tape ici dans le cas ordinaire : le centre de secours et la
/// mairie sont déjà dans le répertoire depuis le premier poteau de la
/// commune, et il n'y a qu'à les désigner.
class ContactsStep extends StatefulWidget {
  const ContactsStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final FichePi draft;
  final VoidCallback onChanged;

  @override
  State<ContactsStep> createState() => _ContactsStepState();
}

class _ContactsStepState extends State<ContactsStep> {
  FichePi get _draft => widget.draft;

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: 'Quel centre du SDISS ?',
          hint: 'Le centre de secours dont dépend ce poteau.',
          child: ContactPicker(
            kind: DirectoryKind.sdis,
            selected: _draft.sdisCenter,
            onChanged: (entry) => _update(() => _draft.sdisCenter = entry),
          ),
        ),
        QuestionBlock(
          question: 'Quelle collectivité ?',
          hint: "La commune ou le syndicat propriétaire de l'appareil.",
          child: ContactPicker(
            kind: DirectoryKind.collectivite,
            selected: _draft.collectivity,
            onChanged: (entry) => _update(() => _draft.collectivity = entry),
          ),
        ),
      ],
    );
  }
}
