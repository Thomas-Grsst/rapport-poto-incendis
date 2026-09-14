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

    test('elles sont livrées prêtes à imprimer, rien à saisir', () {
      // Sans adresse, une fiche sortirait sans en-tete ni mentions legales,
      // et l'accueil afficherait un rappel a completer. Les deux societes
      // arrivent renseignees : l'application s'installe et sert aussitot.
      expect(settings.companies.every((c) => c.needsSetup), isFalse);
    });

    test('elles portent les mentions du registre du commerce', () {
      // Verrouille ce qui s'imprime en pied de chaque fiche. Une faute de
      // frappe dans un SIRET ne se voit pas a l'ecran, seulement sur le PDF
      // deja envoye au client.
      final ter2eaux = settings.companyFor(Company.ter2eauxId);
      expect(ter2eaux.displayName, "SAS TER'2EAUX");
      expect(ter2eaux.addressOneLine, 'Allée des Tanneurs - 01600 TREVOUX');
      expect(ter2eaux.siret, '95071699300015');
      expect(ter2eaux.capital, '5 000,00 €');

      final rezeau = settings.companyFor(Company.rezeauId);
      expect(rezeau.displayName, 'SAS REZEAU');
      expect(rezeau.addressOneLine, '2140, Route de Charnay - 69480 MORANCE');
      expect(rezeau.siret, '84510281300027');
      expect(rezeau.email, 'contact@rezeau.fr');
    });

    test('leur numéro de TVA découle du SIREN', () {
      // Le numero intracommunautaire n'est pas attribue au hasard : c'est FR,
      // une cle, puis le SIREN. Recalculer la cle ici prouve que les deux
      // numeros livres sont coherents avec les SIRET ci-dessus, plutot que
      // recopies de travers.
      String attendu(String siret) {
        final siren = int.parse(siret.substring(0, 9));
        final cle = (12 + 3 * (siren % 97)) % 97;
        return 'FR${cle.toString().padLeft(2, '0')}$siren';
      }

      for (final company in settings.companies) {
        expect(company.vatNumber, attendu(company.siret), reason: company.id);
      }
    });

    test('modifier une société ne touche pas à l’autre', () async {
      await settings.updateCompany(
        settings.companyFor(Company.rezeauId).copyWith(city: 'ANGERS'),
      );

      expect(settings.companyFor(Company.rezeauId).city, 'ANGERS');
      expect(settings.companyFor(Company.ter2eauxId).city, 'TREVOUX');
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
