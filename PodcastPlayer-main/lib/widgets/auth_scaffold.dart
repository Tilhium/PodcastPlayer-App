import 'package:flutter/material.dart';
import 'package:podcastplayer/theme/app_theme.dart';

class AuthScaffold extends StatelessWidget {
  final String appBarTitle;
  final bool showBack;
  final VoidCallback? onBack;
  final String headline;
  final String? subtitle;
  final Widget form;
  final List<Widget>? footer;
  final Widget? hero;

  const AuthScaffold({
    super.key,
    required this.appBarTitle,
    required this.headline,
    this.subtitle,
    required this.form,
    this.footer,
    this.showBack = false,
    this.onBack,
    this.hero,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: showBack,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: WhistilGradients.background,
            ),
          ),
          Positioned(
            top: -60,
            right: -20,
            child: _BackgroundBlob(
              diameter: 220,
              colors: [
                WhistilPalette.secondary.withOpacity(0.18),
                WhistilPalette.primary.withOpacity(0.12),
              ],
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: _BackgroundBlob(
              diameter: 260,
              colors: [
                Colors.white.withOpacity(0.65),
                WhistilPalette.secondary.withOpacity(0.08),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (hero != null) ...[
                        hero!,
                        const SizedBox(height: 28),
                      ],
                      Text(
                        headline,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: WhistilPalette.textPrimary,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: WhistilPalette.textSecondary,
                              ),
                        ),
                      ],
                      const SizedBox(height: 36),
                      SizedBox(width: double.infinity, child: AuthCard(child: form)),
                      if (footer != null) ...[
                        const SizedBox(height: 28),
                        ...footer!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: WhistilGradients.card,
        border: Border.all(color: WhistilPalette.outline.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: WhistilPalette.primary.withOpacity(0.12),
            blurRadius: 45,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: child,
    );
  }
}

class _BackgroundBlob extends StatelessWidget {
  final double diameter;
  final List<Color> colors;

  const _BackgroundBlob({required this.diameter, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: colors,
          center: Alignment.topLeft,
          radius: 0.8,
        ),
      ),
    );
  }
}
