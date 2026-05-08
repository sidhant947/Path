import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/step_provider.dart';
import '../utils/step_service.dart';
import 'stats_page.dart';
import 'today_page.dart';

class MainPage extends StatefulWidget {
  final StepService repository;

  const MainPage({super.key, required this.repository});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await widget.repository.prefs.reload();
      if (mounted) {
        context.read<StepProvider>().refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TodayPage(
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
