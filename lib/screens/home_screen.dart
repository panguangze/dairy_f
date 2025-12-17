import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/mood_entry.dart';
import '../providers/app_provider.dart';
import '../widgets/diary_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MoodType? selectedMood;
  late final TextEditingController _noteController;
  String? _selectedImagePath;
  String? _customMoodLabel;
  String? _lastSyncedSignature;
  String _moodMessage = '无论今天心情如何，我都在你身边，爱你每一天。';
  final ImagePicker _picker = ImagePicker();
  static const int _maxImageBytes = 5 * 1024 * 1024;

  final Map<MoodType, _MoodStyle> _moodStyles = {
    MoodType.sweet: _MoodStyle(
      baseColor: const Color(0xFFFF69B4),
      activeColor: const Color(0xFFFF1493),
      emoji: '💕',
      label: '甜蜜',
    ),
    MoodType.happy: _MoodStyle(
      baseColor: const Color(0xFFFFFF00),
      activeColor: const Color(0xFFFFD700),
      emoji: '😊',
      label: '开心',
    ),
    MoodType.normal: _MoodStyle(
      baseColor: const Color(0xFFCCCCCC),
      activeColor: const Color(0xFF999999),
      emoji: '😐',
      label: '正常',
    ),
    MoodType.lost: _MoodStyle(
      baseColor: const Color(0xFF1E90FF),
      activeColor: const Color(0xFF0000CD),
      emoji: '😢',
      label: '失落',
    ),
    MoodType.angry: _MoodStyle(
      baseColor: const Color(0xFFFF0000),
      activeColor: const Color(0xFFDC143C),
      emoji: '😡',
      label: '愤怒',
    ),
    MoodType.other: _MoodStyle(
      baseColor: const Color(0xFF00FF00),
      activeColor: const Color(0xFF008000),
      emoji: '🤔',
      label: '其他',
    ),
  };

  String get _todayString => DateTime.now().toIso8601String().split('T')[0];

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
      'image': todayEntry.imageUrl,
      'custom': todayEntry.customMoodLabel,
    });
    if (_lastSyncedSignature == signature) return;
    _lastSyncedSignature = signature;
    _syncEntryState(todayEntry);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  MoodEntry _getTodayEntry(AppProvider appProvider) {
    return appProvider.moodEntries.firstWhere(
      (element) => element.date == _todayString,
      orElse: () => MoodEntry(
        date: _todayString,
        mood: MoodType.normal,
      ),
    );
  }

  void _syncEntryState(MoodEntry todayEntry) {
    setState(() {
      selectedMood = todayEntry.id != null ? todayEntry.mood : null;
      _noteController.text = todayEntry.note ?? '';
      _selectedImagePath = todayEntry.imageUrl;
      _customMoodLabel = todayEntry.customMoodLabel;
    });
  }

  Future<void> _onMoodTap(MoodType mood) async {
    if (mood == MoodType.other) {
      final label = await _promptCustomMood();
      if (label == null) return;
      setState(() {
        selectedMood = mood;
        _customMoodLabel = label;
      });
      return;
    }

    setState(() {
      selectedMood = mood;
      _customMoodLabel = null;
    });
  }

  Future<String?> _promptCustomMood() async {
    final controller = TextEditingController(text: _customMoodLabel ?? '其他');
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('自定义心情'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '输入你的心情',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final length = await file.length();

    if (length > _maxImageBytes) {
      _showToast('请选择小于5MB的图片');
      return;
    }

    setState(() {
      _selectedImagePath = picked.path;
    });
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
  }

  Future<void> _saveEntry(AppProvider provider) async {
    final note = _noteController.text.trim();

    if (selectedMood == null) {
      _showToast('请选择心情');
      return;
    }

    if (note.isEmpty) {
      _showToast('请输入内容');
      return;
    }

    final todayEntry = _getTodayEntry(provider);

    await provider.addMoodEntry(
      MoodEntry(
        id: todayEntry.id,
        date: _todayString,
        mood: selectedMood!,
        note: note,
        imageUrl: _selectedImagePath,
        customMoodLabel: selectedMood == MoodType.other
            ? (_customMoodLabel?.trim().isNotEmpty == true
                ? _customMoodLabel!.trim()
                : '其他')
            : null,
      ),
    );

    _showToast('今日心情已保存');
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  int _calculateStreak(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;
    final dates = entries
        .map((e) => DateTime.parse(e.date))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    var streak = 1;
    for (var i = 1; i < dates.length; i++) {
      final difference = dates[i - 1].difference(dates[i]).inDays;
      if (difference == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  MoodType? _mostFrequentMood(List<MoodEntry> entries) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final filtered = entries
        .where((e) => DateTime.parse(e.date).isAfter(cutoff))
        .toList();
    if (filtered.isEmpty) return null;

    final counter = <MoodType, int>{};
    for (final mood in MoodType.values) {
      counter[mood] = 0;
    }
    for (final entry in filtered) {
      counter[entry.mood] = (counter[entry.mood] ?? 0) + 1;
    }

    counter.removeWhere((key, value) => value == 0);
    if (counter.isEmpty) return null;

    counter.entries.toList().sort((a, b) => b.value.compareTo(a.value));
    return counter.entries.first.key;
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final scale =
        (MediaQuery.of(context).size.width / 810).clamp(0.7, 1.2).toDouble();
    final titleText =
        '${appProvider.coupleName} & ${appProvider.partnerName}的第${appProvider.daysTogether}天';
    final subtitleText =
        'From ${appProvider.relationshipStartDate.isNotEmpty ? appProvider.relationshipStartDate : '----'} to ${DateFormat('yyyy-MM-dd').format(DateTime.now())}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 200 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopSection(scale, titleText, subtitleText),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20 * scale),
                      _buildMoodSelection(scale),
                      SizedBox(height: 20 * scale),
                      _buildNoteAndSave(scale, appProvider),
                      SizedBox(height: 20 * scale),
                      _buildImageUpload(scale),
                      SizedBox(height: 32 * scale),
                      _buildHistorySection(scale, appProvider),
                      SizedBox(height: 24 * scale),
                      _buildStatsSection(scale, appProvider),
                      SizedBox(height: 24 * scale),
                      _buildMoodMessage(scale),
                      SizedBox(height: 32 * scale),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DiaryBottomNavigation(currentIndex: 0),
        ],
      ),
    );
  }

  Widget _buildTopSection(double scale, String title, String subtitle) {
    return Container(
      width: double.infinity,
      height: 225 * scale,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 40 * scale, vertical: 40 * scale),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 20 * scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFFFF69B4),
                    fontSize: 36 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 10 * scale),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 18 * scale,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60 * scale,
                  height: 20 * scale,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF999999).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'AI生成',
                    style: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: 12 * scale,
                    ),
                  ),
                ),
                SizedBox(height: 8 * scale),
                Container(
                  width: 60 * scale,
                  height: 60 * scale,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEEEEE),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelection(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今天感觉如何？',
          style: TextStyle(
            fontSize: 20 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16 * scale),
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 20 * scale,
          mainAxisSpacing: 20 * scale,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          children: MoodType.values.map((mood) {
            final style = _moodStyles[mood]!;
            final isSelected = selectedMood == mood;
            final label = mood == MoodType.other && _customMoodLabel != null
                ? _customMoodLabel!
                : style.label;
            return GestureDetector(
              onTap: () => _onMoodTap(mood),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60 * scale,
                    height: 60 * scale,
                    decoration: BoxDecoration(
                      color: isSelected ? style.activeColor : style.baseColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: style.activeColor.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        style.emoji,
                        style: TextStyle(fontSize: 24 * scale),
                      ),
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16 * scale,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoteAndSave(double scale, AppProvider provider) {
    final canSave =
        selectedMood != null && _noteController.text.trim().isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '记录下你的心情',
              hintStyle: const TextStyle(color: Color(0xFF999999)),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        SizedBox(width: 12 * scale),
        SizedBox(
          width: 100 * scale,
          height: 56 * scale,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canSave ? const Color(0xFFFF69B4) : const Color(0xFFCCCCCC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: canSave ? () => _saveEntry(provider) : null,
            child: const Text('保存'),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUpload(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择图片',
          style: TextStyle(
            fontSize: 20 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12 * scale),
        _selectedImagePath == null
            ? GestureDetector(
                onTap: _pickImage,
                child: CustomPaint(
                  painter: _DashedBorderPainter(color: const Color(0xFFCCCCCC)),
                  child: Container(
                    width: double.infinity,
                    height: 250 * scale,
                    color: const Color(0xFFEEEEEE),
                    alignment: Alignment.center,
                    child: Text(
                      '点击上传图片',
                      style: TextStyle(
                        fontSize: 18 * scale,
                        color: const Color(0xFF999999),
                      ),
                    ),
                  ),
                ),
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_selectedImagePath!),
                      width: double.infinity,
                      height: 250 * scale,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 12 * scale,
                    bottom: 12 * scale,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        width: 30 * scale,
                        height: 30 * scale,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildHistorySection(double scale, AppProvider provider) {
    final entries = provider.moodEntries.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final displayEntries = entries.take(36).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最近心情',
              style: TextStyle(
                fontSize: 20 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/history'),
              child: Text(
                '更多 >',
                style: TextStyle(
                  fontSize: 16 * scale,
                  color: const Color(0xFF999999),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16 * scale),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
            mainAxisSpacing: 20 * scale,
            crossAxisSpacing: 20 * scale,
          ),
          itemCount: displayEntries.length,
          itemBuilder: (context, index) {
            final entry = displayEntries[index];
            final style = _moodStyles[entry.mood]!;
            return GestureDetector(
              onTap: () => _showEntryDetail(entry),
              child: Container(
                width: 50 * scale,
                height: 50 * scale,
                decoration: BoxDecoration(
                  color: style.baseColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: style.activeColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    style.emoji,
                    style: TextStyle(fontSize: 18 * scale),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showEntryDetail(MoodEntry entry) {
    final style = _moodStyles[entry.mood]!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            DateFormat('yyyy-MM-dd').format(DateTime.parse(entry.date)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: style.baseColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(style.emoji)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.customMoodLabel ?? entry.mood.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (entry.note != null)
                Text(
                  entry.note!,
                  style: const TextStyle(color: Colors.black87),
                ),
              if (entry.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(entry.imageUrl!),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsSection(double scale, AppProvider provider) {
    final total = provider.moodEntries.length;
    final streak = _calculateStreak(provider.moodEntries);
    final frequentMood = _mostFrequentMood(provider.moodEntries);
    final frequentStyle =
        frequentMood != null ? _moodStyles[frequentMood]! : null;

    Widget buildStat(String title, String value, {String unit = ''}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16 * scale,
              color: const Color(0xFF999999),
            ),
          ),
          SizedBox(height: 6 * scale),
          Text(
            value,
            style: TextStyle(
              fontSize: 48 * scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFF69B4),
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style: TextStyle(
                fontSize: 16 * scale,
                color: const Color(0xFF999999),
              ),
            ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: buildStat('已经记录', total.toString(), unit: '天')),
          Expanded(child: buildStat('连续记录', streak.toString(), unit: '天')),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最近30天常见心情',
                  style: TextStyle(
                    fontSize: 16 * scale,
                    color: const Color(0xFF999999),
                  ),
                ),
                SizedBox(height: 8 * scale),
                Container(
                  width: 60 * scale,
                  height: 60 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF69B4).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: frequentStyle != null
                        ? Text(
                            frequentStyle.emoji,
                            style: TextStyle(fontSize: 24 * scale),
                          )
                        : const Icon(
                            Icons.favorite,
                            color: Color(0xFFFF69B4),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodMessage(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '心情寄语',
          style: TextStyle(
            fontSize: 20 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 10 * scale),
        GestureDetector(
          onTap: () async {
            final controller = TextEditingController(text: _moodMessage);
            final result = await showDialog<String>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('编辑寄语'),
                  content: TextField(
                    controller: controller,
                    maxLines: 2,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, controller.text.trim()),
                      child: const Text('保存'),
                    ),
                  ],
                );
              },
            );
            if (result != null && result.isNotEmpty) {
              setState(() {
                _moodMessage = result;
              });
            }
            controller.dispose();
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(12 * scale),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Text(
              _moodMessage,
              style: TextStyle(
                fontSize: 18 * scale,
                color: const Color(0xFF999999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoodStyle {
  const _MoodStyle({
    required this.baseColor,
    required this.activeColor,
    required this.emoji,
    required this.label,
  });

  final Color baseColor;
  final Color activeColor;
  final String emoji;
  final String label;
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 6.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final length = distance + dashWidth < metric.length
            ? dashWidth
            : metric.length - distance;
        dashedPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
