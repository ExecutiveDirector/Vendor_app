import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Settings Data Model
class AppSettings {
  bool darkTheme;
  String language;
  bool notifications;
  bool soundEnabled;
  bool vibrationEnabled;
  double fontSize;
  String currency;
  bool biometricAuth;
  bool autoBackup;
  String backupFrequency;
  bool analyticsEnabled;

  AppSettings({
    this.darkTheme = false,
    this.language = 'English',
    this.notifications = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.fontSize = 16.0,
    this.currency = 'USD',
    this.biometricAuth = false,
    this.autoBackup = true,
    this.backupFrequency = 'Daily',
    this.analyticsEnabled = true,
  });
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Chinese',
    'Japanese',
    'Arabic'
  ];

  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'CNY',
    'SEK',
    'NOK'
  ];

  final List<String> _backupFrequencies = [
    'Daily',
    'Weekly',
    'Monthly',
    'Never'
  ];

  @override
  void initState() {
    super.initState();
    _settings = AppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _settings.darkTheme
          ? ThemeData.dark().copyWith(
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
            )
          : ThemeData.light().copyWith(
              appBarTheme: AppBarTheme(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: _resetToDefaults,
              tooltip: 'Reset to defaults',
            ),
          ],
        ),
        body: ListView(
          children: [
            // Profile Section
            _buildProfileSection(),

            // Appearance Section
            _buildSectionHeader('Appearance'),
            _buildThemeToggle(),
            _buildLanguageSelector(),
            _buildFontSizeSlider(),
            _buildCurrencySelector(),

            const Divider(),

            // Notifications Section
            _buildSectionHeader('Notifications'),
            _buildNotificationToggle(),
            _buildSoundToggle(),
            _buildVibrationToggle(),

            const Divider(),

            // Security Section
            _buildSectionHeader('Security & Privacy'),
            _buildBiometricToggle(),
            _buildChangePasswordTile(),
            _buildAnalyticsToggle(),

            const Divider(),

            // Data & Storage Section
            _buildSectionHeader('Data & Storage'),
            _buildAutoBackupToggle(),
            _buildBackupFrequencySelector(),
            _buildStorageUsageTile(),
            _buildClearCacheTile(),
            _buildExportDataTile(),

            const Divider(),

            // Support Section
            _buildSectionHeader('Support'),
            _buildHelpTile(),
            _buildContactSupportTile(),
            _buildRateAppTile(),

            const Divider(),

            // About Section
            _buildSectionHeader('About'),
            _buildAboutTile(),
            _buildPrivacyPolicyTile(),
            _buildTermsOfServiceTile(),

            const SizedBox(height: 20),

            // Sign Out Button
            _buildSignOutButton(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _settings.darkTheme
              ? [Colors.grey[800]!, Colors.grey[900]!]
              : [Colors.blue[50]!, Colors.blue[100]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.person, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'John Doe',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text('john.doe@example.com'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _editProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return SwitchListTile(
      title: const Text('Dark Theme'),
      subtitle: const Text('Switch between light and dark mode'),
      value: _settings.darkTheme,
      onChanged: (value) {
        setState(() {
          _settings.darkTheme = value;
        });
        _showSnackBar('Theme updated');
      },
      secondary: Icon(_settings.darkTheme ? Icons.dark_mode : Icons.light_mode),
    );
  }

  Widget _buildLanguageSelector() {
    return ListTile(
      title: const Text('Language'),
      subtitle: Text(_settings.language),
      leading: const Icon(Icons.language),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => _showLanguageDialog(),
    );
  }

  Widget _buildFontSizeSlider() {
    return ListTile(
      title: const Text('Font Size'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current: ${_settings.fontSize.toInt()}sp'),
          Slider(
            value: _settings.fontSize,
            min: 12.0,
            max: 24.0,
            divisions: 12,
            onChanged: (value) {
              setState(() {
                _settings.fontSize = value;
              });
            },
            onChangeEnd: (value) {
              _showSnackBar('Font size updated');
            },
          ),
        ],
      ),
      leading: const Icon(Icons.text_fields),
    );
  }

  Widget _buildCurrencySelector() {
    return ListTile(
      title: const Text('Currency'),
      subtitle: Text(_settings.currency),
      leading: const Icon(Icons.attach_money),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => _showCurrencyDialog(),
    );
  }

  Widget _buildNotificationToggle() {
    return SwitchListTile(
      title: const Text('Push Notifications'),
      subtitle: const Text('Receive important updates and alerts'),
      value: _settings.notifications,
      onChanged: (value) {
        setState(() {
          _settings.notifications = value;
        });
        _showSnackBar(
            value ? 'Notifications enabled' : 'Notifications disabled');
      },
      secondary: const Icon(Icons.notifications),
    );
  }

  Widget _buildSoundToggle() {
    return SwitchListTile(
      title: const Text('Sound Effects'),
      subtitle: const Text('Play sounds for notifications and actions'),
      value: _settings.soundEnabled,
      onChanged: _settings.notifications
          ? (value) {
              setState(() {
                _settings.soundEnabled = value;
              });
              if (value) {
                SystemSound.play(SystemSoundType.click);
              }
            }
          : null,
      secondary:
          Icon(_settings.soundEnabled ? Icons.volume_up : Icons.volume_off),
    );
  }

  Widget _buildVibrationToggle() {
    return SwitchListTile(
      title: const Text('Vibration'),
      subtitle: const Text('Vibrate for notifications and feedback'),
      value: _settings.vibrationEnabled,
      onChanged: _settings.notifications
          ? (value) {
              setState(() {
                _settings.vibrationEnabled = value;
              });
              if (value) {
                HapticFeedback.lightImpact();
              }
            }
          : null,
      secondary: const Icon(Icons.vibration),
    );
  }

  Widget _buildBiometricToggle() {
    return SwitchListTile(
      title: const Text('Biometric Authentication'),
      subtitle: const Text('Use fingerprint or face recognition to unlock'),
      value: _settings.biometricAuth,
      onChanged: (value) {
        _showBiometricConfirmation(value);
      },
      secondary: const Icon(Icons.fingerprint),
    );
  }

  Widget _buildChangePasswordTile() {
    return ListTile(
      title: const Text('Change Password'),
      subtitle: const Text('Update your account password'),
      leading: const Icon(Icons.lock),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: _changePassword,
    );
  }

  Widget _buildAnalyticsToggle() {
    return SwitchListTile(
      title: const Text('Analytics & Crash Reports'),
      subtitle: const Text('Help improve the app by sharing usage data'),
      value: _settings.analyticsEnabled,
      onChanged: (value) {
        setState(() {
          _settings.analyticsEnabled = value;
        });
        _showSnackBar(value ? 'Analytics enabled' : 'Analytics disabled');
      },
      secondary: const Icon(Icons.analytics),
    );
  }

  Widget _buildAutoBackupToggle() {
    return SwitchListTile(
      title: const Text('Auto Backup'),
      subtitle: const Text('Automatically backup your data'),
      value: _settings.autoBackup,
      onChanged: (value) {
        setState(() {
          _settings.autoBackup = value;
        });
        _showSnackBar(value ? 'Auto backup enabled' : 'Auto backup disabled');
      },
      secondary: const Icon(Icons.backup),
    );
  }

  Widget _buildBackupFrequencySelector() {
    return ListTile(
      title: const Text('Backup Frequency'),
      subtitle: Text(_settings.backupFrequency),
      leading: const Icon(Icons.schedule),
      trailing: const Icon(Icons.arrow_forward_ios),
      enabled: _settings.autoBackup,
      onTap: _settings.autoBackup ? () => _showBackupFrequencyDialog() : null,
    );
  }

  Widget _buildStorageUsageTile() {
    return ListTile(
      title: const Text('Storage Usage'),
      subtitle: const Text('View app storage usage'),
      leading: const Icon(Icons.storage),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: _showStorageUsage,
    );
  }

  Widget _buildClearCacheTile() {
    return ListTile(
      title: const Text('Clear Cache'),
      subtitle: const Text('Free up space by clearing temporary files'),
      leading: const Icon(Icons.cleaning_services),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: _clearCache,
    );
  }

  Widget _buildExportDataTile() {
    return ListTile(
      title: const Text('Export Data'),
      subtitle: const Text('Download your data as a backup file'),
      leading: const Icon(Icons.download),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: _exportData,
    );
  }

  Widget _buildHelpTile() {
    return ListTile(
      title: const Text('Help & FAQ'),
      subtitle: const Text('Get help and find answers'),
      leading: const Icon(Icons.help),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: _showHelp,
    );
  }

  Widget _buildContactSupportTile() {
    return ListTile(
      title: const Text('Contact Support'),
      subtitle: const Text('Get in touch with our support team'),
      leading: const Icon(Icons.support_agent),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: _contactSupport,
    );
  }

  Widget _buildRateAppTile() {
    return ListTile(
      title: const Text('Rate This App'),
      subtitle: const Text('Share your feedback on the app store'),
      leading: const Icon(Icons.star_rate),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: _rateApp,
    );
  }

  Widget _buildAboutTile() {
    return const AboutListTile(
      icon: Icon(Icons.info),
      applicationName: 'Vendor App',
      applicationVersion: '1.2.3',
      applicationLegalese: '© 2024 Smart Gas Vendor',
      aboutBoxChildren: [
        Text(
            'A comprehensive vendor management application with modern features and intuitive design.'),
      ],
    );
  }

  Widget _buildPrivacyPolicyTile() {
    return ListTile(
      title: const Text('Privacy Policy'),
      subtitle: const Text('Read our privacy policy'),
      leading: const Icon(Icons.privacy_tip),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: _showPrivacyPolicy,
    );
  }

  Widget _buildTermsOfServiceTile() {
    return ListTile(
      title: const Text('Terms of Service'),
      subtitle: const Text('View terms and conditions'),
      leading: const Icon(Icons.description),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: _showTermsOfService,
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout),
        label: const Text('Sign Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // Dialog Methods
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languages
                .map((language) => RadioListTile<String>(
                      title: Text(language),
                      value: language,
                      groupValue: _settings.language,
                      onChanged: (value) {
                        setState(() {
                          _settings.language = value!;
                        });
                        Navigator.pop(context);
                        _showSnackBar('Language changed to $value');
                      },
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _currencies
                .map((currency) => RadioListTile<String>(
                      title: Text(currency),
                      value: currency,
                      groupValue: _settings.currency,
                      onChanged: (value) {
                        setState(() {
                          _settings.currency = value!;
                        });
                        Navigator.pop(context);
                        _showSnackBar('Currency changed to $value');
                      },
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showBackupFrequencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _backupFrequencies
              .map((frequency) => RadioListTile<String>(
                    title: Text(frequency),
                    value: frequency,
                    groupValue: _settings.backupFrequency,
                    onChanged: (value) {
                      setState(() {
                        _settings.backupFrequency = value!;
                      });
                      Navigator.pop(context);
                      _showSnackBar('Backup frequency set to $value');
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showBiometricConfirmation(bool value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(value
            ? 'Enable Biometric Authentication'
            : 'Disable Biometric Authentication'),
        content: Text(value
            ? 'This will enable fingerprint or face recognition to unlock the app. Make sure your device supports biometric authentication.'
            : 'This will disable biometric authentication. You will need to use your password to unlock the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _settings.biometricAuth = value;
              });
              Navigator.pop(context);
              _showSnackBar(value
                  ? 'Biometric authentication enabled'
                  : 'Biometric authentication disabled');
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showStorageUsage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Usage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStorageItem('App Data', '45.2 MB'),
            _buildStorageItem('Cache', '12.8 MB'),
            _buildStorageItem('Images', '23.5 MB'),
            _buildStorageItem('Documents', '8.1 MB'),
            const Divider(),
            _buildStorageItem('Total', '89.6 MB', isTotal: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageItem(String label, String size, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            size,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  // Action Methods
  void _editProfile() {
    _showSnackBar('Edit Profile - Feature coming soon!');
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
            'Are you sure you want to reset all settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _settings = AppSettings();
              });
              Navigator.pop(context);
              _showSnackBar('Settings reset to defaults');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text ==
                      confirmPasswordController.text &&
                  newPasswordController.text.isNotEmpty &&
                  currentPasswordController.text.isNotEmpty) {
                Navigator.pop(context);
                _showSnackBar('Password changed successfully');
              } else {
                _showSnackBar('Please check your passwords and try again');
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
            'This will clear all temporary files and cached data. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Simulate clearing cache with a progress dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Clearing cache...'),
                    ],
                  ),
                ),
              );

              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pop(context);
                _showSnackBar('Cache cleared successfully (12.8 MB freed)');
              });
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Preparing export...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      _showSnackBar('Data exported successfully to Downloads folder');
    });
  }

  void _showHelp() {
    _showSnackBar('Opening Help & FAQ...');
  }

  void _contactSupport() {
    _showSnackBar('Opening contact support...');
  }

  void _rateApp() {
    _showSnackBar('Opening app store for rating...');
  }

  void _showPrivacyPolicy() {
    _showSnackBar('Opening privacy policy...');
  }

  void _showTermsOfService() {
    _showSnackBar('Opening terms of service...');
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Signed out successfully');
              // Here you would typically navigate to login screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
