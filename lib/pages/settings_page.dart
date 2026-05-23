import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/step_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _weekdayGoalController = TextEditingController();
  final _weekendGoalController = TextEditingController();

  String _gender = 'Other';
  bool _flexibleGoals = false;
  String _motionSensitivity = 'medium';

  @override
  void initState() {
    super.initState();
    final provider = context.read<StepProvider>();
    _heightController.text = provider.height.toStringAsFixed(0);
    _weightController.text = provider.weight.toStringAsFixed(0);
    _weekdayGoalController.text = provider.goalWeekday.toString();
    _weekendGoalController.text = provider.goalWeekend.toString();
    _gender = provider.gender;
    _flexibleGoals = provider.flexibleGoalsEnabled;
    _motionSensitivity = provider.motionSensitivity;
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _weekdayGoalController.dispose();
    _weekendGoalController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final height = double.tryParse(_heightController.text) ?? 170.0;
    final weight = double.tryParse(_weightController.text) ?? 70.0;
    context.read<StepProvider>().updateProfile(height, weight, _gender);
  }

  void _saveGoals() {
    final weekday = int.tryParse(_weekdayGoalController.text) ?? 10000;
    final weekend = int.tryParse(_weekendGoalController.text) ?? 6000;
    context.read<StepProvider>().updateFlexibleGoals(
          enabled: _flexibleGoals,
          weekday: weekday,
          weekend: weekend,
        );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = stepProvider.accentColor;
    final primaryTextColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.grey[900]! : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SETTINGS',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PERSONAL PROFILE CARD
            _buildSectionHeader('PERSONAL PROFILE', Icons.person_rounded, accentColor),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _heightController,
                          label: 'HEIGHT (cm)',
                          hint: '170',
                          isDark: isDark,
                          onChanged: (_) => _saveProfile(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _weightController,
                          label: 'WEIGHT (kg)',
                          hint: '70',
                          isDark: isDark,
                          onChanged: (_) => _saveProfile(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GENDER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Male', 'Female', 'Other'].map((g) {
                          final selected = _gender == g;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _gender = g);
                                _saveProfile();
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? accentColor
                                      : (isDark ? Colors.grey[800] : Colors.grey[200]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  g,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? Colors.black
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // VISUAL STYLE (THEME & ACCENT) CARD
            _buildSectionHeader('APPEARANCE', Icons.palette_rounded, accentColor),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ACCENT COLOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAccentCircle('Lime', const Color(0xFFC7F900), stepProvider),
                      _buildAccentCircle('Pink', const Color(0xFFFF007F), stepProvider),
                      _buildAccentCircle('Blue', const Color(0xFF007BFF), stepProvider),
                      _buildAccentCircle('Green', const Color(0xFF2ECC71), stepProvider),
                      _buildAccentCircle('Orange', const Color(0xFFE67E22), stepProvider),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'THEME MODE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ['system', 'light', 'dark'].map((mode) {
                      final selected = stepProvider.themeModeName == mode;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => stepProvider.updateThemeMode(mode),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                      ? accentColor
                                      : (isDark ? Colors.grey[800] : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              mode.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? Colors.black
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // GOAL TARGETS CARD
            _buildSectionHeader('DAILY TARGETS', Icons.radar_rounded, accentColor),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FLEXIBLE DAILY GOALS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      Switch(
                        value: _flexibleGoals,
                        activeColor: accentColor,
                        onChanged: (val) {
                          setState(() => _flexibleGoals = val);
                          _saveGoals();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: _flexibleGoals
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _weekdayGoalController,
                            label: 'WEEKDAY GOAL',
                            hint: '10000',
                            isDark: isDark,
                            onChanged: (_) => _saveGoals(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _weekendGoalController,
                            label: 'WEEKEND GOAL',
                            hint: '6000',
                            isDark: isDark,
                            onChanged: (_) => _saveGoals(),
                          ),
                        ),
                      ],
                    ),
                    secondChild: Container(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // CALIBRATION CARD
            _buildSectionHeader('MOTION CALIBRATION', Icons.tune_rounded, accentColor),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'VEHICLE ACCURACY SENSITIVITY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'High sensitivity counts fewer false steps in buses/trains but might miss light footsteps. Low sensitivity counts more active steps but may register transport steps.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: ['low', 'medium', 'high'].map((sensitivity) {
                      final selected = _motionSensitivity == sensitivity;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _motionSensitivity = sensitivity);
                            stepProvider.updateMotionSensitivity(sensitivity);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                      ? accentColor
                                      : (isDark ? Colors.grey[800] : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              sensitivity.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? Colors.black
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // BACKGROUND DIAGNOSTICS CARD
            _buildSectionHeader('BACKGROUND DIAGNOSTICS', Icons.developer_mode_rounded, accentColor),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'AGGRESSIVE BATTERY SAVING',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Android manufacturers frequently shut down background pedometers. Follow these steps for your device to ensure continuous tracking:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDiagnosticItem('Google Pixel', 'Settings > Apps > Path > Battery > Select "Unrestricted".', isDark),
                  _buildDiagnosticItem('Samsung', 'Settings > Battery > Background usage limits > Ensure Path is not in sleeping apps list.', isDark),
                  _buildDiagnosticItem('Xiaomi / Redmi', 'App Info > Battery Saver > Select "No restrictions".', isDark),
                  _buildDiagnosticItem('OnePlus', 'Settings > Apps > App management > Path > Battery usage > Enable "Allow background activity".', isDark),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => _launchUrl('https://dontkillmyapp.com'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryTextColor,
                      side: BorderSide(color: accentColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'DONTKILLMYAPP.COM GUIDE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.0,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color accentColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
          cursorColor: isDark ? Colors.white : Colors.black,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
            fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAccentCircle(String name, Color color, StepProvider provider) {
    final selected = provider.accentColorName == name;
    return GestureDetector(
      onTap: () => provider.updateAccentColor(name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                : Colors.transparent,
            width: selected ? 3 : 0,
          ),
        ),
        child: selected
            ? const Icon(
                Icons.check,
                color: Colors.black,
                size: 20,
              )
            : Container(),
      ),
    );
  }

  Widget _buildDiagnosticItem(String device, String instruction, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            device,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            instruction,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
