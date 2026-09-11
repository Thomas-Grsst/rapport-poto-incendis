import 'package:flutter_test/flutter_test.dart';
import 'package:poteaux_incendie/models/app_settings.dart';
import 'package:poteaux_incendie/models/company.dart';
import 'package:poteaux_incendie/models/contact_entry.dart';
import 'package:poteaux_incendie/models/enums.dart';
import 'package:poteaux_incendie/state/settings_provider.dart';

import 'fake_storage.dart';

void main() {
  late FakeStorage storage;
  late SettingsProvider settings;

  setUp(() {
    storage = FakeStorage();
    settings = SettingsProvider(storage);
  });

  group('Sociétés', () {
    test('les deux sociétés sont livrées avec l’application', () {
      expect(settings.companies.map((c) => c.id),
          containsAll(<String>[Company.ter2eauxId, Company.rezeauId]));
    });

    test('elles sont livrées sans adresse, donc à compléter', () {
      // Personne n'a saisi ces mentions : les inventer serait pire que de
      // les demander, une fiche portant un faux SIRET n'ayant aucune valeur.
      expect(settings.companies.every((c) => c.needsSetup), isTrue);
    });

    test('modifier une société ne touche pas à l’autre', () async {
      await settings.updateCompany(
        settings.companyFor(Company.rezeauId).copyWith(city: 'ANGERS'),
      );

      expect(settings.companyFor(Company.rezeauId).city, 'ANGERS');
      expect(settings.companyFor(Company.ter2eauxId).city, isEmpty);
    });

    test('une fiche dont la société a disparu s’imprime quand même', () {
      // Le repli évite qu'une fiche devienne inexportable parce qu'on a
      // renommé ou retiré une société dans les réglages.
      expect(settings.companyFor('societe-inconnue').id, Company.ter2eauxId);
    });

    test('le logo choisi remplace celui livré, sans le laisser derrière',
        () async {
      await settings.setLogo(Company.ter2eauxId, 'galerie/logo.png');
      final first = settings.companyFor(Company.ter2eauxId).logoPath;
      expect(first, isNotNull);

      await settings.setLogo(Company.ter2eauxId, 'galerie/logo2.png');
      final second = settings.companyFor(Company.ter2eauxId).logoPath;

      expect(second, isNot(first));
      expect(storage.files.containsKey(first), isFalse);

      await settings.removeLogo(Company.ter2eauxId);
      expect(settings.companyFor(Company.ter2eauxId).logoPath, isNull);
      expect(storage.files.containsKey(second), isFalse);
    });
  });

  group('Répertoires', () {
    test('une entrée nouvelle reçoit un identifiant et se range', () async {
      final stored = await settings.saveContact(
        DirectoryKind.collectivite,
        const ContactEntry(id: '', name: 'Mairie de Saint Rémy'),
      );

      expect(stored.id, isNotEmpty);
      expect(settings.directory(DirectoryKind.collectivite), hasLength(1));
      expect(settings.directory(DirectoryKind.sdis), isEmpty);
    });

    test('ré-enregistrer une entrée la remplace au lieu de la doubler',
        () async {
      final stored = await settings.saveContact(
        DirectoryKind.sdis,
        const ContactEntry(id: '', name: 'Centre de Bourg'),
      );
      await settings.saveContact(
        DirectoryKind.sdis,
        stored.copyWith(phone: '04.37.62.15.00'),
      );

      final directory = settings.directory(DirectoryKind.sdis);
      expect(directory, hasLength(1));
      expect(directory.single.phone, '04.37.62.15.00');
    });

    test('le répertoire survit au redémarrage', () async {
      await settings.saveContact(
        DirectoryKind.collectivite,
        const ContactEntry(id: '', name: 'Mairie de Trévoux'),
      );

      final reloaded = SettingsProvider(storage);
      await reloaded.load();

      expect(reloaded.directory(DirectoryKind.collectivite).single.name,
          'Mairie de Trévoux');
    });

    test('retirer une entrée la sort de la liste', () async {
      final stored = await settings.saveContact(
        DirectoryKind.sdis,
        const ContactEntry(id: '', name: 'Centre de Bourg'),
      );
      await settings.removeContact(DirectoryKind.sdis, stored.id);

      expect(settings.directory(DirectoryKind.sdis), isEmpty);
    });
  });

  group('Listes de choix', () {
    test('une valeur inédite rejoint la liste', () async {
      await settings.rememberPreset(PresetList.brands, 'FONDERIE DU POITOU');
      expect(settings.presetsOf(PresetList.brands),
          contains('FONDERIE DU POITOU'));
    });

    test('une valeur déjà connue n’y entre pas deux fois', () async {
      await settings.rememberPreset(PresetList.brands, 'bayard');
      expect(
        settings.presetsOf(PresetList.brands).where(
              (value) => value.toLowerCase() == 'bayard',
            ),
        hasLength(1),
      );
    });
  });

  test('des réglages sans société repartent sur celles livrées', () {
    // Un fichier tronqué ou une version ancienne ne doit pas laisser
    // l'utilisateur devant une création de fiche sans aucun choix.
    final settings = AppSettings.fromJson(<String, dynamic>{});
    expect(settings.companies, hasLength(2));
  });
}
