import 'package:flutter/material.dart';
import '../utils/step_service.dart';
import 'stats_page.dart';
import 'today_page.dart';

class MainPage extends StatefulWidget {
  final int goal;
  final StepService repository;

  const MainPage({super.key, required this.goal, required this.repository});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TodayPage(
            goal: widget.goal,
            repository: widget.repository,
            onNavTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          StatsPage(
            repository: widget.repository,
            onNavTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }
}
