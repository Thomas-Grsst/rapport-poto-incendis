import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/company.dart';
import '../models/fiche_pi.dart';
import '../models/photo_item.dart';
import 'fiche_pi_pdf.dart';
import 'storage_service.dart';

/// Un PDF généré : son contenu, son nom de fichier et l'endroit où il a été
/// enregistré.
class SavedPdf {
  const SavedPdf({
    required this.path,
    required this.fileName,
    required this.bytes,
  });

  final String path;
  final String fileName;
  final Uint8List bytes;
}

/// Génère le PDF d'une fiche de poteau d'incendie.
///
/// Le service ne met rien en page lui-même : il rassemble ce dont la page a
/// besoin — les polices, le logo de la société, les trois photos — et confie
/// la mise en page à [FichePiLayout].
class PdfService {
  PdfService(this._storage);

  final StorageService _storage;

  static final DateFormat _fileDate = DateFormat('ddMMyy');

  static const FichePiLayout _layout = FichePiLayout();

  /// La police du corps de la fiche.
  static const String regularFontAsset = 'assets/fonts/Roboto-Regular.ttf';

  /// Polices du document, chargées une fois pour toutes.
  ///
  /// Les polices intégrées au format PDF (Helvetica et consorts) ne couvrent
  /// pas tout ce qu'une fiche en français contient : le « œ » de
  /// « manœuvrer » et le tiret cadratin en sont absents et seraient
  /// simplement omis à l'impression. Roboto est embarquée dans l'application
  /// pour que la fiche s'imprime à l'identique partout, y compris hors ligne
  /// au bord d'une route.
  Future<pw.ThemeData> get _theme async => _themeFuture ??= _loadTheme();
  Future<pw.ThemeData>? _themeFuture;

  Future<pw.ThemeData> _loadTheme() async => pw.ThemeData.withFont(
        base: await _font(regularFontAsset),
        bold: await _font('assets/fonts/Roboto-Bold.ttf'),
        italic: await _font('assets/fonts/Roboto-Italic.ttf'),
      );

  Future<pw.Font> _font(String asset) async =>
      pw.Font.ttf(await rootBundle.load(asset));

  Future<Uint8List> buildFichePdf({
    required FichePi fiche,
    required Company company,
  }) async {
    final doc = pw.Document(
      title: 'Fiche PI ${fiche.orderNumber} ${fiche.displayTitle}'.trim(),
      author: company.displayName,
      subject: fiche.displaySubtitle,
      theme: await _theme,
    );

    doc.addPage(
      _layout.page(
        fiche: fiche,
        company: company,
        logo: await _logo(company),
        planImage: await _photo(fiche.planPhoto),
        hydrantImage: await _photo(fiche.hydrantPhoto),
        environmentImage: await _photo(fiche.environmentPhoto),
      ),
    );

    return doc.save();
  }

  /// Génère le PDF et l'enregistre dans le dossier « fiches » de
  /// l'application, pour pouvoir le retrouver sans le refabriquer.
  Future<SavedPdf> saveFichePdf({
    required FichePi fiche,
    required Company company,
  }) async {
    final bytes = await buildFichePdf(fiche: fiche, company: company);
    final fileName = fileNameFor(fiche);
    final path = await _storage.writePdf(fileName, bytes);
    return SavedPdf(path: path, fileName: fileName, bytes: bytes);
  }

  /// "Fiche-PI_SAINT-REMY_013.pdf"
  ///
  /// La commune et le numéro du poteau plutôt qu'un identifiant : c'est sous
  /// ce nom que la fiche arrive dans la boîte mail de la collectivité, et il
  /// doit se lire sans l'ouvrir.
  String fileNameFor(FichePi fiche) {
    String clean(String value) => value
        .replaceAll(RegExp(r'[^A-Za-z0-9\-_ ]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');

    final commune = clean(fiche.communeName);
    final number = clean(fiche.hydrantNumber);

    final parts = <String>[
      'Fiche-PI',
      if (commune.isNotEmpty) commune,
      if (number.isNotEmpty) number,
      if (commune.isEmpty && number.isEmpty)
        _fileDate.format(fiche.editionDate),
    ];
    return '${parts.where((part) => part.isNotEmpty).join('_')}.pdf';
  }

  Future<pw.MemoryImage?> _photo(PhotoItem? photo) => _image(photo?.filePath);

  Future<pw.MemoryImage?> _image(String? path) async {
    final bytes = await _storage.readBytes(path);
    return bytes == null ? null : pw.MemoryImage(bytes);
  }

  /// Le logo de la société : celui choisi dans les réglages, sinon celui
  /// livré avec l'application pour cette société.
  ///
  /// La mise en page se passe du logo quand il n'y en a pas : elle imprime
  /// alors la raison sociale à sa place, plutôt que de laisser un trou. Il
  /// n'y a pas de logo générique de repli — celui d'une autre entreprise en
  /// tête d'une fiche vaudrait moins que rien.
  Future<pw.MemoryImage?> _logo(Company company) async {
    final chosen = await _image(company.logoPath);
    if (chosen != null) return chosen;

    final asset = company.logoAsset;
    if (asset == null || asset.isEmpty) return null;

    try {
      final data = await rootBundle.load(asset);
      return pw.MemoryImage(data.buffer.asUint8List());
    } on Exception {
      // Un logo absent du paquet n'empêche pas d'éditer une fiche : il se
      // choisit depuis la galerie du téléphone, dans Réglages → Sociétés.
      return null;
    }
  }
}
