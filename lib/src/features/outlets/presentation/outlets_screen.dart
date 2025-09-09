import 'package:flutter/material.dart';

class OutletsScreen extends StatelessWidget {
  const OutletsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outlets')),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add_location_alt)),
      body: ListView.builder(
        itemCount: 3,
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.store),
          title: Text('Outlet ${i+1}'),
          subtitle: const Text('123 Market St • Open 9am-9pm'),
          trailing: const Icon(Icons.edit_location_alt),
        ),
      ),
    );
  }
}
