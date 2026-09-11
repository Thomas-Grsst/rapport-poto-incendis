import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/company.dart';

/// La charte de la fiche en PDF : les couleurs et les briques de mise en page.
///
/// Ce sont exactement les couleurs de l'application — le bleu foncé des
/// titres, le bleu clair des accents, le bleu pâle des aplats. Une fiche
/// imprimée et l'écran qui l'a produite doivent se ressembler ; et une
/// retouche de charte se fait ici, en un seul endroit, plutôt que dispersée
/// dans la mise en page.
class PdfStyle {
  const PdfStyle._();

  static const PdfColor brandDark = PdfColor.fromInt(0xFF104C7E);
  static const PdfColor brandLight = PdfColor.fromInt(0xFF8FB8E8);
  static const PdfColor paleBlue = PdfColor.fromInt(0xFFEAF2FB);
  static const PdfColor lineGrey = PdfColor.fromInt(0xFFD5DEE8);
  static const PdfColor textGrey = PdfColor.fromInt(0xFF5A6773);
  static const PdfColor success = PdfColor.fromInt(0xFF1F8A5B);
  static const PdfColor danger = PdfColor.fromInt(0xFFB3261E);

  /// Épaisseur des filets de tableau. Assez fine pour ne pas écraser le
  /// texte, assez marquée pour survivre à une photocopie.
  static const double hairline = 0.6;

  static pw.BoxDecoration get frame => pw.BoxDecoration(
        border: pw.Border.all(color: lineGrey, width: hairline),
      );

  // --- Titres ---------------------------------------------------------------

  /// Le titre d'une rubrique, centré au-dessus de son tableau.
  ///
  /// Le modèle papier les écrit en anglaise ; l'italique du bleu de la charte
  /// en garde l'allure sans embarquer une police de plus dans l'application.
  static pw.Widget sectionTitle(String title) => pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(top: 10, bottom: 4),
        alignment: pw.Alignment.center,
        child: pw.Text(
          title,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 11.5,
            color: brandDark,
            fontStyle: pw.FontStyle.italic,
            letterSpacing: 0.4,
          ),
        ),
      );

  // --- Cellules de tableau --------------------------------------------------

  /// Une cellule d'en-tête : fond bleu pâle, texte centré en gras.
  static pw.Widget headerCell(
    String text, {
    double? width,
    double height = 16,
    double fontSize = 7.5,
    int maxLines = 2,
    PdfColor color = brandDark,
    pw.Border? border,
  }) {
    return pw.Container(
      width: width,
      height: height,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 3),
      decoration: pw.BoxDecoration(color: paleBlue, border: border),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        maxLines: maxLines,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Une cellule de valeur.
  static pw.Widget valueCell(
    String text, {
    double? width,
    double height = 17,
    double fontSize = 8.5,
    pw.Alignment alignment = pw.Alignment.center,
    pw.TextAlign textAlign = pw.TextAlign.center,
    bool bold = false,
    PdfColor color = PdfColors.black,
    pw.Border? border,
  }) {
    return pw.Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      decoration: pw.BoxDecoration(border: border),
      child: pw.Text(
        text,
        textAlign: textAlign,
        maxLines: 1,
        overflow: pw.TextOverflow.clip,
        style: pw.TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Le filet qui sépare deux cellules d'une même rangée.
  static pw.Border get cellDivider => const pw.Border(
        left: pw.BorderSide(color: lineGrey, width: hairline),
      );

  /// Le filet qui sépare deux rangées.
  static pw.Border get rowDivider => const pw.Border(
        top: pw.BorderSide(color: lineGrey, width: hairline),
      );

  // --- En-tête et pied de page ----------------------------------------------

  /// Le bandeau réduit des pages suivantes.
  ///
  /// Une fiche tient sur une page ; il n'y a de seconde page que lorsque les
  /// observations débordent, et celle-ci doit alors rappeler de quel poteau
  /// il s'agit — une page volante sans identification ne vaut rien.
  static pw.Widget continuationHeader(String title, String subtitle) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: brandLight, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: brandDark,
              ),
            ),
          ),
          pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 8.5, color: textGrey),
          ),
        ],
      ),
    );
  }

  /// Pied de page : les mentions légales de la société et la pagination.
  ///
  /// Les mentions sont centrées sur toute la largeur et la pagination passe
  /// en dessous : mises côte à côte, une raison sociale un peu longue passait
  /// à la ligne et le numéro de page se retrouvait au milieu du texte.
  static pw.Widget pageFooter(pw.Context context, Company company) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: lineGrey)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            company.legalLine,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 6.5, color: textGrey),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7.5, color: textGrey),
          ),
        ],
      ),
    );
  }

  // --- Photographies --------------------------------------------------------

  /// Un cadre photo titré : le bandeau bleu pâle, puis la vue.
  ///
  /// Le cadre reste dessiné même sans photo, avec le nom de la vue attendue
  /// en son milieu : c'est ainsi que le modèle papier signale ce qui manque,
  /// et une fiche incomplète doit le dire plutôt que de laisser un blanc.
  static pw.Widget photoFrame({
    required String title,
    required double height,
    pw.MemoryImage? image,
    pw.BoxFit fit = pw.BoxFit.cover,
    String emptyLabel = '',
  }) {
    return pw.Container(
      decoration: frame,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            height: 15,
            alignment: pw.Alignment.center,
            decoration: const pw.BoxDecoration(
              color: paleBlue,
              border: pw.Border(
                bottom: pw.BorderSide(color: lineGrey, width: hairline),
              ),
            ),
            child: pw.Text(
              title,
              textAlign: pw.TextAlign.center,
              maxLines: 1,
              style: pw.TextStyle(
                fontSize: 8,
                color: brandDark,
                fontStyle: pw.FontStyle.italic,
                letterSpacing: 0.3,
              ),
            ),
          ),
          pw.Container(
            height: height,
            alignment: pw.Alignment.center,
            padding: image == null || fit == pw.BoxFit.contain
                ? const pw.EdgeInsets.all(3)
                : pw.EdgeInsets.zero,
            child: image == null
                ? pw.Text(
                    emptyLabel.isEmpty ? title.toUpperCase() : emptyLabel,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: textGrey,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  )
                : pw.Image(image, fit: fit),
          ),
        ],
      ),
    );
  }
}
