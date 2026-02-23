import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/app/util/validators/validator_helper.dart';
import 'package:amiraly/app/features/auth/login/loginscreen.dart';
import 'package:amiraly/app/features/auth/homepage/homepage.dart';
import 'package:amiraly/app/features/auth/onboarding/onboardingscreen.dart';
import 'package:amiraly/core/services/auth_service.dart';
import 'package:amiraly/main.dart' show ensureServicesInitialized;

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isCheckingServices = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkServices();
  }

  Future<void> _checkServices() async {
    try {
      await ensureServicesInitialized();

      final authService = Get.find<AuthService>();
      if (!authService.isInitialized) {
        await authService.initializeServices();
      }

      if (mounted) setState(() => _isCheckingServices = false);
    } catch (e, stackTrace) {
      AppLogger.logError('Service check failed', e, stackTrace);
      if (mounted) {
        setState(() {
          _isCheckingServices = false;
          _errorMessage = 'فشل في تهيئة الخدمات';
        });
      }
    }
  }

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
    if (_isCheckingServices) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkServices,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<bool>(
      future: _isOnboardingCompleted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'حدث خطأ في تحميل التطبيق',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }

        final isOnboardingCompleted = snapshot.data ?? false;
        if (!isOnboardingCompleted) return const OnboardingScreen();

        final user = Supabase.instance.client.auth.currentUser;
        return user != null ? const HomePage() : const LoginScreen();
      },
    );
  }
}
