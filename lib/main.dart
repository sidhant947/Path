import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/step_service.dart';
import 'pages/goal_setup_page.dart';
import 'pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final repository = StepService(prefs);
  final goal = await repository.getGoal();

  runApp(MyApp(initialGoal: goal, repository: repository));
}

class MyApp extends StatelessWidget {
  final int? initialGoal;
  final StepService repository;

  const MyApp({super.key, this.initialGoal, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        brightness: Brightness.light,
        fontFamily: 'Space Grotesk',
      ),
      darkTheme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        brightness: Brightness.dark,
        fontFamily: 'Space Grotesk',
      ),
      themeMode: ThemeMode.system,
      home: initialGoal == null
          ? GoalSetupPage(repository: repository)
          : MainPage(goal: initialGoal!, repository: repository),
    );
  }
}
