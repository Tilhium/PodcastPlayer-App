import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:podcastplayer/screens/home_page.dart';
import 'package:podcastplayer/screens/signup_page.dart';
import 'package:podcastplayer/screens/forgot_password.dart';
import 'package:podcastplayer/screens/verify_email.dart';
import 'package:podcastplayer/widgets/gradient_button.dart';
import 'package:podcastplayer/widgets/auth_scaffold.dart';
import 'package:podcastplayer/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBarTitle: 'Welcome',
      hero: Image.asset('assets/app_icon.png', height: 96),
      headline: 'Welcome back',
      subtitle: 'Log in to keep riding the Whistil wave.',
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign in to your account',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: WhistilPalette.textSecondary,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: WhistilPalette.primary,
              ),
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Sign in',
            onPressed: () => _signIn(context),
            textColor: WhistilPalette.textPrimary,
          ),
        ],
      ),
      footer: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'New to Whistil?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: WhistilPalette.textSecondary,
                  ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpPage()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: WhistilPalette.primary,
              ),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ],
    );
  }

  void _signIn(BuildContext context) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Please verify your email before logging in.'),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await userCredential.user!.sendEmailVerification();

                      DocumentSnapshot userSnapshot = await FirebaseFirestore
                          .instance
                          .collection('users')
                          .doc(userCredential.user!.uid)
                          .get();

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmailVerificationPage(
                            name: userSnapshot['name'],
                            email: userCredential.user!.email!,
                            birthDate: userSnapshot['birthDate'],
                          ),
                        ),
                      );
                    },
                    child: Text('Verify Email'),
                  ),
                ],
              ),
            );
          },
        );
        return;
      }

      if (userCredential.user != null) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        if (userSnapshot.exists) {
          Timestamp birthDateTimestamp = userSnapshot['birthDate'];
          DateTime birthDate = birthDateTimestamp.toDate();
          String profileImageUrl = userSnapshot['profileImageUrl'] ??
              'assets/images/profileimage.jpeg';
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                name: userSnapshot['name'],
                email: userCredential.user!.email!,
                birthDate: birthDate,
                profileImagePath: profileImageUrl,
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(e.message ?? 'An error occurred.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Ok'),
              ),
            ],
          );
        },
      );
    }
  }
}
