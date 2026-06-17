import 'dart:convert';
import 'package:flutter/material.dart';
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
    final accentColor = context.select<StepProvider, Color>((p) => p.accentColor);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      _buildStreakSection(accentColor),
                      const SizedBox(height: 24),
                      _buildEncouragementSection(isDark, accentColor),
                      const SizedBox(height: 16),
                      _buildActivityChartSection(isDark, accentColor),
                      const SizedBox(height: 24),
                      _buildBreakdownSection(isDark, accentColor),
                      const SizedBox(height: 24),
                      _buildHourlySection(isDark, accentColor),
                      const SizedBox(height: 24),
                      Consumer<StepProvider>(
                        builder: (context, provider, _) => _buildAchievementsSection(provider, isDark, accentColor),
                      ),
                      const SizedBox(height: 24),
                      _buildHistoryList(accentColor),

                      const SizedBox(height: 80),
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

  Widget _buildStreakSection(Color accentColor) {
    return Selector<StepProvider, int>(
      selector: (_, p) => p.streak,
      builder: (context, streak, _) => _buildStreakBar(streak, accentColor),
    );
  }

  Widget _buildEncouragementSection(bool isDark, Color accentColor) {
    return Selector<StepProvider, (int, int)>(
      selector: (_, p) => (p.todaySteps, p.goal),
      builder: (context, data, _) => _buildEncouragementMessage(data.$1, data.$2, isDark, accentColor),
    );
  }

  Widget _buildActivityChartSection(bool isDark, Color accentColor) {
    return Selector<StepProvider, (int, int, List<DailyStepRecord>)>(
      selector: (_, p) => (p.todaySteps, p.goal, p.history),
      builder: (context, data, _) {
        final todayRecord = DailyStepRecord(date: DateTime.now(), steps: data.$1);
        final allRecords = [todayRecord, ...data.$3];
        final displayRecords = allRecords.take(7).toList();
        final chartRecords = displayRecords.reversed.toList();
        return _buildBarChart(chartRecords, data.$2, isDark, accentColor);
      },
    );
  }

  Widget _buildBreakdownSection(bool isDark, Color accentColor) {
    return Consumer<StepProvider>(
      builder: (context, provider, _) => _buildWalkRunBreakdown(provider, isDark, accentColor),
    );
  }

  Widget _buildHourlySection(bool isDark, Color accentColor) {
    return Selector<StepProvider, String>(
      selector: (_, p) => p.hourlyStepsString,
      builder: (context, hourlyString, _) => _buildHourlyChart(hourlyString, isDark, accentColor),
    );
  }

  Widget _buildHistoryList(Color accentColor) {
    return Selector<StepProvider, (int, List<DailyStepRecord>)>(
      selector: (_, p) => (p.todaySteps, p.history),
      builder: (context, data, _) {
        final todayRecord = DailyStepRecord(date: DateTime.now(), steps: data.$1);
        final displayRecords = [todayRecord, ...data.$2].take(7).toList();
        return Column(
          children: displayRecords.map((item) => _buildListItem(item, context, accentColor)).toList(),
        );
      },
    );
  }

  Widget _buildStreakBar(int streak, Color accentColor) {
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
                      ? accentColor
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

  Widget _buildEncouragementMessage(int steps, int goal, bool isDark, Color accentColor) {
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
          Icon(Icons.directions_walk, color: accentColor),
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

  Widget _buildBarChart(List<DailyStepRecord> records, int goal, bool isDark, Color accentColor) {
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
                                    ? accentColor
                                    : accentColor.withValues(
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
                      color: accentColor.withValues(alpha: 0.3),
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

  Widget _buildWalkRunBreakdown(StepProvider provider, bool isDark, Color accentColor) {
    final walk = provider.walkingSteps;
    final run = provider.runningSteps;
    final total = walk + run;
    final double walkPercent = total > 0 ? (walk / total) : 1.0;
    final double runPercent = total > 0 ? (run / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TODAY BREAKDOWN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                if (walkPercent > 0)
                  Expanded(
                    flex: (walkPercent * 100).toInt().clamp(1, 100),
                    child: Container(
                      height: 8,
                      color: accentColor,
                    ),
                  ),
                if (runPercent > 0)
                  Expanded(
                    flex: (runPercent * 100).toInt().clamp(1, 100),
                    child: Container(
                      height: 8,
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_walk_rounded, color: accentColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Walk: ${_numberFormat.format(walk)} (${(walkPercent * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.directions_run_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Run: ${_numberFormat.format(run)} (${(runPercent * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChart(String hourlyStepsString, bool isDark, Color accentColor) {
    Map<String, dynamic> hourlyMap = {};
    try {
      hourlyMap = jsonDecode(hourlyStepsString);
    } catch (_) {}

    int night = 0;
    int morning = 0;
    int afternoon = 0;
    int evening = 0;

    hourlyMap.forEach((key, val) {
      final hour = int.tryParse(key) ?? 0;
      final steps = val as int? ?? 0;
      if (hour >= 0 && hour < 6) {
        night += steps;
      } else if (hour >= 6 && hour < 12) {
        morning += steps;
      } else if (hour >= 12 && hour < 18) {
        afternoon += steps;
      } else {
        evening += steps;
      }
    });

    final maxSteps = [night, morning, afternoon, evening].reduce((a, b) => a > b ? a : b);

    double getBarHeight(int steps) {
      if (maxSteps == 0) return 10.0;
      return (steps / maxSteps * 100.0).clamp(10.0, 100.0);
    }

    Widget buildBar(String label, int steps, IconData icon) {
      return Expanded(
        child: Column(
          children: [
            Text(
              _numberFormat.format(steps),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              height: 100,
              width: 14,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(7),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: getBarHeight(steps),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOURLY DISTRIBUTION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              buildBar('NIGHT', night, Icons.nights_stay_rounded),
              buildBar('MORNING', morning, Icons.wb_sunny_rounded),
              buildBar('AFTERNOON', afternoon, Icons.wb_twilight_rounded),
              buildBar('EVENING', evening, Icons.dark_mode_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(StepProvider provider, bool isDark, Color accentColor) {
    final pbSteps = provider.pbSteps;
    final pbStepsDate = provider.pbStepsDate;
    final pbStreak = provider.pbStreak;
    final lifetime = provider.lifetimeSteps;

    Widget buildAchCard(String label, String value, String sub, IconData icon, Color col) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[950] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.grey[850]! : Colors.grey[200]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: col, size: 24),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: TextStyle(fontSize: 8, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERSONAL RECORDS & BADGES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              buildAchCard(
                'ALL-TIME BEST',
                _numberFormat.format(pbSteps),
                pbStepsDate,
                Icons.emoji_events_rounded,
                Colors.amber,
              ),
              const SizedBox(width: 8),
              buildAchCard(
                'BEST STREAK',
                '$pbStreak DAYS',
                'Active Days',
                Icons.local_fire_department_rounded,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              buildAchCard(
                'LIFETIME STEPS',
                _numberFormat.format(lifetime),
                '',
                Icons.stacked_line_chart_rounded,
                accentColor,
              ),
              const SizedBox(width: 8),
              buildAchCard(
                'TOTAL DISTANCE',
                '${provider.getDistanceKmForSteps(lifetime).toStringAsFixed(1)} km',
                '',
                Icons.map_rounded,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(DailyStepRecord record, BuildContext context, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = Colors.grey;

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
              color: accentColor,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
