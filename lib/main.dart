import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'utils/step_service.dart';
import 'utils/background_service.dart';
import 'pages/goal_setup_page.dart';
import 'pages/main_page.dart';
import 'pages/welcome_page.dart';
import 'providers/step_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service
  await initializeService();

  final prefs = await SharedPreferences.getInstance();

  final repository = StepService(prefs);
  final goal = await repository.getGoal();
  final hasCompletedOnboarding = prefs.getBool('onboarding_complete') ?? false;

  final stepProvider = StepProvider(repository);

  runApp(
    ChangeNotifierProvider<StepProvider>.value(
      value: stepProvider,
      child: MyApp(
        initialGoal: goal,
        repository: repository,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ),
    ),
  );

  // Initialize provider after first frame is built
  WidgetsBinding.instance.addPostFrameCallback((_) {
    stepProvider.init();
  });
}

class MyApp extends StatelessWidget {
  final int? initialGoal;
  final StepService repository;
  final bool hasCompletedOnboarding;

  const MyApp({
    super.key,
    this.initialGoal,
    required this.repository,
    required this.hasCompletedOnboarding,
  });

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
      home: hasCompletedOnboarding
          ? (initialGoal == null
                ? GoalSetupPage(repository: repository)
                : MainPage(repository: repository))
          : WelcomePage(repository: repository),
    );
  }
}
