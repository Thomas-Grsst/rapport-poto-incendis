import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/enums.dart';
import '../../models/fiche_pi.dart';
import '../../state/settings_provider.dart';
import '../../theme.dart';
import '../../widgets/question_block.dart';
import '../../widgets/status_chip.dart';

/// Étape 6 — les observations et l'état de la fiche.
///
/// Les observations tiennent en une ligne neuf fois sur dix — « R.A.S. » —,
/// d'où les phrases toutes faites : on en touche une et c'est écrit. Le reste
/// du temps, c'est la seule trace d'un défaut constaté, et le champ reste
/// entièrement libre.
class ObservationsStep extends StatefulWidget {
  const ObservationsStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final FichePi draft;
  final VoidCallback onChanged;

  @override
  State<ObservationsStep> createState() => _ObservationsStepState();
}

class _ObservationsStepState extends State<ObservationsStep> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.draft.observations);

  FichePi get _draft => widget.draft;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  /// Ajoute une phrase toute faite à la suite de ce qui est déjà écrit,
  /// plutôt que de le remplacer : on en coche souvent deux.
  void _append(String sentence) {
    final current = _controller.text.trim();
    final next = current.isEmpty ? sentence : '$current\n$sentence';
    _controller.text = next;
    _controller.selection = TextSelection.collapsed(offset: next.length);
    _update(() => _draft.observations = next);
  }

  @override
  Widget build(BuildContext context) {
    final presets =
        context.watch<SettingsProvider>().presetsOf(PresetList.observations);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: 'Quelque chose à signaler ?',
          hint: 'Ce texte se retrouve au bas de la fiche.',
          optional: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                onChanged: (value) => _draft.observations = value,
                maxLines: 4,
                minLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ex. : R.A.S.',
                  alignLabelWithHint: true,
                ),
              ),
              if (presets.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final sentence in presets)
                      ActionChip(
                        avatar: const Icon(Icons.add,
                            size: 16, color: AppColors.brandDark),
                        label: Text(sentence),
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.brandDark,
                        ),
                        onPressed: () => _append(sentence),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        QuestionBlock(
          question: 'État de la fiche',
          hint: 'Proposé à partir du dernier contrôle, modifiable ici.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in FicheStatus.values)
                    GestureDetector(
                      onTap: () => _update(() => _draft.status = status),
                      child: Opacity(
                        opacity: _draft.status == status ? 1 : 0.45,
                        child: StatusChip(status: status),
                      ),
                    ),
                ],
              ),
              if (_draft.status != _draft.suggestedStatus &&
                  _draft.suggestedStatus != FicheStatus.brouillon) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () =>
                      _update(() => _draft.status = _draft.suggestedStatus),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                    'Vos relevés disent « ${_draft.suggestedStatus.label} »',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
