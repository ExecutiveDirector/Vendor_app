import 'package:flutter/material.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: ListView.builder(
        itemCount: 8,
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.reviews),
          title: Text('4.${i} ★ by User ${i+1}'),
          subtitle: const Text('Great food, quick delivery!'),
          trailing: TextButton(onPressed: () {}, child: const Text('Reply')),
        ),
      ),
    );
  }
}
