import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/step_service.dart';
import 'main_page.dart';

class GoalSetupPage extends StatefulWidget {
  final StepService repository;
  const GoalSetupPage({super.key, required this.repository});

  @override
  State<GoalSetupPage> createState() => _GoalSetupPageState();
}

class _GoalSetupPageState extends State<GoalSetupPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentGoal();
  }

  void _loadCurrentGoal() async {
    final goal = await widget.repository.getGoal();
    if (goal != null) {
      _controller.text = goal.toString();
    }
  }

  void _saveGoal() async {
    final String text = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    final int? goal = int.tryParse(text);
    if (goal != null && goal >= 10 && goal <= 1000000) {
      await widget.repository.saveGoal(goal);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainPage(goal: goal, repository: widget.repository),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter a valid number between 10 and 1,000,000',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Daily Goal',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      cursorColor: textColor,
                      autofocus: true,
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: -2.0,
                        height: 1.2,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '10000',
                        hintStyle: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      onSubmitted: (_) => _saveGoal(),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Update goal',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
