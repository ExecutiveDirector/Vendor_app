import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(onPressed: () {}, child: const Text('Create Ticket')),
          const SizedBox(height: 8),
          for (var i=0; i<5; i++) Card(child: ListTile(title: Text('Ticket #$i'), subtitle: const Text('Open'))),
        ],
      ),
    );
  }
}
