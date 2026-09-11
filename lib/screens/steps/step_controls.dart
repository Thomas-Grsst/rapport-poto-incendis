import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/fiche_pi.dart';
import '../../theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/question_block.dart';

/// Étape 4 — les relevés de contrôle, une ligne par année.
///
/// La fiche garde les années précédentes en dessous de celle qu'on remplit :
/// c'est ce qui donne son sens au contrôle, car un poteau se juge sur
/// l'évolution de son débit. L'année en cours s'ouvre dépliée, les autres
/// restent repliées tant qu'on n'y touche pas.
class ControlsStep extends StatefulWidget {
  const ControlsStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final FichePi draft;
  final VoidCallback onChanged;

  @override
  State<ControlsStep> createState() => _ControlsStepState();
}

class _ControlsStepState extends State<ControlsStep> {
  FichePi get _draft => widget.draft;

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  /// Une année de plus, à la suite de la dernière.
  void _addYear() {
    final years = _draft.controls
        .map((row) => int.tryParse(row.year.trim()) ?? 0)
        .toList();
    final next = (years.isEmpty ? DateTime.now().year - 1 : years.reduce(
          (a, b) => a > b ? a : b,
        )) +
        1;
    _update(() => _draft.controls.add(ControlRow(year: '$next')));
  }

  void _removeRow(ControlRow row) {
    _update(() => _draft.controls.remove(row));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: "Qu'avez-vous relevé ?",
          hint: 'Les mesures se saisissent comme elles se lisent au '
              'manomètre : « 3,2 » s’imprimera « 3,2 ».',
          child: Column(
            children: [
              for (var index = 0; index < _draft.controls.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ControlCard(
                    key: ValueKey(_draft.controls[index]),
                    row: _draft.controls[index],
                    initiallyExpanded:
                        _draft.controls[index].isFilled || index == 0,
                    onChanged: widget.onChanged,
                    onRefresh: () => setState(() {}),
                    onRemove: _draft.controls.length > 1
                        ? () => _removeRow(_draft.controls[index])
                        : null,
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addYear,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Ajouter une année'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Une année de contrôle : sa date, ses quatre mesures et ses deux verdicts.
class _ControlCard extends StatelessWidget {
  const _ControlCard({
    super.key,
    required this.row,
    required this.initiallyExpanded,
    required this.onChanged,
    required this.onRefresh,
    this.onRemove,
  });

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final ControlRow row;
  final bool initiallyExpanded;
  final VoidCallback onChanged;

  /// Redessine l'étape : le titre replié résume la ligne, il doit suivre.
  final VoidCallback onRefresh;

  final VoidCallback? onRemove;

  void _edit(VoidCallback change) {
    change();
    onChanged();
    onRefresh();
  }

  Future<void> _pickDate(BuildContext context) async {
    final year = int.tryParse(row.year.trim()) ?? DateTime.now().year;
    final picked = await showDatePicker(
      context: context,
      initialDate: row.date ?? DateTime(year, 6, 15),
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5, 12, 31),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) _edit(() => row.date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Les tuiles dépliantes tracent leurs propres filets par-dessus la
        // bordure de la carte : deux traits pour une seule séparation.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(
            row.year.trim().isEmpty ? 'Année à préciser' : row.year.trim(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.brandDark,
            ),
          ),
          subtitle: Text(
            _summary(),
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7785)),
          ),
          children: [
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: AppTextField(
                    initialValue: row.year,
                    label: 'Année',
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _edit(() => row.year = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(context),
                    icon: const Icon(Icons.event_outlined, size: 20),
                    label: Text(
                      row.date == null
                          ? 'Date du contrôle'
                          : _dateFormat.format(row.date!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _measure(
              label: 'Débit maximum',
              suffix: 'm³/h',
              value: row.maxFlow,
              onChanged: (value) => _edit(() => row.maxFlow = value),
            ),
            const SizedBox(height: 10),
            _measure(
              label: 'Pression dynamique',
              suffix: 'bar',
              value: row.dynamicPressure,
              onChanged: (value) => _edit(() => row.dynamicPressure = value),
            ),
            const SizedBox(height: 10),
            _measure(
              label: 'Pression statique au poteau',
              suffix: 'bar',
              value: row.staticPressure,
              onChanged: (value) => _edit(() => row.staticPressure = value),
            ),
            const SizedBox(height: 10),
            _measure(
              label: 'Débit à 1 bar de pression dynamique',
              suffix: 'm³/h',
              value: row.flowAtOneBar,
              onChanged: (value) => _edit(() => row.flowAtOneBar = value),
            ),
            const SizedBox(height: 18),
            _YesNo(
              label: 'Bon fonctionnement',
              value: row.goodOperation,
              onChanged: (value) => _edit(() => row.goodOperation = value),
            ),
            const SizedBox(height: 12),
            _YesNo(
              label: 'Disponibilité',
              value: row.available,
              onChanged: (value) => _edit(() => row.available = value),
            ),
            if (onRemove != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onRemove,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Retirer cette année'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _measure({
    required String label,
    required String suffix,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AppTextField(
            initialValue: value,
            label: label,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textCapitalization: TextCapitalization.none,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 42,
          child: Text(
            suffix,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7785)),
          ),
        ),
      ],
    );
  }

  /// Ce que la ligne repliée annonce : la date, le débit de référence, et le
  /// défaut s'il y en a un.
  String _summary() {
    if (!row.isFilled) return 'Pas encore contrôlé';

    final parts = <String>[
      if (row.date != null) _dateFormat.format(row.date!),
      if (row.flowAtOneBar.trim().isNotEmpty)
        '${row.flowAtOneBar.trim()} m³/h à 1 bar',
      if (row.available == false)
        'indisponible'
      else if (row.goodOperation == false)
        'fonctionnement défectueux',
    ];
    return parts.isEmpty ? 'Relevé en cours' : parts.join('  •  ');
  }
}

/// Un verdict en deux boutons : OUI, NON — et rien tant qu'on n'a pas répondu.
///
/// Retoucher le choix déjà fait l'efface : une case cochée par erreur doit
/// pouvoir revenir à « non renseigné », car une fiche qui affirme « bon
/// fonctionnement : non » alors que personne n'a vérifié est pire qu'une
/// fiche muette.
class _YesNo extends StatelessWidget {
  const _YesNo({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.brandDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Choice(
                label: 'OUI',
                selected: value == true,
                color: AppColors.success,
                onTap: () => onChanged(value == true ? null : true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Choice(
                label: 'NON',
                selected: value == false,
                color: AppColors.danger,
                onTap: () => onChanged(value == false ? null : false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.10) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? color : const Color(0xFFD5DEE8),
              width: selected ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: selected ? color : const Color(0xFF6B7785),
            ),
          ),
        ),
      ),
    );
  }
}
