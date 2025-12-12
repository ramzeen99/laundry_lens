import 'package:laundry_lens/model/model.dart';

class DonneesExemple {
  static List<Machine> get machines => [
    Machine(
      id: '1',
      nom: 'Machine A',
      emplacement: 'Rez-de-chaussée',
      statut: MachineStatus.libre,
    ),
    Machine(
      id: '2',
      nom: 'Lave-linge 2',
      emplacement: 'Étage 1',
      statut: MachineStatus.occupe,
      tempsRestant: 35,
      utilisateurActuel: 'Jean D.',
    ),
    Machine(
      id: '3',
      nom: 'Machine C',
      emplacement: 'Rez-de-chaussée',
      statut: MachineStatus.termine,
      utilisateurActuel: 'Marie L.',
    ),
    Machine(
      id: '4',
      nom: 'Lave-linge 4',
      emplacement: 'Étage 2',
      statut: MachineStatus.libre,
    ),
    Machine(
      id: '5',
      nom: 'Machine E',
      emplacement: 'Sous-sol',
      statut: MachineStatus.occupe,
      tempsRestant: 15,
      utilisateurActuel: 'Pierre M.',
    ),
    Machine(
      id: '6',
      nom: 'Lave-linge 6',
      emplacement: 'Étage 3',
      statut: MachineStatus.termine,
      utilisateurActuel: 'Sophie T.',
    ),
  ];
}
