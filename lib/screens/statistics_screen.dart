import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';
import '../providers/app_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics'),
        centerTitle: true,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          final moodStats = provider.getMoodStatistics();
          final totalEntries = provider.moodEntries.length;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                context,
                                totalEntries.toString(),
                                'Total Entries',
                                Icons.insert_chart,
                              ),
                              _buildStatItem(
                                context,
                                provider.daysTogether.toString(),
                                'Days Together',
                                Icons.favorite,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Mood Distribution
                  Text(
                    'Mood Distribution',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  ...MoodType.values.map((mood) {
                    final count = moodStats[mood] ?? 0;
                    final percentage = totalEntries > 0 
                        ? ((count / totalEntries) * 100).round()
                        : 0;
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(mood.emoji, style: TextStyle(fontSize: 20)),
                                  SizedBox(width: 8),
                                  Text(
                                    mood.label,
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Text(
                                '$count entries ($percentage%)',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: totalEntries > 0 ? count / totalEntries : 0,
                            minHeight: 8,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getColorForMood(mood, context),
                            ),
                            backgroundColor: Theme.of(context).brightness == Brightness.light
                                ? Colors.grey.shade200
                                : Colors.grey.shade800,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  
                  SizedBox(height: 20),
                  
                  // Monthly Overview
                  Text(
                    'Monthly Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  _buildMonthlyChart(provider.moodEntries, context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getColorForMood(MoodType mood, BuildContext context) {
    switch (mood) {
      case MoodType.happy:
        return Colors.green.shade400;
      case MoodType.satisfied:
        return Colors.blue.shade400;
      case MoodType.normal:
        return Colors.grey.shade400;
      case MoodType.sad:
        return Colors.blue.shade800;
      case MoodType.angry:
        return Colors.red.shade600;
      case MoodType.other:
        return Colors.purple.shade400;
    }
  }

  Widget _buildMonthlyChart(List<MoodEntry> entries, BuildContext context) {
    // Group entries by month
    final monthlyData = <String, Map<MoodType, int>>{};
    
    for (final entry in entries) {
      final date = DateTime.parse(entry.date);
      final monthKey = '${date.year}-${date.month}';
      
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {};
        for (final mood in MoodType.values) {
          monthlyData[monthKey]![mood] = 0;
        }
      }
      
      final currentCount = monthlyData[monthKey]![entry.mood] ?? 0;
      monthlyData[monthKey]![entry.mood] = currentCount + 1;
    }
    
    final sortedMonths = monthlyData.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return Column(
      children: sortedMonths.take(6).map((month) {
        final data = monthlyData[month]!;
        final totalForMonth = data.values.fold(0, (a, b) => a + b);
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(
                    DateTime.parse('$month-01')
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: MoodType.values.map((mood) {
                    final count = data[mood] ?? 0;
                    final percentage = totalForMonth > 0 
                        ? ((count / totalForMonth) * 100).round()
                        : 0;
                    
                    return Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _getColorForMood(mood, context).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              mood.emoji,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}