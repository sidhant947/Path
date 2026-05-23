import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/step_service.dart';
import '../providers/step_provider.dart';
import 'goal_setup_page.dart';
import 'settings_page.dart';

class TodayPage extends StatefulWidget {
  final StepService repository;
  final ValueChanged<int> onNavTap;
  const TodayPage({
    super.key,
    required this.repository,
    required this.onNavTap,
  });

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  final _numberFormat = NumberFormat("#,##0", "en_US");

  String _formatNumber(int number) {
    return _numberFormat.format(number);
  }

  Map<String, String> getFormattedRemaining(int steps, int goal) {
    final int remaining = goal - steps;
    if (remaining <= 0) {
      return {'label': 'ACHIEVED', 'value': _formatNumber(steps - goal)};
    }
    return {
      'label': 'REMAINING',
      'value': _formatNumber(remaining > 0 ? remaining : 0),
    };
  }

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>();
    final int steps = stepProvider.todaySteps;
    final int goal = stepProvider.goal;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final limeColor = stepProvider.accentColor;

    final double percentage = (steps / goal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              height: MediaQuery.of(context).size.height * percentage,
              width: double.infinity,
              color: limeColor,
            ),
          ),
          RepaintBoundary(
            child: _buildForeground(
              context,
              textColor: textColor,
              steps: steps,
              goal: goal,
              stepProvider: stepProvider,
            ),
          ),
          ClipRect(
            clipper: _BottomFillClipper(percentage),
            child: RepaintBoundary(
              child: _buildForeground(
                context,
                textColor: Colors.black,
                steps: steps,
                goal: goal,
                stepProvider: stepProvider,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForeground(
    BuildContext context, {
    required Color textColor,
    required int steps,
    required int goal,
    required StepProvider stepProvider,
  }) {
    final String formattedGoal = _formatNumber(goal);
    final String formattedSteps = _formatNumber(steps);
    final remainingData = getFormattedRemaining(steps, goal);

    return Column(
      children: [
        Expanded(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 32.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  GoalSetupPage(repository: widget.repository),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GOAL',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              formattedGoal,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                remainingData['label']!,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                remainingData['value']!,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(Icons.settings_rounded, color: textColor),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        formattedSteps,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 88,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2.0,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Daily Steps',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 36),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMetricItem(
                            icon: Icons.straighten_rounded,
                            value: '${stepProvider.todayDistanceKm.toStringAsFixed(2)} km',
                            label: 'DISTANCE',
                            color: textColor,
                          ),
                          _buildMetricItem(
                            icon: Icons.local_fire_department_rounded,
                            value: '${stepProvider.todayCalories.toStringAsFixed(0)} kcal',
                            label: 'CALORIES',
                            color: textColor,
                          ),
                          _buildMetricItem(
                            icon: Icons.timer_rounded,
                            value: '${stepProvider.todayActiveMinutes.toStringAsFixed(0)}m',
                            label: 'ACTIVE',
                            color: textColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
        _buildBottomNav(context, textColor: textColor),
      ],
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color.withValues(alpha: 0.8)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context, {required Color textColor}) {
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
                    color: textColor,
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
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomFillClipper extends CustomClipper<Rect> {
  final double percentage;

  _BottomFillClipper(this.percentage);

  @override
  Rect getClip(Size size) {
    final height = size.height * percentage;
    return Rect.fromLTWH(0, size.height - height, size.width, height);
  }

  @override
  bool shouldReclip(_BottomFillClipper oldClipper) {
    return oldClipper.percentage != percentage;
  }
}
