import 'package:flutter/material.dart';
import 'package:podcastplayer/widgets/auth_scaffold.dart';
import 'package:podcastplayer/theme/app_theme.dart';

class TermsOfServicePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBarTitle: 'Terms of Service',
      showBack: true,
      headline: 'Whistil Terms of Service',
      subtitle: 'Please review these key points before creating an account.',
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Section(
            title: '1. Eligibility & Account Responsibilities',
            body:
                'You must be at least 15 years old and able to enter into a binding contract. Keep your login credentials confidential and notify us immediately of any unauthorized use.',
          ),
          const SizedBox(height: 16),
          _Section(
            title: '2. Acceptable Use',
            body:
                'Use Whistil only for lawful purposes. Do not publish audio or text that infringes intellectual property, spreads malware, or harasses other users. We may suspend accounts that violate these rules.',
          ),
          const SizedBox(height: 16),
          _Section(
            title: '3. Content & Licensing',
            body:
                'You retain rights to content you upload but grant Whistil a non-exclusive license to host and distribute it within the service. You are responsible for ensuring you have the rights to all submitted material.',
          ),
          const SizedBox(height: 16),
          _Section(
            title: '4. Subscriptions & Payments',
            body:
                'Paid features, when available, will be billed through the app store tied to your device. Charges are non-refundable except as required by local law. Cancel recurring plans before renewal to avoid additional fees.',
          ),
          const SizedBox(height: 16),
          _Section(
            title: '5. Service Changes & Termination',
            body:
                'We may modify or discontinue aspects of the service with prior notice where possible. Accounts may be terminated for violating these terms or at the user’s request. Remaining statutory rights are unaffected.',
          ),
          const SizedBox(height: 24),
          Text(
            'By continuing you acknowledge that you have read and agree to these terms.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WhistilPalette.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WhistilPalette.outline),
        boxShadow: [
          BoxShadow(
            color: WhistilPalette.primary.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: WhistilPalette.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WhistilPalette.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
