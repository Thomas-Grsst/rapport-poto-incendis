import 'package:flutter/material.dart';

import '../theme.dart';

/// Un champ de saisie doublé de ses valeurs courantes, proposées en pastilles.
///
/// Sur le terrain, la marque et le type d'un appareil se prennent dans une
/// liste de six ou sept noms qui reviennent sans cesse : les taper au clavier,
/// une main sur le poteau, n'a pas de sens. Le champ reste libre pour le
/// modèle qu'on rencontre une fois par an — et cette valeur-là peut rejoindre
/// la liste, via [onRemember].
class SuggestField extends StatefulWidget {
  const SuggestField({
    super.key,
    required this.initialValue,
    required this.label,
    required this.suggestions,
    required this.onChanged,
    this.hint,
    this.onRemember,
    this.textCapitalization = TextCapitalization.characters,
  });

  final String initialValue;
  final String label;
  final String? hint;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;

  /// Appelé quand la valeur saisie n'était pas proposée, pour la mémoriser.
  final ValueChanged<String>? onRemember;

  final TextCapitalization textCapitalization;

  @override
  State<SuggestField> createState() => _SuggestFieldState();
}

class _SuggestFieldState extends State<SuggestField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  late String _value = widget.initialValue;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(String value) {
    setState(() => _value = value);
    widget.onChanged(value);
  }

  /// Toucher une pastille déjà choisie la désélectionne : c'est ainsi qu'on
  /// corrige une erreur de doigt sans avoir à vider le champ au clavier.
  void _tap(String option) {
    final next = _value.trim().toLowerCase() == option.toLowerCase()
        ? ''
        : option;
    _controller.text = next;
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    _set(next);
  }

  void _remember() {
    final trimmed = _value.trim();
    if (trimmed.isEmpty) return;
    final known = widget.suggestions
        .any((option) => option.toLowerCase() == trimmed.toLowerCase());
    if (!known) widget.onRemember?.call(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: _set,
          onEditingComplete: _remember,
          onTapOutside: (_) => _remember(),
          textCapitalization: widget.textCapitalization,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
          ),
        ),
        if (widget.suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in widget.suggestions)
                ChoiceChip(
                  label: Text(option),
                  selected: _value.trim().toLowerCase() == option.toLowerCase(),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: _value.trim().toLowerCase() == option.toLowerCase()
                        ? AppColors.brandDark
                        : const Color(0xFF35414D),
                    fontWeight:
                        _value.trim().toLowerCase() == option.toLowerCase()
                            ? FontWeight.w600
                            : FontWeight.w400,
                  ),
                  onSelected: (_) => _tap(option),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
