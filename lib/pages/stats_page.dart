import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../utils/date_formatter.dart';
import '../utils/step_service.dart';

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
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        widget.repository.getHistoricalSteps(30),
        widget.repository.getGoal(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data![0] as List<DailyStepRecord>;
        final goal = snapshot.data![1] as int? ?? 10000;

        // Assuming records are sorted descending by date for the list
        // and we want the first 7 items for the graph
        final latestRecords = records.take(7).toList().reversed.toList();

        return Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 250,
                        // Simple fl_chart based on the image
                        child: _buildChart(latestRecords, goal),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final item = records[index];
                          return _buildListItem(item, context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomNav(context),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context) {
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.black54,
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
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

    final maxSteps = records
        .map((e) => e.steps)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final double chartMaxY =
        (maxSteps > goal ? maxSteps : goal.toDouble()) * 1.5;

    final spots = records.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.steps.toDouble());
    }).toList();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(
          0xFFC7F900,
        ).withValues(alpha: 0.8), // Lime green background
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.only(top: 48, bottom: 0, left: 0, right: 0),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: chartMaxY, // leave space at the top for labels
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
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.black.withValues(
                  alpha: 0.2,
                ), // Dark lower gradient approximation
              ),
            ),
          ],
          clipData: const FlClipData.all(),
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }

  Widget _buildListItem(DailyStepRecord record, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = Colors.grey;
    final accentTextColor = const Color(
      0xFF32CD32,
    ); // Slightly darker green text for better visibility

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormatter.formatDayOfWeek(record.date),
                style: TextStyle(color: secondaryTextColor, fontSize: 14),
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
