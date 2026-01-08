import 'package:amiraly/E-commerce_project/features/auth/homepage/homepage.dart';
import 'package:amiraly/E-commerce_project/features/auth/login/loginscreen.dart';
import 'package:amiraly/E-commerce_project/features/auth/onboarding/onboardingscreen.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/E-commerce_project/util/validators/validatorHeper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.onboardingKey) ?? false;
    } catch (e) {
      AppLogger.logError('Failed to check onboarding status', e);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isOnboardingCompleted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ في تحميل التطبيق',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        final isOnboardingCompleted = snapshot.data ?? false;
        if (!isOnboardingCompleted) {
          return const OnboardingScreen();
        }

        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        return user != null ? const HomePage() : const LoginScreen();
      },
    );
  }
}
