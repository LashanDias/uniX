import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_error_messages.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.returnAfterSignIn = false});
  final bool returnAfterSignIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted && user.uid.isNotEmpty) {
        if (widget.returnAfterSignIn) {
          Navigator.pop(context, true);
        } else {
          final route = await AuthService.homeRoute();
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, route);
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        if (error.code == 'invalid-credential' ||
            error.code == 'wrong-password') {
          setState(() {
            _passwordError =
                "Wrong password. Try again or click 'Forgot password' to reset it.";
          });
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to sign in. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.signInWithGoogle();
      if (mounted && user != null) {
        if (widget.returnAfterSignIn) {
          Navigator.pop(context, true);
        } else {
          final route = await AuthService.homeRoute();
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, route);
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(socialAuthMessage(error, provider: 'Google')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Apple and LinkedIn sign-in are not connected yet.
  ///
  /// Enabling either needs an account with that provider and the matching
  /// Firebase configuration, which is not something the app can do by itself.
  /// Until then the buttons are visibly disabled and say so in plain words,
  /// rather than looking live and failing.
  void _showProviderSetupMessage(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$provider sign-in is not available yet. '
          'Use your SLTC email, or continue with Google.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                children: [
                  const SizedBox(height: 56),
                  Image.asset(
                    'assets/images/unix_logo.png',
                    width: 88,
                    height: 88,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Welcome! 👋',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EDF5),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Password',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          onChanged: (_) {
                            if (_passwordError != null) {
                              setState(() => _passwordError = null);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            fillColor: Colors.white,
                            error: _passwordError == null
                                ? null
                                : Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.error,
                                          color: AppColors.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _passwordError!,
                                            style: const TextStyle(
                                              color: AppColors.error,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/forgot_password',
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          child: Text(_isLoading ? 'Signing in...' : 'Login'),
                        ),
                        if (!widget.returnAfterSignIn)
                          TextButton.icon(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              '/main',
                            ),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                            ),
                            label: const Text('Continue as guest'),
                          ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'or continue with',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _socialIconButton(
                              asset: 'assets/images/google_logo.png',
                              onTap: _isLoading ? () {} : _signInWithGoogle,
                            ),
                            const SizedBox(width: 16),
                            _socialIconButton(
                              icon: Icons.apple,
                              color: Colors.black,
                              enabled: false,
                              onTap: () => _showProviderSetupMessage('Apple'),
                            ),
                            const SizedBox(width: 16),
                            _socialIconButton(
                              asset: 'assets/images/linkedin_logo.png',
                              enabled: false,
                              onTap: () =>
                                  _showProviderSetupMessage('LinkedIn'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Registration is limited to verified SLTC institutional emails.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Wrap, not Row: at narrow widths or with a large system
                  // font the prompt and the link no longer fit on one line.
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (!widget.returnAfterSignIn) {
                            Navigator.pushNamed(context, '/signup');
                            return;
                          }
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SignupScreen(returnAfterSignIn: true),
                            ),
                          );
                          if (context.mounted && result == true) {
                            Navigator.pop(context, true);
                          }
                        },
                        child: const Text(
                          'Sign UP',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialIconButton({
    IconData? icon,
    Color color = AppColors.primary,
    String? asset,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 62,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: asset != null
            ? Image.asset(asset, width: 20, height: 20, fit: BoxFit.contain)
            : Icon(icon, color: color, size: 24),
      ),
    ),
    );
  }
}
