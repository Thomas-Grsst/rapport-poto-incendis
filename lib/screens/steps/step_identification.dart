import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/company.dart';
import '../../models/fiche_pi.dart';
import '../../state/fiches_provider.dart';
import '../../state/settings_provider.dart';
import '../../theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/question_block.dart';

/// Étape 1 — l'en-tête de la fiche : la société, la commune, le numéro
/// d'ordre et la date d'édition.
///
/// La société se choisit ici et non dans les réglages : le même intervenant
/// contrôle des poteaux pour Ter2eaux un jour et pour Rezeau le lendemain, et
/// c'est elle qui décide du logo imprimé en tête et des mentions légales en
/// pied de la fiche.
class IdentificationStep extends StatefulWidget {
  const IdentificationStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final FichePi draft;
  final VoidCallback onChanged;

  @override
  State<IdentificationStep> createState() => _IdentificationStepState();
}

class _IdentificationStepState extends State<IdentificationStep> {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  FichePi get _draft => widget.draft;

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  Future<void> _pickEditionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.editionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) _update(() => _draft.editionDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final companies = context.watch<SettingsProvider>().companies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: 'Pour quelle société ?',
          hint: 'Son logo et ses mentions légales habilleront la fiche.',
          child: Column(
            children: [
              for (final company in companies)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CompanyTile(
                    company: company,
                    selected: company.id == _draft.companyId,
                    onTap: () => _update(() => _draft.companyId = company.id),
                  ),
                ),
            ],
          ),
        ),
        QuestionBlock(
          question: 'Quelle commune ?',
          hint: "Elle s'imprime en gros au centre de la fiche.",
          child: AppTextField(
            initialValue: _draft.communeName,
            label: 'Commune',
            hint: 'Ex. : SAINT-REMY (01)',
            textCapitalization: TextCapitalization.characters,
            prefixIcon: Icons.location_city_outlined,
            onChanged: (value) => _update(() => _draft.communeName = value),
          ),
        ),
        QuestionBlock(
          question: "Quel numéro d'ordre ?",
          hint: 'Le repère du dossier, en haut à droite de la fiche.',
          child: _OrderNumberField(
            draft: _draft,
            onChanged: (value) => _update(() => _draft.orderNumber = value),
          ),
        ),
        QuestionBlock(
          question: "Date d'édition",
          child: OutlinedButton.icon(
            onPressed: _pickEditionDate,
            icon: const Icon(Icons.event_outlined, size: 20),
            label: Text(_dateFormat.format(_draft.editionDate)),
          ),
        ),
      ],
    );
  }
}

/// Une société, présentée comme une carte à cocher.
class _CompanyTile extends StatelessWidget {
  const _CompanyTile({
    required this.company,
    required this.selected,
    required this.onTap,
  });

  final Company company;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.paleBlue : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.brandDark : const Color(0xFFD5DEE8),
              width: selected ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color:
                    selected ? AppColors.brandDark : const Color(0xFF8A97A3),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name.isEmpty ? company.id : company.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandDark,
                      ),
                    ),
                    if (company.addressOneLine.isNotEmpty ||
                        company.website.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        company.addressOneLine.isNotEmpty
                            ? company.addressOneLine
                            : company.website,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7785),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le numéro d'ordre, avec la proposition tirée du préfixe de la tournée.
class _OrderNumberField extends StatefulWidget {
  const _OrderNumberField({required this.draft, required this.onChanged});

  final FichePi draft;
  final ValueChanged<String> onChanged;

  @override
  State<_OrderNumberField> createState() => _OrderNumberFieldState();
}

class _OrderNumberFieldState extends State<_OrderNumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.draft.orderNumber);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applySuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection =
        TextSelection.collapsed(offset: suggestion.length);
    widget.onChanged(suggestion);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final suggestion =
        context.read<FichesProvider>().suggestOrderNumber(widget.draft, settings);
    final showSuggestion =
        suggestion.isNotEmpty && suggestion != _controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: (value) {
            widget.onChanged(value);
            setState(() {});
          },
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'N° ordre',
            hintText: 'Ex. : 45 013',
            prefixIcon: Icon(Icons.tag, size: 20),
          ),
        ),
        if (showSuggestion) ...[
          const SizedBox(height: 8),
          ActionChip(
            avatar: const Icon(Icons.auto_awesome,
                size: 16, color: AppColors.brandDark),
            label: Text('Proposer « $suggestion »'),
            labelStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.brandDark,
              fontWeight: FontWeight.w600,
            ),
            onPressed: () => _applySuggestion(suggestion),
          ),
        ],
      ],
    );
  }
}
