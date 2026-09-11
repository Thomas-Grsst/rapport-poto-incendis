import 'package:flutter_test/flutter_test.dart';
import 'package:poteaux_incendie/models/app_settings.dart';
import 'package:poteaux_incendie/models/company.dart';
import 'package:poteaux_incendie/models/enums.dart';
import 'package:poteaux_incendie/state/fiches_provider.dart';

import 'fake_storage.dart';
import 'sample_fiche.dart';

void main() {
  late FakeStorage storage;
  late FichesProvider fiches;

  setUp(() {
    storage = FakeStorage();
    fiches = FichesProvider(storage);
  });

  group('FichesProvider', () {
    test('un brouillon part avec trois années de contrôle', () {
      final draft = fiches.createDraft(
        AppSettings.defaults,
        companyId: Company.rezeauId,
      );

      expect(draft.companyId, Company.rezeauId);
      expect(draft.controls, hasLength(3));
      expect(draft.controls.first.year, '${DateTime.now().year}');
      // Seule l'année en cours est datée : les deux suivantes attendent
      // qu'on repasse, imprimées vides sur la fiche.
      expect(draft.controls.first.date, isNotNull);
      expect(draft.controls[1].date, isNull);
    });

    test('le préfixe de tournée pré-remplit le n° d’ordre', () {
      final draft = fiches.createDraft(
        AppSettings.defaults.copyWith(orderNumberPrefix: '45'),
        companyId: Company.ter2eauxId,
      );
      expect(draft.orderNumber, '45');
    });

    test('le n° d’ordre proposé colle le préfixe au n° de poteau', () {
      final settings = AppSettings.defaults.copyWith(orderNumberPrefix: '45');
      final fiche = sampleFiche()..hydrantNumber = '013';

      expect(fiches.suggestOrderNumber(fiche, settings), '45 013');
    });

    test('enregistrer puis recharger retrouve la fiche', () async {
      await fiches.save(sampleFiche());

      final reloaded = FichesProvider(storage);
      await reloaded.load();

      expect(reloaded.all, hasLength(1));
      expect(reloaded.all.first.communeName, 'SAINT-REMY (01)');
      expect(reloaded.all.first.controls.first.flowAtOneBar, '136');
    });

    test('la recherche ignore la casse et les accents', () async {
      await fiches.save(sampleFiche());

      fiches.setQuery('saint remy');
      expect(fiches.visible, hasLength(1));

      fiches.setQuery('colombier');
      expect(fiches.visible, hasLength(1));

      fiches.setQuery('montanay');
      expect(fiches.visible, isEmpty);
    });

    test('les filtres comptent les fiches par état', () async {
      await fiches.save(sampleFiche()..status = FicheStatus.conforme);
      await fiches.save(
        sampleFiche()
          ..status = FicheStatus.indisponible
          ..hydrantNumber = '014',
      );

      // Deux fiches d'identifiant identique ne font qu'une : c'est bien la
      // même, enregistrée deux fois.
      expect(fiches.all, hasLength(1));
      expect(fiches.countFor(FicheFilter.aSuivre), 1);
      expect(fiches.countFor(FicheFilter.conformes), 0);
    });

    test('dupliquer garde le lieu et repart sans relevé ni photo', () {
      final source = sampleFiche();
      final copy = fiches.duplicate(source);

      expect(copy.id, isNot(source.id));
      expect(copy.communeName, 'SAINT-REMY (01)');
      expect(copy.collectivity?.name, 'Mairie de Saint Rémy');
      expect(copy.brand, 'BAYARD');
      // Le poteau suivant de la rue n'est ni le même appareil ni le même
      // relevé : son numéro et ses mesures repartent à zéro.
      expect(copy.hydrantNumber, isEmpty);
      expect(copy.orderNumber, isEmpty);
      expect(copy.photos, isEmpty);
      // La ligne de l'année en cours est datée du jour — on est en train de
      // contrôler ce poteau-là — mais aucune mesure de l'appareil précédent
      // ne la suit.
      expect(copy.controls.first.date, isNotNull);
      expect(copy.controls.first.maxFlow, isEmpty);
      expect(copy.controls.first.flowAtOneBar, isEmpty);
      expect(copy.controls.first.goodOperation, isNull);
      expect(copy.controls.first.available, isNull);
      expect(copy.status, FicheStatus.brouillon);
    });

    test('supprimer une fiche efface ses photos', () async {
      final path = await storage.importMedia('camera.jpg', prefix: 'hydrant');
      final fiche = sampleFiche()
        ..hydrantPhoto = fiches.buildPhoto(path, PhotoSlot.hydrant);

      await fiches.save(fiche);
      await fiches.delete(fiche);

      expect(fiches.all, isEmpty);
      expect(storage.files.containsKey(path), isFalse);
    });
  });
}
