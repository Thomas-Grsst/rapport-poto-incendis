import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/fiche_pi.dart';
import '../../state/settings_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/question_block.dart';
import '../../widgets/suggest_field.dart';

/// Étape 3 — les caractéristiques de l'appareil.
///
/// C'est la ligne du tableau « CARACTÉRISTIQUES DU POTEAU D'INCENDIE » du
/// modèle, posée une question à la fois. Marque, modèle, type et diamètre se
/// prennent dans les listes des réglages : ce sont toujours les mêmes noms,
/// et une valeur inédite y entre d'elle-même pour les fiches suivantes.
class HydrantStep extends StatefulWidget {
  const HydrantStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final FichePi draft;
  final VoidCallback onChanged;

  @override
  State<HydrantStep> createState() => _HydrantStepState();
}

class _HydrantStepState extends State<HydrantStep> {
  FichePi get _draft => widget.draft;

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  void _remember(PresetList list, String value) {
    context.read<SettingsProvider>().rememberPreset(list, value);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: 'Quel numéro de poteau ?',
          hint: 'Le numéro peint sur l\'appareil, ex. : 013.',
          child: AppTextField(
            initialValue: _draft.hydrantNumber,
            label: 'Poteau n°',
            hint: '013',
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            prefixIcon: Icons.pin_outlined,
            onChanged: (value) => _update(() => _draft.hydrantNumber = value),
          ),
        ),
        QuestionBlock(
          question: 'Où se trouve-t-il ?',
          hint: 'Adresse, carrefour, lieu-dit — de quoi le retrouver.',
          child: AppTextField(
            initialValue: _draft.location,
            label: 'Localisation',
            hint: 'Ex. : 187 Ch du Colombier (Grange Carrée)',
            maxLines: 2,
            prefixIcon: Icons.place_outlined,
            onChanged: (value) => _update(() => _draft.location = value),
          ),
        ),
        QuestionBlock(
          question: 'Quelle marque ?',
          child: SuggestField(
            initialValue: _draft.brand,
            label: 'Marque',
            hint: 'Ex. : BAYARD',
            suggestions: settings.presetsOf(PresetList.brands),
            onChanged: (value) => _update(() => _draft.brand = value),
            onRemember: (value) => _remember(PresetList.brands, value),
          ),
        ),
        QuestionBlock(
          question: 'Quel modèle ?',
          child: SuggestField(
            initialValue: _draft.model,
            label: 'Modèle',
            hint: 'Ex. : EMERAUDE',
            suggestions: settings.presetsOf(PresetList.models),
            onChanged: (value) => _update(() => _draft.model = value),
            onRemember: (value) => _remember(PresetList.models, value),
          ),
        ),
        QuestionBlock(
          question: 'Quel type ?',
          child: SuggestField(
            initialValue: _draft.hydrantType,
            label: 'Type',
            hint: 'Ex. : ECS4',
            suggestions: settings.presetsOf(PresetList.types),
            onChanged: (value) => _update(() => _draft.hydrantType = value),
            onRemember: (value) => _remember(PresetList.types, value),
          ),
        ),
        QuestionBlock(
          question: 'Quel diamètre de canalisation ?',
          child: SuggestField(
            initialValue: _draft.pipeDiameter,
            label: 'DN canalisation',
            hint: 'Ex. : DN 100',
            suggestions: settings.presetsOf(PresetList.diameters),
            onChanged: (value) => _update(() => _draft.pipeDiameter = value),
            onRemember: (value) => _remember(PresetList.diameters, value),
          ),
        ),
      ],
    );
  }
}
