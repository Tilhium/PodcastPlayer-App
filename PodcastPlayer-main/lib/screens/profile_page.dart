import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:podcastplayer/screens/home_page.dart';
import 'package:podcastplayer/screens/library_page.dart';
import 'package:podcastplayer/screens/login_page.dart';
import 'package:podcastplayer/screens/edit_settings_page.dart';
import 'package:podcastplayer/models/profile_edit_result.dart';
import 'package:podcastplayer/theme/app_theme.dart';
import 'package:podcastplayer/utils/navigation_helpers.dart';
import 'package:podcastplayer/widgets/app_bottom_nav.dart';
import 'package:podcastplayer/widgets/gradient_button.dart';

class ProfilePage extends StatefulWidget {
  final String name;
  final String email;
  final DateTime birthDate;
  final String profileImagePath;

  ProfilePage({
    required this.name,
    required this.email,
    required this.birthDate,
    required this.profileImagePath,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _profileImagePath;
  late String _password;
  late String _name;
  late String _email;
  late DateTime _birthDate;

  @override
  void initState() {
    super.initState();
    _profileImagePath = widget.profileImagePath;
    _password = 'Set password';
    _name = widget.name;
    _email = widget.email;
    _birthDate = widget.birthDate;

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.providerData.isNotEmpty) {
      final usesPasswordProvider =
          user.providerData.any((provider) => provider.providerId == 'password');
      if (usesPasswordProvider) {
        _password = '••••••••';
      }
    }

    _loadLatestProfile();
  }

  Future<void> _loadLatestProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!snapshot.exists || !mounted) return;

      final data = snapshot.data();
      if (data == null) return;

      setState(() {
        final remoteImage = data['profileImageUrl'] as String?;
        if (remoteImage != null && remoteImage.isNotEmpty) {
          _profileImagePath = remoteImage;
        }

        final remoteName = data['name'] as String?;
        if (remoteName != null && remoteName.isNotEmpty) {
          _name = remoteName;
        }

        final remoteEmail = data['email'] as String?;
        if (remoteEmail != null && remoteEmail.isNotEmpty) {
          _email = remoteEmail;
        }

        final birthDate = data['birthDate'];
        if (birthDate is Timestamp) {
          _birthDate = birthDate.toDate();
        }
      });
    } catch (error) {
      debugPrint('Failed to refresh profile data: $error');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImagePath = pickedFile.path;
      });
      await _uploadProfileImage(File(_profileImagePath));
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _profileImagePath = 'assets/images/profileimage.jpg';
    });
    await _uploadProfileImage(File('assets/images/profileimage.jpg'), isAsset: true);
  }

  String _withCacheBuster(String url) {
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';
  }

 Future<void> _uploadProfileImage(File imageFile, {bool isAsset = false}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user is signed in.');
      return;
    }

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child(user.uid + '.jpg');

    if (isAsset) {
      final assetBundle = DefaultAssetBundle.of(context);
      final data = await assetBundle.load('assets/images/profileimage.jpg');
      await ref.putData(data.buffer.asUint8List());
    } else {
      await ref.putFile(imageFile);
    }

    final downloadUrl = await ref.getDownloadURL();
    final cacheSafeUrl = _withCacheBuster(downloadUrl);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'profileImageUrl': cacheSafeUrl,
    });

    await user.updatePhotoURL(cacheSafeUrl);

      setState(() {
        _profileImagePath = cacheSafeUrl;
      });
    } catch (error) {
      print('Error uploading profile image: $error');
    }
  }

  void _showImageOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profile Picture Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo),
              title: Text('Change Picture'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Remove Picture'),
              onTap: () async {
                Navigator.pop(context);
                await _removeImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user is signed in.');
      return;
    }

    final email = user.email;
    if (email == null) {
      print('User email is null.');
      return;
    }

    final credential = EmailAuthProvider.credential(email: email, password: 'current_password');
    await user.reauthenticateWithCredential(credential);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password verified successfully.')),
    );

    String newPassword = await _getNewPassword(context);
    if (newPassword.isNotEmpty) {
      await user.updatePassword(newPassword);
      setState(() {
        _password = '••••••••';
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Password updated successfully'),
            content: Text('Your password has been updated successfully.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<String> _getNewPassword(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter new password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'New password',
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop('');
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
            ),
          ],
        );
      },
    );
    return controller.text;
  }

  Widget _buildProfileAvatar() {
    final imageProvider = _resolveProfileImage();

    return GestureDetector(
      onTap: _showImageOptions,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: WhistilGradients.card,
              boxShadow: [
                BoxShadow(
                  color: WhistilPalette.primary.withOpacity(0.18),
                  blurRadius: 26,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: ClipOval(
              child: Image(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: WhistilPalette.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: WhistilPalette.primary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _resolveProfileImage() {
    final path = _profileImagePath;
    if (path.isEmpty) {
      return const AssetImage('assets/images/profileimage.jpg');
    }
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    return FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final birthDateLabel = '${_birthDate.day.toString().padLeft(2, '0')}.${_birthDate.month.toString().padLeft(2, '0')}.${_birthDate.year}';

    return Scaffold(
      backgroundColor: WhistilPalette.background,
      extendBody: true,
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: WhistilGradients.background,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your profile',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: WhistilPalette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GradientButton(
                      label: 'Edit profile',
                      expand: false,
                      leading: const Icon(Icons.edit, size: 18, color: Colors.white),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      textStyle: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      onPressed: _navigateToEditSettings,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    gradient: WhistilGradients.card,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: WhistilPalette.primary.withOpacity(0.1),
                        blurRadius: 32,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                  child: Column(
                    children: [
                      _buildProfileAvatar(),
                      const SizedBox(height: 20),
                      Text(
                        _name,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: WhistilPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: WhistilPalette.primarySoft.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          _email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: WhistilPalette.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Account information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: WhistilPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: WhistilGradients.card,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ProfileDetailTile(
                        icon: Icons.person_outline,
                        label: 'Name',
                        value: _name,
                        onTap: _navigateToEditSettings,
                      ),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFE9E0FF)),
                      _ProfileDetailTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: _email,
                        onTap: _navigateToEditSettings,
                      ),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFE9E0FF)),
                      _ProfileDetailTile(
                        icon: Icons.cake_outlined,
                        label: 'Birth date',
                        value: birthDateLabel,
                        onTap: _navigateToEditSettings,
                      ),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFE9E0FF)),
                      _ProfileDetailTile(
                        icon: Icons.lock_outline,
                        label: 'Password',
                        value: _password,
                        onTap: _navigateToEditSettings,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                GradientButton(
                  label: 'Log out',
                  expand: true,
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: WhistilBottomNav(
        currentIndex: 2,
        onItemSelected: (index) {
          if (index == 2) return;
          if (index == 0) {
            slideToPage(
              context,
              LibraryPage(
                name: _name,
                email: _email,
                birthDate: _birthDate,
                profileImagePath: _profileImagePath,
              ),
              forward: false,
            );
          } else if (index == 1) {
            slideToPage(
              context,
              HomePage(
                name: _name,
                email: _email,
                birthDate: _birthDate,
                profileImagePath: _profileImagePath,
              ),
              forward: false,
            );
          }
        },
      ),
    );
  }

  void _navigateToEditSettings() async {
    final result = await Navigator.push<ProfileEditResult>(
      context,
      MaterialPageRoute(
        builder: (context) => EditSettingsPage(
          name: _name,
          email: _email,
          birthDate: _birthDate,
          profileImagePath: _profileImagePath,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _name = result.name;
      _email = result.email;
      _birthDate = result.birthDate;
      if (result.profileImagePath != null) {
        _profileImagePath = result.profileImagePath!;
      }
      if (result.passwordUpdated) {
        _password = '••••••••';
      }
    });
  }
}

class _ProfileDetailTile extends StatelessWidget {
  const _ProfileDetailTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: WhistilPalette.primarySoft.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: WhistilPalette.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: WhistilPalette.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: WhistilPalette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: WhistilPalette.primary),
            ],
          ),
        ),
      ),
    );
  }
}
