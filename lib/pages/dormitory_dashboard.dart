import 'package:flutter/material.dart';

class DormitoryDashboard extends StatefulWidget {
  const DormitoryDashboard({super.key});

  @override
  State<DormitoryDashboard> createState() => _DormitoryDashboardState();
}

class _DormitoryDashboardState extends State<DormitoryDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dortoir')),
      body: Center(child: Text('Machines & stats')),
    );
  }
}
