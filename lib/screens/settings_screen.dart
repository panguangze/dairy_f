import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coupleNameController = TextEditingController();
  final _partnerNameController = TextEditingController();
  final _relationshipDateController = TextEditingController();

  bool _enableNotifications = true;
  ThemeMode _selectedThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    _coupleNameController.text = appProvider.coupleName;
    _partnerNameController.text = appProvider.partnerName;
    
    if (appProvider.relationshipStartDate.isNotEmpty) {
      final date = DateTime.parse(appProvider.relationshipStartDate);
      _relationshipDateController.text = DateFormat('yyyy-MM-dd').format(date);
    }
    
    _enableNotifications = appProvider.enableNotifications;
    _selectedThemeMode = appProvider.themeMode;
  }

  @override
  void dispose() {
    _coupleNameController.dispose();
    _partnerNameController.dispose();
    _relationshipDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Profile Settings
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _coupleNameController,
                      decoration: InputDecoration(
                        labelText: 'Couple Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a couple name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _partnerNameController,
                      decoration: InputDecoration(
                        labelText: 'Partner Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your partner\'s name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _relationshipDateController,
                      decoration: InputDecoration(
                        labelText: 'Relationship Start Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: _relationshipDateController.text.isNotEmpty
                              ? DateTime.parse(_relationshipDateController.text)
                              : DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );

                        if (selectedDate != null) {
                          setState(() {
                            _relationshipDateController.text = 
                                DateFormat('yyyy-MM-dd').format(selectedDate);
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // App Settings
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    SwitchListTile(
                      title: Text('Enable Notifications'),
                      value: _enableNotifications,
                      onChanged: (value) {
                        setState(() {
                          _enableNotifications = value;
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    ListTile(
                      title: Text('Theme Mode'),
                      subtitle: Text(_getThemeModeString(_selectedThemeMode)),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _showThemeModeDialog();
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // App Info
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildInfoItem('App Version', '1.0.0'),
                    _buildInfoItem('Days Together', appProvider.daysTogether.toString()),
                    _buildInfoItem('Total Entries', appProvider.moodEntries.length.toString()),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Save Button
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getThemeModeString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Follow System';
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      default:
        return 'Follow System';
    }
  }

  void _showThemeModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text('Follow System'),
              value: ThemeMode.system,
              groupValue: _selectedThemeMode,
              onChanged: (value) {
                setState(() {
                  _selectedThemeMode = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text('Light Mode'),
              value: ThemeMode.light,
              groupValue: _selectedThemeMode,
              onChanged: (value) {
                setState(() {
                  _selectedThemeMode = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text('Dark Mode'),
              value: ThemeMode.dark,
              groupValue: _selectedThemeMode,
              onChanged: (value) {
                setState(() {
                  _selectedThemeMode = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      appProvider.updateSettings(
        coupleName: _coupleNameController.text,
        partnerName: _partnerNameController.text,
        relationshipStartDate: _relationshipDateController.text,
        enableNotifications: _enableNotifications,
        themeMode: _selectedThemeMode,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
}