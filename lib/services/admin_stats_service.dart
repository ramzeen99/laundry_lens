import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> countCountries() async {
    final snap = await _firestore.collection('countries').get();
    return snap.size;
  }

  Future<int> countDorms() async {
    final snap = await _firestore.collection('dorms').get();
    return snap.size;
  }

  Future<int> countMachines() async {
    final snap = await _firestore.collection('machines').get();
    return snap.size;
  }

  Future<int> countUsers() async {
    final snap = await _firestore.collection('users').get();
    return snap.size;
  }

  Future<Map<String, int>> getGlobalStats() async {
    final results = await Future.wait([
      countCountries(),
      countDorms(),
      countMachines(),
      countUsers(),
    ]);

    return {
      'countries': results[0],
      'dorms': results[1],
      'machines': results[2],
      'users': results[3],
    };
  }
}
