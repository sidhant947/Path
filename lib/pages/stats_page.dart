import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

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
                      _buildBarChart(chartRecords, goal),
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

  Widget _buildBarChart(List<DailyStepRecord> records, int goal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (records.isEmpty) {
      return _buildEmptyChartPlaceholder(isDark);
    }

    double maxY = goal.toDouble();
    for (var record in records) {
      if (record.steps > maxY) maxY = record.steps.toDouble();
    }
    // Add 20% headroom
    maxY = maxY * 1.2;

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVITY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Goal: ${_numberFormat.format(goal)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor:
                        (group) => isDark ? Colors.grey[800]! : Colors.white,
                    tooltipBorder:
                        isDark ? null : BorderSide(color: Colors.grey[300]!),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        _numberFormat.format(rod.toY.toInt()),
                        TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= records.length) {
                          return const SizedBox();
                        }
                        final date = records[index].date;
                        final isToday =
                            DateFormat('yyyy-MM-dd').format(date) ==
                            DateFormat('yyyy-MM-dd').format(DateTime.now());

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            isToday ? 'T' : DateFormat('E').format(date)[0],
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups:
                    records.asMap().entries.map((entry) {
                      final index = entry.key;
                      final record = entry.value;
                      final isToday =
                          DateFormat('yyyy-MM-dd').format(record.date) ==
                          DateFormat('yyyy-MM-dd').format(DateTime.now());

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: record.steps.toDouble(),
                            color:
                                isToday
                                    ? const Color(0xFFC7F900)
                                    : const Color(0xFFC7F900).withValues(
                                      alpha: 0.4,
                                    ),
                            width: 22,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY,
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                        ],
                        showingTooltipIndicators: [],
                      );
                    }).toList(),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: goal.toDouble(),
                      color: const Color(0xFFC7F900).withValues(alpha: 0.3),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
