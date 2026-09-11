import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/company.dart';
import '../models/contact_entry.dart';
import '../models/enums.dart';
import '../models/fiche_pi.dart';
import 'pdf_style.dart';

/// La mise en page de la fiche de poteau d'incendie, sur une page A4.
///
/// Elle suit rubrique par rubrique le modèle papier — en-tête, coordonnées du
/// centre du SDISS, coordonnées de la collectivité, caractéristiques de
/// l'appareil, détail des contrôles, les trois vues, les observations — mais
/// habillée de la charte de l'application plutôt que du gabarit du tableur
/// dont le modèle est issu.
///
/// Les largeurs de colonne sont fixes et leur somme vaut [contentWidth] :
/// c'est un formulaire, pas un texte au fil de l'eau, et deux fiches côte à
/// côte doivent se lire à la même hauteur d'œil.
class FichePiLayout {
  const FichePiLayout();

  /// Marge latérale de la page.
  static const double sideMargin = 28;

  /// La largeur d'une A4, en points. `PdfPageFormat.a4.width` dit la même
  /// chose mais n'est pas une constante : les largeurs de colonne ci-dessous
  /// en sont déduites à la compilation, et leur somme doit valoir
  /// exactement [contentWidth].
  static const double pageWidth = 595.28;

  /// La largeur utile, entre les deux marges.
  static const double contentWidth = pageWidth - 2 * sideMargin;

  static final DateFormat _shortDate = DateFormat('dd/MM/yy');

  // --- La page --------------------------------------------------------------

  /// La fiche complète, prête à être ajoutée au document.
  ///
  /// C'est une [pw.MultiPage] et non une page unique : la fiche tient sur une
  /// page dans tous les cas ordinaires, mais des observations fournies ne
  /// doivent pas être tronquées — elles débordent alors sur une seconde page
  /// qui rappelle de quel poteau il s'agit.
  pw.MultiPage page({
    required FichePi fiche,
    required Company company,
    pw.MemoryImage? logo,
    pw.MemoryImage? planImage,
    pw.MemoryImage? hydrantImage,
    pw.MemoryImage? environmentImage,
  }) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(sideMargin, 22, sideMargin, 26),
      header: (context) => context.pageNumber == 1
          ? _header(fiche: fiche, company: company, logo: logo)
          : PdfStyle.continuationHeader(
              fiche.displayTitle,
              fiche.displaySubtitle,
            ),
      footer: (context) => PdfStyle.pageFooter(context, company),
      build: (context) => [
        PdfStyle.sectionTitle('COORDONNÉES du Centre du SDISS'),
        _contactBlock(fiche.sdisCenter, emptyLabel: 'Centre non renseigné'),
        PdfStyle.sectionTitle('COORDONNÉES de la Collectivité'),
        _contactBlock(
          fiche.collectivity,
          emptyLabel: 'Collectivité non renseignée',
        ),
        PdfStyle.sectionTitle("CARACTÉRISTIQUES DU POTEAU D'INCENDIE"),
        _hydrantTable(fiche),
        PdfStyle.sectionTitle('DÉTAIL DES INTERVENTIONS DE CONTRÔLE'),
        _controlTable(fiche),
        pw.SizedBox(height: 8),
        _photoBlock(
          planImage: planImage,
          hydrantImage: hydrantImage,
          environmentImage: environmentImage,
        ),
        pw.SizedBox(height: 8),
        _observations(fiche),
      ],
    );
  }

  // --- En-tête --------------------------------------------------------------

  /// Le bandeau de tête : le logo de la société, la commune au centre, le
  /// numéro d'ordre et la date d'édition à droite.
  pw.Widget _header({
    required FichePi fiche,
    required Company company,
    pw.MemoryImage? logo,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfStyle.brandLight, width: 2),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 128,
            height: 52,
            alignment: pw.Alignment.centerLeft,
            child: logo == null
                ? pw.Text(
                    company.displayName,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfStyle.brandDark,
                    ),
                  )
                : pw.Image(logo, fit: pw.BoxFit.contain),
          ),
          pw.Expanded(
            child: pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Text(
                fiche.displayTitle.toUpperCase(),
                textAlign: pw.TextAlign.center,
                maxLines: 2,
                style: pw.TextStyle(
                  fontSize: 19,
                  color: PdfStyle.brandDark,
                  fontStyle: pw.FontStyle.italic,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          pw.SizedBox(
            width: 132,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'N° ORDRE',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfStyle.textGrey,
                        letterSpacing: 0.4,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfStyle.paleBlue,
                        border: pw.Border.all(
                          color: PdfStyle.brandLight,
                          width: PdfStyle.hairline,
                        ),
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                      child: pw.Text(
                        fiche.orderNumber.trim().isEmpty
                            ? '—'
                            : fiche.orderNumber.trim(),
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfStyle.brandDark,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 7),
                pw.Text(
                  'Édition du ${_shortDate.format(fiche.editionDate)}',
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfStyle.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Coordonnées ----------------------------------------------------------

  /// Un cadre de coordonnées : l'adresse principale à gauche, le téléphone,
  /// le fax et le portable à droite.
  pw.Widget _contactBlock(ContactEntry? contact, {required String emptyLabel}) {
    const double contactWidth = 206;
    const double labelWidth = 60;
    const double addressWidth = contentWidth - contactWidth;
    const double rowHeight = 15;

    final lines = contact?.addressLines ?? const <String>[];

    return pw.Container(
      decoration: PdfStyle.frame,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // L'adresse : un en-tête puis les lignes, sur la hauteur des trois
          // rangées de contact d'en face.
          pw.SizedBox(
            width: addressWidth,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                PdfStyle.headerCell('ADRESSE PRINCIPALE', height: 16),
                pw.Container(
                  height: 3 * rowHeight,
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(border: PdfStyle.rowDivider),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: lines.isEmpty
                        ? [
                            pw.Text(
                              emptyLabel,
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                color: PdfStyle.textGrey,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                          ]
                        : [
                            for (final line in lines)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 1.5),
                                child: pw.Text(
                                  line,
                                  maxLines: 1,
                                  style: const pw.TextStyle(fontSize: 8.5),
                                ),
                              ),
                          ],
                  ),
                ),
              ],
            ),
          ),
          // Les trois lignes de contact.
          pw.Container(
            width: contactWidth,
            decoration: pw.BoxDecoration(border: PdfStyle.cellDivider),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                PdfStyle.headerCell('contact', height: 16, fontSize: 8),
                _contactRow('Tel :', contact?.phone ?? '',
                    labelWidth: labelWidth, height: rowHeight),
                _contactRow('Fax :', contact?.fax ?? '',
                    labelWidth: labelWidth, height: rowHeight),
                _contactRow('Port :', contact?.mobile ?? '',
                    labelWidth: labelWidth, height: rowHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _contactRow(
    String label,
    String value, {
    required double labelWidth,
    required double height,
  }) {
    return pw.Container(
      height: height,
      decoration: pw.BoxDecoration(border: PdfStyle.rowDivider),
      child: pw.Row(
        children: [
          pw.Container(
            width: labelWidth,
            height: height,
            alignment: pw.Alignment.centerRight,
            padding: const pw.EdgeInsets.only(right: 6),
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfStyle.textGrey,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              height: height,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(border: PdfStyle.cellDivider),
              child: pw.Text(
                value.trim(),
                maxLines: 1,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Caractéristiques du poteau -------------------------------------------

  /// Les six colonnes qui identifient l'appareil.
  pw.Widget _hydrantTable(FichePi fiche) {
    const widths = <double>[58, 179, 78, 78, 62, 84];
    const titles = <String>[
      'POTEAU n°',
      'LOCALISATION (adresse, etc…)',
      'MARQUE',
      'MODÈLE',
      'TYPE',
      'DN CANALISATION',
    ];
    final values = <String>[
      fiche.hydrantNumber,
      fiche.location,
      fiche.brand,
      fiche.model,
      fiche.hydrantType,
      fiche.pipeDiameter,
    ];

    return pw.Container(
      decoration: PdfStyle.frame,
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              for (var i = 0; i < titles.length; i++)
                PdfStyle.headerCell(
                  titles[i],
                  width: widths[i],
                  height: 22,
                  border: i == 0 ? null : PdfStyle.cellDivider,
                ),
            ],
          ),
          pw.Container(
            decoration: pw.BoxDecoration(border: PdfStyle.rowDivider),
            child: pw.Row(
              children: [
                for (var i = 0; i < values.length; i++)
                  PdfStyle.valueCell(
                    values[i].trim(),
                    width: widths[i],
                    // La localisation est le seul champ qui peut être long :
                    // elle se lit alignée à gauche, comme une adresse.
                    alignment: i == 1
                        ? pw.Alignment.centerLeft
                        : pw.Alignment.center,
                    textAlign: i == 1 ? pw.TextAlign.left : pw.TextAlign.center,
                    border: i == 0 ? null : PdfStyle.cellDivider,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Détail des contrôles -------------------------------------------------

  /// Le tableau des relevés, une ligne par année.
  ///
  /// Les deux dernières colonnes sont coiffées d'un titre commun et se
  /// partagent en OUI / NON : c'est le cœur de la fiche, ce qu'un centre de
  /// secours lit en premier.
  pw.Widget _controlTable(FichePi fiche) {
    const double year = 34;
    const double date = 60;
    const double flow = 70;
    const double dyn = 74;
    const double static_ = 78;
    const double oneBar = 73;
    const double verdict = 75;
    const double half = verdict / 2;

    return pw.Container(
      decoration: PdfStyle.frame,
      child: pw.Column(
        children: [
          // En-tête sur deux niveaux.
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyle.headerCell('ANNÉE', width: year, height: 32),
              _measureHeader('DATE DU\nCONTRÔLE', width: date),
              _measureHeader('DÉBIT MAXIMUM\n(en m³/h)', width: flow),
              _measureHeader('PRESSION DYNAMIQUE\n(en bar)', width: dyn),
              _measureHeader('PRESSION STATIQUE\nAU POTEAU (en bar)',
                  width: static_),
              _measureHeader('DÉBIT à 1 bar de\npression (en m³/h)',
                  width: oneBar),
              _splitHeader('BON FONCTIONNEMENT', width: verdict, half: half),
              _splitHeader('DISPONIBILITÉ', width: verdict, half: half),
            ],
          ),
          for (final row in fiche.controls)
            pw.Container(
              decoration: pw.BoxDecoration(border: PdfStyle.rowDivider),
              child: pw.Row(
                children: [
                  PdfStyle.valueCell(row.year.trim(),
                      width: year, bold: true, color: PdfStyle.brandDark),
                  PdfStyle.valueCell(
                    row.date == null ? '' : _shortDate.format(row.date!),
                    width: date,
                    bold: true,
                    border: PdfStyle.cellDivider,
                  ),
                  PdfStyle.valueCell(row.maxFlow.trim(),
                      width: flow, bold: true, border: PdfStyle.cellDivider),
                  PdfStyle.valueCell(row.dynamicPressure.trim(),
                      width: dyn, bold: true, border: PdfStyle.cellDivider),
                  PdfStyle.valueCell(row.staticPressure.trim(),
                      width: static_, bold: true, border: PdfStyle.cellDivider),
                  PdfStyle.valueCell(row.flowAtOneBar.trim(),
                      width: oneBar, bold: true, border: PdfStyle.cellDivider),
                  _tick(row.goodOperation, yes: true, width: half),
                  _tick(row.goodOperation, yes: false, width: half),
                  _tick(row.available, yes: true, width: half),
                  _tick(row.available, yes: false, width: half),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Un en-tête de colonne de mesure : son intitulé, puis son unité.
  ///
  /// Quatre lignes sont permises et la police est fine : l'unité est la
  /// moitié de l'information — « 3,2 » ne veut rien dire sans le « bar » —
  /// et elle ne doit jamais tomber sous la coupe.
  pw.Widget _measureHeader(String title, {required double width}) =>
      PdfStyle.headerCell(
        title,
        width: width,
        height: 32,
        fontSize: 6.6,
        maxLines: 4,
        border: PdfStyle.cellDivider,
      );

  /// Une colonne d'en-tête coiffant ses deux sous-colonnes OUI / NON.
  pw.Widget _splitHeader(
    String title, {
    required double width,
    required double half,
  }) {
    return pw.Container(
      width: width,
      height: 32,
      decoration: pw.BoxDecoration(border: PdfStyle.cellDivider),
      child: pw.Column(
        children: [
          PdfStyle.headerCell(title, width: width, height: 18, fontSize: 6.8),
          pw.Row(
            children: [
              PdfStyle.headerCell(
                'OUI',
                width: half,
                height: 14,
                fontSize: 7,
                color: PdfStyle.success,
                border: PdfStyle.rowDivider,
              ),
              PdfStyle.headerCell(
                'NON',
                width: half,
                height: 14,
                fontSize: 7,
                color: PdfStyle.danger,
                border: const pw.Border(
                  top: pw.BorderSide(
                      color: PdfStyle.lineGrey, width: PdfStyle.hairline),
                  left: pw.BorderSide(
                      color: PdfStyle.lineGrey, width: PdfStyle.hairline),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// La croix d'une case OUI ou NON, posée seulement dans la bonne colonne.
  pw.Widget _tick(bool? answer, {required bool yes, required double width}) {
    return PdfStyle.valueCell(
      answer == yes ? 'X' : '',
      width: width,
      bold: true,
      fontSize: 9,
      color: yes ? PdfStyle.success : PdfStyle.danger,
      border: PdfStyle.cellDivider,
    );
  }

  // --- Photographies --------------------------------------------------------

  /// Les trois vues, dans la disposition du modèle : le plan et
  /// l'environnement empilés à gauche, l'hydrant sur toute la hauteur à
  /// droite — c'est lui qu'on regarde, il a droit au grand cadre.
  pw.Widget _photoBlock({
    pw.MemoryImage? planImage,
    pw.MemoryImage? hydrantImage,
    pw.MemoryImage? environmentImage,
  }) {
    const double leftWidth = 258;
    const double gap = 8;
    const double rightWidth = contentWidth - leftWidth - gap;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: leftWidth,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              PdfStyle.photoFrame(
                title: PhotoSlot.plan.label.toUpperCase(),
                height: 107,
                image: planImage,
                // Un plan se lit en entier : le rogner couperait justement la
                // rue qui situe le poteau.
                fit: pw.BoxFit.contain,
                emptyLabel: 'EXTRAIT DE PLAN\nDES RÉSEAUX',
              ),
              pw.SizedBox(height: 6),
              PdfStyle.photoFrame(
                title: PhotoSlot.environnement.label.toUpperCase(),
                height: 95,
                image: environmentImage,
                emptyLabel: "PHOTO ÉLOIGNÉE AVEC\nENVIRONNEMENT DE L'HYDRANT",
              ),
            ],
          ),
        ),
        pw.SizedBox(width: gap),
        pw.SizedBox(
          width: rightWidth,
          child: PdfStyle.photoFrame(
            title: PhotoSlot.hydrant.label.toUpperCase(),
            height: 223,
            image: hydrantImage,
            emptyLabel: "PHOTO DE L'HYDRANT\nCONTRÔLÉ",
          ),
        ),
      ],
    );
  }

  // --- Observations ---------------------------------------------------------

  /// Les observations, sous leur titre.
  ///
  /// Le cas ordinaire — « R.A.S. », une phrase — se pose sur des lignes
  /// réglées : la fiche est souvent annotée à la main après impression, et
  /// c'est la place laissée pour cela. Un texte plus long prend le pas sur
  /// les lignes et court au fil de la page, quitte à passer sur une seconde :
  /// une observation tronquée ne vaut rien, et c'est parfois la seule trace
  /// d'un défaut constaté.
  pw.Widget _observations(FichePi fiche) {
    const double lineHeight = 12.5;
    const int lines = 5;
    final text = fiche.observations.trim();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 2),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfStyle.brandLight, width: 1.2),
            ),
          ),
          child: pw.Text(
            'OBSERVATIONS :',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfStyle.brandDark,
              letterSpacing: 0.4,
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        if (_overflows(text, lines))
          pw.Text(
            text,
            style: const pw.TextStyle(fontSize: 9, lineSpacing: 2.5),
          )
        else
          pw.SizedBox(
            width: double.infinity,
            height: lines * lineHeight,
            child: pw.Stack(
              children: [
                pw.Column(
                  children: [
                    for (var i = 0; i < lines; i++)
                      pw.Container(
                        height: lineHeight,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfStyle.lineGrey,
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1, right: 4),
                  child: pw.Text(
                    text,
                    maxLines: lines,
                    style: const pw.TextStyle(fontSize: 9, lineSpacing: 3.4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Vrai quand le texte ne tiendra visiblement pas sur les lignes réglées.
  ///
  /// L'estimation est volontairement grossière — on ne mesure pas le texte
  /// ici — et généreuse dans le bon sens : mieux vaut répéter une observation
  /// un peu longue que d'en perdre la fin.
  static bool _overflows(String text, int lines) {
    const int charsPerLine = 115;
    if (text.isEmpty) return false;
    final wrapped = text
        .split('\n')
        .fold<int>(0, (total, line) => total + (line.length ~/ charsPerLine) + 1);
    return wrapped > lines;
  }
}
