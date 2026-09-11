import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poteaux_incendie/models/company.dart';
import 'package:poteaux_incendie/models/enums.dart';
import 'package:poteaux_incendie/models/fiche_pi.dart';
import 'package:poteaux_incendie/services/pdf_service.dart';

import 'fake_storage.dart';
import 'sample_fiche.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStorage storage;
  late PdfService service;

  setUp(() {
    storage = FakeStorage();
    service = PdfService(storage);
  });

  /// Enregistre le PDF produit quand `FICHE_PDF_OUT` désigne un dossier.
  ///
  /// C'est ce qui permet de regarder la fiche pour de bon plutôt que de se
  /// fier à la seule taille du fichier — une mise en page ne se vérifie pas
  /// autrement qu'avec les yeux.
  void dump(String name, List<int> bytes) {
    final out = Platform.environment['FICHE_PDF_OUT'];
    if (out == null || out.isEmpty) return;
    Directory(out).createSync(recursive: true);
    File('$out/$name').writeAsBytesSync(bytes);
  }

  group('PdfService', () {
    test('produit un PDF valide', () async {
      final bytes = await service.buildFichePdf(
        fiche: sampleFiche(),
        company: sampleCompany,
      );
      dump('fiche-complete.pdf', bytes);

      expect(bytes.length, greaterThan(2000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('une fiche à peine commencée s’imprime quand même', () async {
      // Le cas se produit tous les jours : on génère la fiche pour la
      // montrer à un agent avant d'avoir tout rempli.
      final fiche = FichePi(
        id: 'vide',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        controls: [ControlRow(year: '2026')],
      );

      final bytes = await service.buildFichePdf(
        fiche: fiche,
        company: const Company(id: Company.ter2eauxId),
      );
      dump('fiche-vide.pdf', bytes);

      expect(bytes.length, greaterThan(1000));
    });

    test('des observations longues ne sont pas perdues', () async {
      final fiche = sampleFiche()
        ..observations = List.generate(
          12,
          (index) => 'Observation numéro $index : le capot présente des '
              'traces de corrosion et la peinture est à reprendre.',
        ).join('\n');

      final bytes = await service.buildFichePdf(
        fiche: fiche,
        company: sampleCompany,
      );
      dump('fiche-observations-longues.pdf', bytes);

      expect(bytes.length, greaterThan(2000));
    });

    test('un logo absent du paquet ne bloque pas la génération', () async {
      // Les sociétés livrées déclarent leur logo dans assets/images/, mais le
      // fichier peut ne pas y être : la fiche doit alors sortir avec la
      // raison sociale à la place, et surtout sortir. Un asset manquant lève
      // une FlutterError, c'est-à-dire une Error et non une Exception — le
      // premier `on Exception` la laissait filer et cassait l'export.
      final bytes = await service.buildFichePdf(
        fiche: sampleFiche(),
        company: const Company(
          id: Company.ter2eauxId,
          name: 'TER2EAUX',
          logoAsset: 'assets/images/logo-qui-nexiste-pas.png',
        ),
      );
      dump('fiche-sans-logo.pdf', bytes);

      expect(bytes.length, greaterThan(2000));
    });

    test('les sociétés livrées s’impriment telles quelles', () async {
      // Le vrai cas de figure : on génère une fiche pour Ter2eaux ou Rezeau
      // sans avoir rien touché aux réglages.
      for (final company in Company.bundled) {
        final bytes = await service.buildFichePdf(
          fiche: sampleFiche(),
          company: company,
        );
        expect(bytes.length, greaterThan(2000), reason: company.id);
      }
    });

    test('les photos manquantes laissent leur cadre en place', () async {
      final fiche = sampleFiche();
      expect(fiche.photoOf(PhotoSlot.hydrant), isNull);

      final bytes =
          await service.buildFichePdf(fiche: fiche, company: sampleCompany);
      expect(bytes.length, greaterThan(2000));
    });

    test('enregistre la fiche dans le dossier des PDF', () async {
      final saved =
          await service.saveFichePdf(fiche: sampleFiche(), company: sampleCompany);

      expect(saved.path, startsWith('fiches/'));
      expect(storage.files[saved.path], isNotNull);
    });

    group('le nom du fichier', () {
      test('porte la commune et le numéro du poteau', () {
        expect(
          service.fileNameFor(sampleFiche()),
          'Fiche-PI_SAINT-REMY-01_013.pdf',
        );
      });

      test('retombe sur la date quand la fiche n’est pas identifiée', () {
        final fiche = sampleFiche()
          ..communeName = ''
          ..hydrantNumber = '';
        expect(service.fileNameFor(fiche), 'Fiche-PI_290426.pdf');
      });
    });
  });
}
