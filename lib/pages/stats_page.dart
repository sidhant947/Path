import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
                        height: 250,
                        child: _buildWaveChart(chartRecords, goal),
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

  Widget _buildWaveChart(List<DailyStepRecord> records, int goal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Empty state: no history at all (just today with 0 steps)
    if (records.isEmpty) {
      return _buildEmptyChartPlaceholder(isDark);
    }

    // Single data point (first day, no history yet)
    if (records.length == 1) {
      final todayRecord = records.first;
      if (todayRecord.steps == 0) {
        return _buildEmptyChartPlaceholder(isDark);
      }
    }

    // Find max steps to determine Y axis scale
    double maxSteps = 0;
    for (final record in records) {
      if (record.steps.toDouble() > maxSteps) {
        maxSteps = record.steps.toDouble();
      }
    }
    // Add 20% headroom so the highest point isn't at the very top
    maxSteps = maxSteps * 1.2;
    if (maxSteps == 0) maxSteps = 10000;

    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFC7F900),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: CustomPaint(
          size: Size.infinite,
          painter: _GoalWaveChartPainter(
            records: records,
            goal: goal.toDouble(),
            maxSteps: maxSteps,
          ),
        ),
      ),
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

/// Smooth wave chart painter with goal line matching the reference design
class _GoalWaveChartPainter extends CustomPainter {
  final List<DailyStepRecord> records;
  final double goal;
  final double maxSteps;

  _GoalWaveChartPainter({
    required this.records,
    required this.goal,
    required this.maxSteps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    final padding = 16.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    // Helper: convert steps to Y position (inverted because canvas Y goes down)
    double stepsToY(double steps) {
      return padding + chartHeight - (steps / maxSteps) * chartHeight;
    }

    // Helper: convert index to X position
    double indexToX(int index) {
      if (records.length == 1) return padding + chartWidth / 2;
      return padding + (index / (records.length - 1)) * chartWidth;
    }

    // Calculate control points for smooth Catmull-Rom spline
    final points = <Offset>[];
    for (int i = 0; i < records.length; i++) {
      final x = indexToX(i);
      final y = stepsToY(records[i].steps.toDouble());
      points.add(Offset(x, y));
    }

    // Build smooth path using cubic bezier curves
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    if (points.length > 1) {
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = i > 0 ? points[i - 1] : points[i];
        final p1 = points[i];
        final p2 = points[i + 1];
        final p3 = i < points.length - 2 ? points[i + 2] : p2;

        // Catmull-Rom to cubic bezier conversion
        final tension = 0.3;
        final cp1x = p1.dx + (p2.dx - p0.dx) * tension;
        final cp1y = p1.dy + (p2.dy - p0.dy) * tension;
        final cp2x = p2.dx - (p3.dx - p1.dx) * tension;
        final cp2y = p2.dy - (p3.dy - p1.dy) * tension;

        path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      }
    }

    // Draw area fill (darker shade below curve)
    final areaPath = Path.from(path);
    areaPath.lineTo(points.last.dx, padding + chartHeight);
    areaPath.lineTo(points.first.dx, padding + chartHeight);
    areaPath.close();

    final areaPaint = Paint()
      ..color = const Color(0xFFB0E000)
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, areaPaint);

    // Draw the wave line (thick black)
    final linePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw black dots at each data point
    final dotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawCircle(point, 5.0, dotPaint);
    }

    // Draw dashed goal line
    final goalY = stepsToY(goal);
    if (goalY >= padding && goalY <= padding + chartHeight) {
      final dashedLinePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      const dashWidth = 8.0;
      const dashGap = 6.0;
      double startX = padding;
      while (startX < padding + chartWidth) {
        final endX = startX + dashWidth;
        if (endX <= padding + chartWidth) {
          canvas.drawLine(
            Offset(startX, goalY),
            Offset(endX, goalY),
            dashedLinePaint,
          );
        }
        startX += dashWidth + dashGap;
      }

      // Draw "Goal" label
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Goal',
          style: TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      final labelX = padding + chartWidth - textPainter.width - 4;
      final labelY = goalY - textPainter.height - 6;
      textPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(covariant _GoalWaveChartPainter oldDelegate) =>
      oldDelegate.records != records ||
      oldDelegate.goal != goal ||
      oldDelegate.maxSteps != maxSteps;
}
