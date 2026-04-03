import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'goal_setup_page.dart';
import '../utils/step_service.dart';

class OnboardingPage extends StatefulWidget {
  final StepService repository;

  const OnboardingPage({super.key, required this.repository});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  bool _activityGranted = false;
  bool _batteryGranted = false;
  bool _notificationGranted = false;

  bool _isLoading = false;

  final List<OnboardingStep> _steps = const [
    OnboardingStep(
      icon: Icons.directions_run_rounded,
      title: 'Activity Access',
      description:
          'Path needs activity recognition to track your steps accurately and help you reach your fitness goals.',
      buttonLabel: 'GRANT ACCESS',
    ),
    OnboardingStep(
      icon: Icons.battery_saver_rounded,
      title: 'Unrestricted Access',
      description:
          'To track steps even when the app is closed, please disable battery optimization for Path.',
      buttonLabel: 'REMOVE RESTRICTIONS',
    ),
    OnboardingStep(
      icon: Icons.notifications_active_rounded,
      title: 'Stay Updated',
      description:
          'Get real-time step count updates in your notification bar so you always know your progress.',
      buttonLabel: 'ENABLE NOTIFICATIONS',
    ),
  ];

  Future<void> _requestActivityPermission() async {
    setState(() => _isLoading = true);
    final status = await Permission.activityRecognition.request();
    setState(() {
      _activityGranted = status.isGranted;
      _isLoading = false;
    });
    if (_activityGranted) {
      _goToNextStep();
    }
  }

  Future<void> _requestBatteryOptimization() async {
    setState(() => _isLoading = true);
    final status = await Permission.ignoreBatteryOptimizations.request();
    setState(() {
      _batteryGranted = status.isGranted;
      _isLoading = false;
    });
    if (_batteryGranted) {
      _goToNextStep();
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _isLoading = true);
    final status = await Permission.notification.request();
    setState(() {
      _notificationGranted = status.isGranted;
      _isLoading = false;
    });
    if (_notificationGranted) {
      _goToGoalSetup();
    }
  }

  void _goToNextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToGoalSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GoalSetupPage(repository: widget.repository),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicators
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (index) {
                  final isActive = index == _currentStep;
                  final isCompleted = index < _currentStep;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive || isCompleted
                          ? const Color(0xFFC7F900)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 32),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _buildStep(
                    context,
                    _steps[index],
                    index,
                    textColor,
                    isDark,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    OnboardingStep step,
    int index,
    Color textColor,
    bool isDark,
  ) {
    final bool isGranted;
    final VoidCallback onPressed;

    switch (index) {
      case 0:
        isGranted = _activityGranted;
        onPressed = _requestActivityPermission;
      case 1:
        isGranted = _batteryGranted;
        onPressed = _requestBatteryOptimization;
      case 2:
        isGranted = _notificationGranted;
        onPressed = _requestNotificationPermission;
      default:
        isGranted = false;
        onPressed = () {};
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFC7F900).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, size: 60, color: const Color(0xFFC7F900)),
          ),
          const SizedBox(height: 48),
          // Title
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const Spacer(),
          // Button or granted status
          if (isGranted)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFFC7F900),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Granted',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC7F900),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black,
                          ),
                        ),
                      )
                    : Text(
                        step.buttonLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingStep {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;

  const OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
  });
}
