import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';
import '../providers/app_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();
  MoodType? selectedMood;
  late final TextEditingController _noteController;
  Timer? _noteDebounce;
  String? _lastSyncedSignature;
  static const Duration _noteDebounceDuration = Duration(milliseconds: 300);
  String get _selectedDateString => selectedDate.toIso8601String().split('T')[0];

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appProvider = Provider.of<AppProvider>(context);
    final todayEntry = _getTodayEntry(appProvider);
    final signature = jsonEncode({
      'id': todayEntry.id,
      'mood': todayEntry.mood.index,
      'note': todayEntry.note,
    });
    if (_lastSyncedSignature == signature) return;
    _lastSyncedSignature = signature;
    if (_needsSync(todayEntry)) {
      _syncEntryState(todayEntry);
    }
  }

  bool _needsSync(MoodEntry todayEntry) {
    final entryNote = todayEntry.note ?? '';
    return _shouldUpdateMood(todayEntry) || _noteController.text != entryNote;
  }

  @override
  void dispose() {
    _noteDebounce?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  MoodEntry _getTodayEntry(AppProvider appProvider) {
    return appProvider.moodEntries.firstWhere(
      (element) => element.date == _selectedDateString,
      orElse: () => MoodEntry(
        date: _selectedDateString,
        mood: MoodType.normal,
      ),
    );
  }

  bool _shouldUpdateMood(MoodEntry todayEntry) {
    return (todayEntry.id != null && selectedMood != todayEntry.mood) ||
        (todayEntry.id == null && selectedMood != null);
  }

  void _syncEntryState(MoodEntry todayEntry) {
    final entryNote = todayEntry.note ?? '';

    if (_shouldUpdateMood(todayEntry)) {
      setState(() {
        selectedMood = todayEntry.id != null ? todayEntry.mood : null;
      });
    }

    if (_noteController.text != entryNote) {
      _noteController.text = entryNote;
    }
  }

  MoodEntry _buildMoodEntry(MoodType mood, {int? id, String? note}) {
    final trimmedNote = note?.trim() ?? '';
    return MoodEntry(
      id: id,
      date: _selectedDateString,
      mood: mood,
      note: trimmedNote.isNotEmpty ? trimmedNote : null,
    );
  }

  void _scheduleNoteUpdate(String value, MoodEntry todayEntry, AppProvider appProvider) {
    _noteDebounce?.cancel();
    _noteDebounce = Timer(_noteDebounceDuration, () {
      if (selectedMood != null) {
        final currentEntry = _getTodayEntry(appProvider);
        appProvider.addMoodEntry(
          _buildMoodEntry(
            selectedMood!,
            id: currentEntry.id,
            note: value,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final todayEntry = _getTodayEntry(appProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Love Diary'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              context.go('/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Days Together Card
              Card(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Days Together',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${appProvider.daysTogether}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'with ${appProvider.partnerName}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // Today's Date
              Text(
                'Today - ${DateFormat('EEEE, MMMM dd, yyyy').format(selectedDate)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              
              SizedBox(height: 20),
              
              // Mood Selection
              Text(
                'How are you feeling today?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              
              SizedBox(height: 16),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: MoodType.values.map((mood) {
                  final isSelected = selectedMood == mood;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedMood = mood;
                      });
                      
                      appProvider.addMoodEntry(
                        _buildMoodEntry(
                          mood,
                          note: _noteController.text,
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).brightness == Brightness.light
                                ? Colors.grey.shade200
                                : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary 
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(mood.emoji, style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(
                            mood.label,
                            style: TextStyle(
                              color: isSelected 
                                  ? Colors.white 
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              SizedBox(height: 20),
              
              // Note Input
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Add a note (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'How was your day together?',
                ),
                maxLines: 3,
                onChanged: (value) {
                  _scheduleNoteUpdate(value, todayEntry, appProvider);
                },
              ),
              
              SizedBox(height: 20),
              
              // Recent Entries
              Text(
                'Recent Entries',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              
              SizedBox(height: 12),
              
              ...appProvider.moodEntries.take(5).map((entry) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      child: Text(
                        entry.mood.emoji,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    title: Text(
                      DateFormat('MMM dd, yyyy').format(DateTime.parse(entry.date)),
                    ),
                    subtitle: entry.note != null ? Text(entry.note!) : null,
                    trailing: Text(
                      entry.mood.label,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
