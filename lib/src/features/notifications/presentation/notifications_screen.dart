import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        itemBuilder: (_, i) => ListTile(leading: const Icon(Icons.notifications), title: Text('Message #$i'), subtitle: const Text('Order or system alert')),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: 10,
      ),
    );
  }
}
