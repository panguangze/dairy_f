import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../utils/database_helper.dart';

class AppProvider with ChangeNotifier {
  List<MoodEntry> _moodEntries = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MoodEntry> get moodEntries => _moodEntries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Settings
  String _coupleName = 'My Love Diary';
  String _partnerName = 'Partner';
  String _relationshipStartDate = '';
  bool _enableNotifications = true;
  ThemeMode _themeMode = ThemeMode.system;

  String get coupleName => _coupleName;
  String get partnerName => _partnerName;
  String get relationshipStartDate => _relationshipStartDate;
  bool get enableNotifications => _enableNotifications;
  ThemeMode get themeMode => _themeMode;

  AppProvider() {
    _loadSettings();
    loadMoodEntries();
  }

  Future<void> _loadSettings() async {
    final dbHelper = DatabaseHelper();
    final settings = await dbHelper.getSettings();
    
    if (settings != null) {
      _coupleName = settings['coupleName'] ?? 'My Love Diary';
      _partnerName = settings['partnerName'] ?? 'Partner';
      _relationshipStartDate = settings['relationshipStartDate'] ?? '';
      _enableNotifications = settings['enableNotifications'] == 1;
      _themeMode = ThemeMode.values[settings['themeMode'] ?? 0];
    }
    
    notifyListeners();
  }

  Future<void> loadMoodEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      final dbHelper = DatabaseHelper();
      _moodEntries = await dbHelper.getAllMoodEntries();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMoodEntry(MoodEntry entry) async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.insertMoodEntry(entry);
      await loadMoodEntries(); // Reload to update UI
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateSettings({
    String? coupleName,
    String? partnerName,
    String? relationshipStartDate,
    bool? enableNotifications,
    ThemeMode? themeMode,
  }) async {
    _coupleName = coupleName ?? _coupleName;
    _partnerName = partnerName ?? _partnerName;
    _relationshipStartDate = relationshipStartDate ?? _relationshipStartDate;
    _enableNotifications = enableNotifications ?? _enableNotifications;
    _themeMode = themeMode ?? _themeMode;

    final dbHelper = DatabaseHelper();
    await dbHelper.updateSettings({
      'coupleName': _coupleName,
      'partnerName': _partnerName,
      'relationshipStartDate': _relationshipStartDate,
      'enableNotifications': _enableNotifications ? 1 : 0,
      'themeMode': _themeMode.index,
    });

    notifyListeners();
  }

  int get daysTogether {
    if (_relationshipStartDate.isEmpty) return 0;
    try {
      final startDate = DateTime.parse(_relationshipStartDate);
      final today = DateTime.now();
      return today.difference(startDate).inDays + 1; // +1 because we count the first day as day 1
    } catch (e) {
      return 0;
    }
  }

  // Get mood statistics
  Map<MoodType, int> getMoodStatistics() {
    final stats = <MoodType, int>{};
    
    for (final moodType in MoodType.values) {
      stats[moodType] = 0;
    }
    
    for (final entry in _moodEntries) {
      stats[entry.mood] = (stats[entry.mood] ?? 0) + 1;
    }
    
    return stats;
  }
}
