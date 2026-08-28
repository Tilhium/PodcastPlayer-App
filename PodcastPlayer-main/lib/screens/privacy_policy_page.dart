import 'package:flutter/material.dart';
import 'package:podcastplayer/widgets/auth_scaffold.dart';
import 'package:podcastplayer/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBarTitle: 'Privacy Policy',
      showBack: true,
      headline: 'Whistil Privacy Notice',
      subtitle: 'How we collect, use, and protect your information.',
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrivacySection(
            title: '1. Information We Collect',
            body:
                'We gather data you provide directly (name, email, profile details) and technical data generated when you listen, search, or interact with Whistil. Limited analytics data may be gathered through trusted service providers.',
          ),
          const SizedBox(height: 16),
          _PrivacySection(
            title: '2. Why We Collect It',
            body:
                'Data allows us to personalize recommendations, maintain account security, deliver customer support, and comply with legal obligations. Marketing messages are optional and you can opt out at any time.',
          ),
          const SizedBox(height: 16),
          _PrivacySection(
            title: '3. Sharing & Processing',
            body:
                'We never sell personal data. We share limited information with processors who help run core services (cloud hosting, analytics, payments) under confidentiality agreements. We may disclose information if lawfully required.',
          ),
          const SizedBox(height: 16),
          _PrivacySection(
            title: '4. Your Rights',
            body:
                'Depending on your region, you may request access, correction, deletion, or portability of your data. Contact privacy@whistil.app to exercise these rights or to withdraw consent to marketing communications.',
          ),
          const SizedBox(height: 16),
          _PrivacySection(
            title: '5. Data Security & Retention',
            body:
                'We use encryption, role-based access, and regular audits to protect your information. Personal data is retained only as long as necessary to provide the service or meet legal requirements, after which it is securely deleted.',
          ),
          const SizedBox(height: 16),
          _PrivacySection(
            title: '6. Children’s Privacy',
            body:
                'Whistil is not directed to individuals under 15. If we learn a minor has provided personal data, we will delete it and may terminate the account. Parents can contact us for assistance.',
          ),
          const SizedBox(height: 24),
          Text(
            'Questions? Reach out to privacy@whistil.app for clarification or requests.',
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

class _PrivacySection extends StatelessWidget {
  final String title;
  final String body;

  const _PrivacySection({required this.title, required this.body});

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
