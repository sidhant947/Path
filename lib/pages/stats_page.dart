import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
                        child: _buildChart(chartRecords, goal),
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

  Widget _buildChart(List<DailyStepRecord> records, int goal) {
    if (records.isEmpty) return const SizedBox.shrink();

    final maxStepsInRecords = records
        .map((e) => e.steps)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final double chartMaxY =
        (maxStepsInRecords > goal ? maxStepsInRecords : goal.toDouble()) * 1.5;

    final spots = records.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.steps.toDouble());
    }).toList();

    return Container(
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: const Color(0xFFC7F900),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.only(top: 48, bottom: 16, left: 16, right: 16),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: chartMaxY,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: goal.toDouble(),
                color: Colors.black.withValues(alpha: 0.4),
                strokeWidth: 2,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                  alignment: Alignment.topRight,
                  labelResolver: (line) => 'Goal',
                ),
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: Colors.black,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.black.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    _numberFormat.format(spot.y.toInt()),
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
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
