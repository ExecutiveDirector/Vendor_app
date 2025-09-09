import 'package:flutter/material.dart';

class RidersScreen extends StatelessWidget {
  const RidersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riders')),
      body: ListView.builder(
        itemCount: 6,
        itemBuilder: (_, i) => Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.pedal_bike)),
            title: Text('Rider ${i+1}'),
            subtitle: const Text('available • 4.7 ★ • 312 deliveries'),
            trailing: const Icon(Icons.more_horiz),
          ),
        ),
      ),
    );
  }
}
