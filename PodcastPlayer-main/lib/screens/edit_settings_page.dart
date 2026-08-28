import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:podcastplayer/models/profile_edit_result.dart';
import 'package:podcastplayer/theme/app_theme.dart';
import 'package:podcastplayer/widgets/gradient_button.dart';

class EditSettingsPage extends StatefulWidget {
  final String name;
  final String email;
  final DateTime birthDate;
  final String profileImagePath;

  EditSettingsPage({
    required this.name,
    required this.email,
    required this.birthDate,
    required this.profileImagePath,
  });

  @override
  _EditSettingsPageState createState() => _EditSettingsPageState();
}

class _EditSettingsPageState extends State<EditSettingsPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late DateTime _selectedDate;
  bool _passwordUpdated = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _selectedDate = widget.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? _selectedDate : today,
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Select your birth date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: WhistilPalette.primary,
                  onSurface: WhistilPalette.textPrimary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      _showSnack('You need to be logged in to change your password.');
      return;
    }

    final currentPassword = await _showPasswordPrompt(
      title: 'Verify Current Password',
      confirmLabel: 'Verify',
    );

    if (currentPassword == null || currentPassword.isEmpty) return;

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (_) {
      _showSnack('Incorrect password. Please try again.');
      return;
    }

    final newPassword = await _showPasswordPrompt(
      title: 'Choose a new password',
      hintText: 'Minimum 8 characters, incl. uppercase',
      confirmLabel: 'Change password',
      validator: (value) {
        if (value == null || value.length < 8) {
          return 'Must be at least 8 characters long';
        }
        if (!value.contains(RegExp(r'[A-Z]'))) {
          return 'Include at least one uppercase letter';
        }
        return null;
      },
    );

    if (newPassword == null || newPassword.isEmpty) return;

    try {
      await user.updatePassword(newPassword);
      setState(() => _passwordUpdated = true);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => _SuccessDialog(
          title: 'Password updated',
          message: 'Your password has been changed successfully.',
        ),
      );
    } on FirebaseAuthException catch (error) {
      _showSnack(error.message ?? 'Failed to update password.');
    }
  }

  Future<String?> _showPasswordPrompt({
    required String title,
    String? hintText,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    String? Function(String?)? validator,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: hintText ?? 'Enter password',
              ),
              validator: validator,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(cancelLabel),
            ),
            GradientButton(
              label: confirmLabel,
              expand: false,
              onPressed: () {
                if (validator == null || formKey.currentState!.validate()) {
                  Navigator.of(context).pop(controller.text);
                }
              },
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ],
        );
      },
    );

    return result;
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    if (newName.isEmpty) {
      _showSnack('Please enter your name.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw FirebaseAuthException(code: 'user-not-found');

      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'name': newName,
        'email': newEmail,
        'birthDate': Timestamp.fromDate(_selectedDate),
      });

      if (currentUser.email != newEmail) {
        await currentUser.updateEmail(newEmail);
      }

      if (!mounted) return;
      Navigator.of(context).pop(
        ProfileEditResult(
          name: newName,
          email: newEmail,
          birthDate: _selectedDate,
          profileImagePath: widget.profileImagePath,
          passwordUpdated: _passwordUpdated,
        ),
      );
    } on FirebaseAuthException catch (error) {
      _showSnack(error.message ?? 'Failed to save changes.');
    } catch (error) {
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final birthDateLabel = '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}';

    return Scaffold(
      backgroundColor: WhistilPalette.background,
      extendBody: true,
      appBar: AppBar(
        title: Text('Edit profile', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: GradientButton(
              label: _isSaving ? 'Saving...' : 'Save',
              expand: false,
              onPressed: () {
                if (_isSaving) return;
                _saveChanges();
              },
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: WhistilGradients.background,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          gradient: WhistilGradients.card,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 24,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile details',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: WhistilPalette.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Name',
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              readOnly: true,
                              suffixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: WhistilPalette.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _DatePickerTile(
                              label: 'Birth date',
                              value: birthDateLabel,
                              onTap: () => _selectDate(context),
                            ),
                          ],
                        ),
                      ),
                const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: WhistilGradients.card,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: WhistilPalette.primary.withOpacity(0.06),
                              blurRadius: 26,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Security',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: WhistilPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Update your password to keep your Whistil profile protected.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: WhistilPalette.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            GradientButton(
                              label: 'Change password',
                              expand: false,
                              leading: const Icon(Icons.lock_reset_rounded, size: 18, color: Colors.white),
                              onPressed: _changePassword,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.suffixIcon,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final Widget? suffixIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: WhistilPalette.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          enableInteractiveSelection: !readOnly,
          onTap: readOnly
              ? () {
                  FocusScope.of(context).unfocus();
                  onTap?.call();
                }
              : onTap,
          decoration: InputDecoration(
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: WhistilPalette.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: WhistilPalette.outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: WhistilPalette.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_rounded, color: WhistilPalette.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title, style: theme.textTheme.titleMedium),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        GradientButton(
          label: 'Got it',
          expand: false,
          onPressed: () => Navigator.of(context).pop(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ],
    );
  }
}
