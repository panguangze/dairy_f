class MoodEntry {
  final int? id;
  final String date;
  final MoodType mood;
  final String? note;
  final String? imageUrl;
  final String? customMoodLabel;

  MoodEntry({
    this.id,
    required this.date,
    required this.mood,
    this.note,
    this.imageUrl,
    this.customMoodLabel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'mood': mood.index,
      'note': note,
      'imageUrl': imageUrl,
      'customMoodLabel': customMoodLabel,
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'],
      date: map['date'] ?? '',
      mood: MoodType.values[map['mood']],
      note: map['note'],
      imageUrl: map['imageUrl'],
      customMoodLabel: map['customMoodLabel'],
    );
  }

  @override
  String toString() {
    return 'MoodEntry(id: $id, date: $date, mood: $mood, note: $note, imageUrl: $imageUrl, customMoodLabel: $customMoodLabel)';
  }
}

enum MoodType {
  sweet('甜蜜', '💕'),
  happy('开心', '😊'),
  normal('正常', '😐'),
  lost('失落', '😢'),
  angry('愤怒', '😠'),
  other('其他', '🤔');

  const MoodType(this.label, this.emoji);
  
  final String label;
  final String emoji;
}
