class MoodEntry {
  final int? id;
  final String date;
  final MoodType mood;
  final String? note;
  final String? imageUrl;

  MoodEntry({
    this.id,
    required this.date,
    required this.mood,
    this.note,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'mood': mood.index,
      'note': note,
      'imageUrl': imageUrl,
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'],
      date: map['date'] ?? '',
      mood: MoodType.values[map['mood']],
      note: map['note'],
      imageUrl: map['imageUrl'],
    );
  }

  @override
  String toString() {
    return 'MoodEntry(id: $id, date: $date, mood: $mood, note: $note, imageUrl: $imageUrl)';
  }
}

enum MoodType {
  happy('Happy', '😊'),
  satisfied('Satisfied', '🙂'),
  normal('Normal', '😐'),
  sad('Sad', '😢'),
  angry('Angry', '😠'),
  other('Other', '🤔');

  const MoodType(this.label, this.emoji);
  
  final String label;
  final String emoji;
}