import 'package:poteaux_incendie/models/company.dart';
import 'package:poteaux_incendie/models/contact_entry.dart';
import 'package:poteaux_incendie/models/fiche_pi.dart';

/// Une societe complete, pour les tests.
///
/// Les societes sont livrees avec leur nom seul : les tests qui ont besoin
/// d'un pied de page rempli se donnent donc la leur, inventee de toutes
/// pieces plutot qu'empruntee a une vraie entreprise.
const Company sampleCompany = Company(
  id: 'ter2eaux',
  legalForm: 'SASU',
  name: 'TER2EAUX',
  addressLine: '12, Rue des Ateliers',
  postalCode: '01000',
  city: 'BOURG-EN-BRESSE',
  phone: '04 74 00 00 00',
  email: 'contact@exemple.fr',
  siret: '12345678900012',
  ape: '3700Z',
  rcs: 'BOURG EN BRESSE B 123 456 789',
  vatNumber: 'FR00123456789',
  capital: '5 000,00 €',
);

/// La fiche du modele papier, transcrite : elle sert de reference aux tests
/// de mise en page comme aux tests de serialisation.
FichePi sampleFiche() => FichePi(
      id: 'fiche-1',
      createdAt: DateTime(2026, 4, 29),
      updatedAt: DateTime(2026, 4, 29),
      companyId: 'ter2eaux',
      orderNumber: '45 013',
      communeName: 'SAINT-REMY (01)',
      editionDate: DateTime(2026, 4, 29),
      sdisCenter: const ContactEntry(
        id: 'sdis-1',
        addressLine: '200 avenue du Capitaine Dhonne',
        postalCode: '01000',
        city: 'BOURG-EN-BRESSE',
        phone: '04.37.62.15.00',
        fax: '04.37.62.15.01',
      ),
      collectivity: const ContactEntry(
        id: 'col-1',
        name: 'Mairie de Saint Rémy',
        addressLine: '999, route de St Rémy',
        postalCode: '01310',
        city: 'SAINT-REMY',
        phone: '04.74.24.28.45',
      ),
      hydrantNumber: '013',
      location: '187 Ch du Colombier (Grange Carrée)',
      brand: 'BAYARD',
      model: 'EMERAUDE',
      hydrantType: 'ECS4',
      pipeDiameter: 'DN 100',
      controls: [
        ControlRow(
          year: '2025',
          date: DateTime(2025, 6, 25),
          maxFlow: '155',
          dynamicPressure: '3,2',
          staticPressure: '3,5',
          flowAtOneBar: '136',
          goodOperation: true,
          available: true,
        ),
        ControlRow(year: '2026'),
        ControlRow(year: '2027'),
      ],
      observations: 'R.A.S.',
    );
