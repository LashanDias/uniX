import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  bool isSuccessState = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: isSuccessState ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAlignment.center,
        children: [
          const SizedBox(height: 10),
          const Text(
            'New Password',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 30),

          // Illustration
          Icon(Icons.shield_outlined, size: 80, color: AppColors.primary),
          const SizedBox(height: 36),

          TextField(
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'New Password',
              prefixIcon: Icon(Icons.lock_outline, size: 20),
              suffixIcon: Icon(Icons.visibility_off_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_outline, size: 20),
              suffixIcon: Icon(Icons.visibility_off_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 36),

          ElevatedButton(
            onPressed: () {
              setState(() {
                isSuccessState = true;
              });
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: const [
                Icon(Icons.check_circle_rounded, size: 100, color: Color(0xFF0284C7)),
                SizedBox(height: 24),
                Text(
                  'New password set successfully !',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
