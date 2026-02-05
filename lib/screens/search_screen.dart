import 'package:flutter/material.dart';
import '../utils/app_strings.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 80, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            AppStrings.get(context, 'search_coming'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(AppStrings.get(context, 'search_desc')),
        ],
      ),
    );
  }
}
