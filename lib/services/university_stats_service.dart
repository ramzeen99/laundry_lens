import 'package:cloud_firestore/cloud_firestore.dart';

class UniversityStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> getUniversityStats(String universityId) async {
    final dormsSnap = await _firestore
        .collection('dorms')
        .where('universityId', isEqualTo: universityId)
        .get();

    final machinesSnap = await _firestore
        .collection('machines')
        .where('universityId', isEqualTo: universityId)
        .get();

    final activeMachines = machinesSnap.docs
        .where((m) => m['status'] == 'active')
        .length;

    final inactiveMachines = machinesSnap.docs
        .where((m) => m['status'] != 'active')
        .length;

    return {
      'dorms': dormsSnap.size,
      'machines': machinesSnap.size,
      'activeMachines': activeMachines,
      'inactiveMachines': inactiveMachines,
    };
  }
}
