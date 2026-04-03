import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'utils/step_service.dart';
import 'utils/background_service.dart';
import 'pages/goal_setup_page.dart';
import 'pages/main_page.dart';
import 'providers/step_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service
  await initializeService();

  final prefs = await SharedPreferences.getInstance();

  final repository = StepService(prefs);
  final goal = await repository.getGoal();

  final stepProvider = StepProvider(repository);

  runApp(
    ChangeNotifierProvider<StepProvider>.value(
      value: stepProvider,
      child: MyApp(initialGoal: goal, repository: repository),
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
      home: Builder(
        builder: (context) => PermissionWrapper(
          child:
              (initialGoal == null
                      ? GoalSetupPage(repository: repository)
                      : MainPage(repository: repository))
                  as Widget,
        ),
      ),
    );
  }
}

class PermissionWrapper extends StatelessWidget {
  final Widget child;
  const PermissionWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    StepProvider? stepProvider;
    try {
      stepProvider = context.watch<StepProvider>();
    } catch (e) {
      // Provider not available yet
    }

    // If provider is not available yet, show the child without permission checks
    if (stepProvider == null) {
      return child;
    }

    final isPermissionGranted = stepProvider.isPermissionGranted;
    final isBatteryOptimizationIgnored =
        stepProvider.isBatteryOptimizationIgnored;
    final isRequirementMet =
        isPermissionGranted && isBatteryOptimizationIgnored;

    if (isRequirementMet) return child;

    return Stack(
      children: [
        child,
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
                  child: Icon(
                    !isPermissionGranted
                        ? Icons.directions_run_rounded
                        : Icons.battery_saver_rounded,
                    size: 80,
                    color: const Color(0xFFC7F900),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  !isPermissionGranted
                      ? 'Activity Access Required'
                      : 'Unrestricted Access',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  !isPermissionGranted
                      ? 'Path needs activity recognition to track your steps and help you reach your goals.'
                      : 'To track steps even when the app is closed, please disable battery optimization for Path.',
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
                    onPressed: () => stepProvider?.requestPermission(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC7F900),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      !isPermissionGranted
                          ? 'GRANT ACCESS'
                          : 'REMOVE RESTRICTIONS',
                      style: const TextStyle(
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
