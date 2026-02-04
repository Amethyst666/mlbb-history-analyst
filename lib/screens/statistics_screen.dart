import 'package:flutter/material.dart';
import '../utils/app_strings.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pie_chart, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            AppStrings.get(context, 'search_stats_coming'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(AppStrings.get(context, 'search_stats_desc')),
        ],
      ),
    );
  }
}