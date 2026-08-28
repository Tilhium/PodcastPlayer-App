import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:podcastplayer/widgets/auth_scaffold.dart';
import 'package:podcastplayer/widgets/gradient_button.dart';
import 'package:podcastplayer/theme/app_theme.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reset password link has been sent to $email',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WhistilPalette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          action: SnackBarAction(
            label: 'Ok',
            textColor: WhistilPalette.primary,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send reset password link. Please try again.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WhistilPalette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: WhistilPalette.primary,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBarTitle: 'Reset password',
      showBack: true,
      headline: 'Forgot your password?',
      subtitle:
          'Enter the email you use for Whistil and we’ll send a magic reset link.',
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Send reset link',
            textColor: WhistilPalette.primary,
            onPressed: _resetPassword,
          ),
        ],
      ),
    );
  }
}
