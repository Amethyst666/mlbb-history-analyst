import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart, size: 80, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Statistics Coming Soon',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text('Win rates, favorite heroes, and more!'),
        ],
      ),
    );
  }
}
