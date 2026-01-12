import 'package:flutter/material.dart';
import 'package:laundry_lens/services/university_stats_service.dart';

class UniversityDashboard extends StatefulWidget {
  final String universityId;

  const UniversityDashboard({
    super.key,
    required this.universityId,
  });

  @override
  State<UniversityDashboard> createState() => _UniversityDashboardState();
}

class _UniversityDashboardState extends State<UniversityDashboard> {
  final UniversityStatsService _statsService = UniversityStatsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord – Université'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _statsService.getUniversityStats(widget.universityId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Erreur lors du chargement'),
            );
          }

          final data = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              children: [
                _statCard('Dortoirs', data['dorms']!, Icons.home),
                _statCard('Machines', data['machines']!, Icons.local_laundry_service),
                _statCard('Actives', data['activeMachines']!, Icons.check_circle),
                _statCard('En panne', data['inactiveMachines']!, Icons.error),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String title, int value, IconData icon) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 10),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(title),
        ],
      ),
    );
  }
}
