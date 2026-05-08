import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../utils/date_formatter.dart';
import '../utils/step_service.dart';
import '../providers/step_provider.dart';

class StatsPage extends StatefulWidget {
  final StepService repository;
  final ValueChanged<int> onNavTap;

  const StatsPage({
    super.key,
    required this.repository,
    required this.onNavTap,
  });

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _numberFormat = NumberFormat("#,##0", "en_US");

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>();
    final todaySteps = stepProvider.todaySteps;
    final history = stepProvider.history;
    final goal = stepProvider.goal;
    final streak = stepProvider.streak;

    // Combine today with history for display
    final todayRecord = DailyStepRecord(
      date: DateTime.now(),
      steps: todaySteps,
    );
    final allRecords = [todayRecord, ...history];

    // Sort and take last 7 days including today
    final displayRecords = allRecords.take(7).toList();
    final chartRecords = displayRecords.reversed.toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      _buildStreakBar(streak),
                      const SizedBox(height: 24),
                      if (todaySteps > 0)
                        _buildEncouragementMessage(todaySteps, goal, isDark),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: _buildProgressRings(chartRecords, goal),
                      ),
                      const SizedBox(height: 24),
                      ...displayRecords.map(
                        (item) => _buildListItem(item, context),
                      ),
                      const SizedBox(height: 80), // Space for nav
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildBottomNav(context),
        ],
      ),
    );
  }

  Widget _buildStreakBar(int streak) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STREAK',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (index) {
            final active = index < streak;
            return Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFC7F900)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          '$streak DAY STREAK',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEncouragementMessage(int steps, int goal, bool isDark) {
    String message = "Go for a walk! You can do it.";
    if (steps >= goal) {
      message = "Amazing work! Goal smashed.";
    } else if (steps >= goal * 0.7) {
      message = "Almost there! Keep pushing.";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_walk, color: Color(0xFFC7F900)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onNavTap(0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 12.0,
                ),
                child: Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onNavTap(1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 12.0,
                ),
                child: Text(
                  'Stats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRings(List<DailyStepRecord> records, int goal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (records.isEmpty) {
      return _buildEmptyChartPlaceholder(isDark);
    }

    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: CustomPaint(
              size: Size.infinite,
              painter: _ConcentricRingsPainter(
                records: records,
                goal: goal.toDouble(),
                isDark: isDark,
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Today', const Color(0xFFC7F900), isDark),
                const SizedBox(width: 16),
                _buildLegendItem(
                  'Past 7 Days',
                  const Color(0xFFC7F900).withValues(alpha: 0.4),
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.black54,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChartPlaceholder(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_walk,
            size: 48,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            'Start walking to see your stats!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(DailyStepRecord record, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = Colors.grey;
    final accentTextColor = const Color(0xFF32CD32);

    final isToday =
        DateFormat('yyyy-MM-dd').format(record.date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday ? 'TODAY' : DateFormatter.formatDayOfWeek(record.date),
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormatter.formatFullDate(record.date),
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            _numberFormat.format(record.steps),
            style: TextStyle(
              color: accentTextColor,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConcentricRingsPainter extends CustomPainter {
  final List<DailyStepRecord> records;
  final double goal;
  final bool isDark;

  _ConcentricRingsPainter({
    required this.records,
    required this.goal,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (size.width < size.height ? size.width : size.height) / 2;

    final ringWidth = maxRadius / (records.length + 1.5);
    final spacing = 4.0;

    for (int i = 0; i < records.length; i++) {
      final record =
          records[records.length - 1 - i]; // Outer to inner (Today to past)
      final progress = (record.steps / goal).clamp(
        0.0,
        1.5,
      ); // Allow slight overflow visual

      final radius = maxRadius - (i * (ringWidth + spacing));

      // Color: Outer is bright lime, inner rings are progressively more transparent/darker
      final opacity = 1.0 - (i * 0.12);
      final color = const Color(0xFFC7F900).withValues(
        alpha: opacity.clamp(0.2, 1.0),
      );

      final backgroundPaint = Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round;

      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round;

      // Draw background track
      canvas.drawCircle(center, radius, backgroundPaint);

      // Draw progress arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2, // Start from top
        progress * 2 * 3.14159,
        false,
        progressPaint,
      );

      // Add a small day label if it's the outermost or every few rings
      if (i == 0 || i == records.length - 1) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: i == 0 ? 'T' : '7d',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            center.dx - textPainter.width / 2,
            center.dy - radius - textPainter.height / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConcentricRingsPainter oldDelegate) =>
      !listEquals(oldDelegate.records, records) || oldDelegate.goal != goal;
}
