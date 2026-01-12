import 'package:flutter/material.dart';
import 'package:laundry_lens/services/dormitory_stats_service.dart';

class DormitoryDashboard extends StatefulWidget {
  final String dormId;

  const DormitoryDashboard({
    super.key,
    required this.dormId,
  });

  @override
  State<DormitoryDashboard> createState() => _DormitoryDashboardState();
}

class _DormitoryDashboardState extends State<DormitoryDashboard> {
  final DormitoryStatsService _statsService = DormitoryStatsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord – Dortoir'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _statsService.getDormitoryStats(widget.dormId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erreur'));
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
                _statCard('Machines', data['machines']!, Icons.local_laundry_service),
                _statCard('Actives', data['active']!, Icons.check_circle),
                _statCard('En panne', data['inactive']!, Icons.error),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String title, int value, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 10),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          Text(title),
        ],
      ),
    );
  }
}
