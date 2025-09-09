import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  String language = 'en';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        SwitchListTile(value: darkMode, onChanged: (v)=>setState(()=>darkMode=v), title: const Text('Dark Theme')),
        ListTile(title: const Text('Language'), subtitle: Text(language)),
        const AboutListTile(applicationName: 'Vendor App', applicationVersion: '1.0.0'),
      ]),
    );
  }
}
