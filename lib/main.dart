import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'utils/step_service.dart';
import 'pages/goal_setup_page.dart';
import 'pages/main_page.dart';
import 'providers/step_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final repository = StepService(prefs);
  final goal = await repository.getGoal();

  runApp(
    ChangeNotifierProvider(
      create: (_) => StepProvider(repository),
      child: MyApp(initialGoal: goal, repository: repository),
    ),
  );
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
      home: PermissionWrapper(
        child: initialGoal == null
            ? GoalSetupPage(repository: repository)
            : MainPage(goal: initialGoal!, repository: repository),
      ),
    );
  }
}

class PermissionWrapper extends StatelessWidget {
  final Widget child;
  const PermissionWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>();
    final isPermissionGranted = stepProvider.isPermissionGranted;

    return Stack(
      children: [
        child,
        if (!isPermissionGranted)
          Material(
            color: Colors.transparent,
            child: Container(
              color:
                  (Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white)
                      .withValues(alpha: 0.95),
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7F900).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_run_rounded,
                      size: 80,
                      color: Color(0xFFC7F900),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Activity Access Required',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Path needs activity recognition to track your steps and help you reach your goals. The app cannot function without this permission.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black)
                              .withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => stepProvider.requestPermission(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC7F900),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'GRANT ACCESS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
