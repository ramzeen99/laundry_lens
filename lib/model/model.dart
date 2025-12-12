import 'package:cloud_firestore/cloud_firestore.dart';

// FR : Statut possible d'une machine
// RU : Возможные статусы машины
enum MachineStatus { libre, occupe, termine }

class Machine {
  final String id;
  final String nom;
  final String emplacement;
  final MachineStatus statut;
  final int? tempsRestant;
  final String? utilisateurActuel;
  final Timestamp? lastUpdate;

  Machine({
    required this.id,
    required this.nom,
    required this.emplacement,
    required this.statut,
    this.tempsRestant,
    this.utilisateurActuel,
    this.lastUpdate,
  });

  // FR : Convertir l'objet Machine en Map (pour Firebase)
  // RU : Преобразование объекта Machine в карту (для Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'emplacement': emplacement,
      'statut': _statusToString(statut), // FR : Conversion du statut en texte
      // RU : Преобразование статуса в текст
      'tempsRestant': tempsRestant,
      'utilisateurActuel': utilisateurActuel,
      //'lastUpdate': FieldValue.serverTimestamp(),
    };
  }

  // FR : Créer une instance Machine à partir des données Firebase
  // RU : Создание экземпляра Machine из данных Firebase
  factory Machine.fromFirebase(Map<String, dynamic> data) {
    print('🔄 Mapping Firebase data: $data');
    return Machine(
      id: data['id'] ?? '',
      nom: data['nom'] ?? '',
      emplacement: data['emplacement'] ?? '',
      statut: _parseStatus(data['statut']),
      tempsRestant: data['tempsRestant'],
      utilisateurActuel: data['utilisateurActuel'],
      lastUpdate: data['lastUpdate'],
    );
  }

  // FR : Convertit un texte Firebase en statut MachineStatus
  // RU : Преобразует текст из Firebase в статус MachineStatus
  static MachineStatus _parseStatus(String? status) {
    switch (status) {
      case 'libre':
        return MachineStatus.libre;
      case 'occupe':
        return MachineStatus.occupe;
      case 'termine':
        return MachineStatus.termine;
      default:
        return MachineStatus.libre;
    }
  }

  // FR : Convertit un statut MachineStatus en texte (stocké dans Firebase)
  // RU : Преобразует статус MachineStatus в текст (хранится в Firebase)
  static String _statusToString(MachineStatus status) {
    switch (status) {
      case MachineStatus.libre:
        return 'libre';     // RU : свободна
      case MachineStatus.occupe:
        return 'occupe';    // RU : занята
      case MachineStatus.termine:
        return 'termine';   // RU : завершено
    }
  }

  // FR : Emoji correspondant au statut
  // RU : Эмодзи, соответствующий статусу
  String get emojiStatut {
    switch (statut) {
      case MachineStatus.libre:
        return '🟢'; // RU : свободна
      case MachineStatus.occupe:
        return '🔴'; // RU : занята
      case MachineStatus.termine:
        return '🟠'; // RU : завершено
    }
  }

  // FR : Texte du statut (affiché dans l’UI) → traduit en russe
  // RU : Текст статуса (показывается в интерфейсе)
  String get texteStatut {
    switch (statut) {
      case MachineStatus.libre:
        return 'СВОБОДНА'; // FR : LIBRE
      case MachineStatus.occupe:
        return 'ЗАНЯТА'; // FR : OCCUPÉ
      case MachineStatus.termine:
        return 'ЗАВЕРШЕНО'; // FR : TERMINÉ
    }
  }

  // FR : Formatage lisible de la dernière mise à jour
  // RU : Читаемый формат последнего обновления
  String get lastUpdateFormatted {
    if (lastUpdate == null) return 'Неизвестно'; // FR : Inconnu
    final date = lastUpdate!.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
