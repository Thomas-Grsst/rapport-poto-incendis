import 'package:flutter_test/flutter_test.dart';
import 'package:poteaux_incendie/models/enums.dart';
import 'package:poteaux_incendie/models/fiche_pi.dart';
import 'package:poteaux_incendie/models/photo_item.dart';

import 'sample_fiche.dart';

void main() {
  group('FichePi', () {
    test('survit a un aller-retour par le JSON', () {
      final original = sampleFiche()
        ..hydrantPhoto = PhotoItem(
          id: 'p1',
          filePath: 'media/hydrant_0.jpg',
          slot: PhotoSlot.hydrant,
          caption: 'capot repeint',
        );

      final copy = FichePi.fromJson(original.toJson());

      expect(copy.orderNumber, '45 013');
      expect(copy.communeName, 'SAINT-REMY (01)');
      expect(copy.collectivity?.name, 'Mairie de Saint Rémy');
      expect(copy.sdisCenter?.phone, '04.37.62.15.00');
      expect(copy.controls, hasLength(3));
      expect(copy.controls.first.dynamicPressure, '3,2');
      expect(copy.controls.first.date, DateTime(2025, 6, 25));
      expect(copy.hydrantPhoto?.caption, 'capot repeint');
      expect(copy.planPhoto, isNull);
    });

    test('la virgule des relevés est imprimée telle quelle', () {
      // Un aller-retour par un double aurait rendu « 3.2 » : sur la fiche,
      // c'est la valeur lue au manomètre qui doit s'imprimer.
      final copy = FichePi.fromJson(sampleFiche().toJson());
      expect(copy.controls.first.dynamicPressure, '3,2');
      expect(copy.controls.first.staticPressure, '3,5');
    });

    test('cloner ne partage rien avec la fiche d’origine', () {
      final fiche = sampleFiche();
      final clone = fiche.clone();

      clone.communeName = 'AUTRE COMMUNE';
      clone.controls.first.maxFlow = '999';
      clone.controls.add(ControlRow(year: '2028'));

      expect(fiche.communeName, 'SAINT-REMY (01)');
      expect(fiche.controls.first.maxFlow, '155');
      expect(fiche.controls, hasLength(3));
    });

    test('le dernier contrôle est celui de l’année la plus récente', () {
      final fiche = sampleFiche();
      fiche.controls[1]
        ..date = DateTime(2026, 5, 2)
        ..flowAtOneBar = '120';

      expect(fiche.latestControl?.year, '2026');
      expect(fiche.latestControl?.flowAtOneBar, '120');
    });

    test('une ligne vide ne compte pas comme un contrôle', () {
      final fiche = sampleFiche();
      expect(fiche.controls[1].isFilled, isFalse);
      expect(fiche.latestControl?.year, '2025');
    });

    group("l'état proposé", () {
      test('est conforme quand tout va bien', () {
        expect(sampleFiche().suggestedStatus, FicheStatus.conforme);
      });

      test('est « à suivre » sur un mauvais fonctionnement', () {
        final fiche = sampleFiche();
        fiche.controls.first.goodOperation = false;
        expect(fiche.suggestedStatus, FicheStatus.aSuivre);
      });

      test('est « indisponible » dès que le poteau ne l’est plus', () {
        // L'indisponibilité prime : c'est ce qu'un centre de secours doit
        // voir en premier, même si l'appareil fonctionne par ailleurs.
        final fiche = sampleFiche();
        fiche.controls.first
          ..goodOperation = true
          ..available = false;
        expect(fiche.suggestedStatus, FicheStatus.indisponible);
      });

      test('reste un brouillon tant que rien n’est relevé', () {
        final fiche = sampleFiche();
        fiche.controls.clear();
        expect(fiche.suggestedStatus, FicheStatus.brouillon);
      });
    });

    test('les photos se rangent dans leur cadre', () {
      final fiche = sampleFiche();
      final photo =
          PhotoItem(id: 'p', filePath: 'media/plan.jpg', slot: PhotoSlot.plan);

      fiche.setPhoto(PhotoSlot.plan, photo);

      expect(fiche.photoOf(PhotoSlot.plan), same(photo));
      expect(fiche.photoOf(PhotoSlot.hydrant), isNull);
      expect(fiche.photos, hasLength(1));
    });

    test('le titre retombe sur le lieu-dit sans commune', () {
      final fiche = sampleFiche()..communeName = '';
      expect(fiche.displayTitle, '187 Ch du Colombier (Grange Carrée)');
      expect(fiche.displaySubtitle, contains('Poteau n° 013'));
    });
  });
}
