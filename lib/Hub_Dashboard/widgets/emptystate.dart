import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;

  const EmptyState({super.key, this.message = 'No projects available'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.folder_off, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('No projects available', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
