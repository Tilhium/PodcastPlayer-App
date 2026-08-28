import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:podcastplayer/screens/home_page.dart';

class ProfilePictureSelectionPage extends StatefulWidget {
  final String name;
  final String email;
  final DateTime birthDate;

  ProfilePictureSelectionPage({
    required this.name,
    required this.email,
    required this.birthDate,
  });

  @override
  _ProfilePictureSelectionPageState createState() => _ProfilePictureSelectionPageState();
}

class _ProfilePictureSelectionPageState extends State<ProfilePictureSelectionPage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _profileImageUrl;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadProfilePicture();
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_imageFile == null) return;
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final storageRef = FirebaseStorage.instance.ref().child('profile_pictures').child(user.uid);
    await storageRef.putFile(_imageFile!);

    _profileImageUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'profileImageUrl': _profileImageUrl,
    });

    await user.updateProfile(photoURL: _profileImageUrl);
  }

  Future<void> _removeProfilePicture() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final storageRef = FirebaseStorage.instance.ref().child('profile_pictures').child(user.uid);
    try {
      await storageRef.delete();
    } catch (e) {
      print('Error: $e');
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'profileImageUrl': FieldValue.delete(),
    });

    await user.updateProfile(photoURL: null);

    setState(() {
      _imageFile = null;
      _profileImageUrl = null;
    });
  }

  void _skip() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final profileImageUrl = 'assets/images/profileimage.jpg';
    
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'profileImageUrl': profileImageUrl,
    });

    await user.updateProfile(photoURL: profileImageUrl);

    _navigateToHomePage();
  }

  void _navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          name: widget.name,
          email: widget.email,
          birthDate: widget.birthDate,
          profileImagePath: _profileImageUrl ?? 'assets/images/profileimage.jpg',
        ),
      ),
    );
  }

  void _confirmSelection() async {
    if (_imageFile != null) {
      await _uploadProfilePicture();
    }
    _navigateToHomePage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SELECT PROFILE PICTURE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple[800],
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _skip,
            child: Text(
              'Skip',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple[800]!,
              Colors.deepPurple[200]!,
            ],
          ),
        ),
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: _imageFile != null
                    ? CircleAvatar(
                        radius: 80,
                        backgroundImage: FileImage(_imageFile!),
                      )
                    : CircleAvatar(
                        radius: 80,
                        backgroundImage: AssetImage('assets/images/profileimage.jpg'),
                      ),
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.photo),
              label: Text('Choose from Gallery'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.deepPurple[800],
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 20.0,
                ),
              ),
            ),
            SizedBox(height: 20.0),
            if (_imageFile != null)
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.edit),
                label: Text('Change Image'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.deepPurple[800],
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 20.0,
                  ),
                ),
              ),
            SizedBox(height: 20.0),
            if (_imageFile != null)
              ElevatedButton.icon(
                onPressed: () async {
                  await _removeProfilePicture();
                },
                icon: Icon(Icons.remove_circle),
                label: Text('Remove Image'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.deepPurple[800],
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 20.0,
                  ),
                ),
              ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _imageFile != null ? _confirmSelection : null,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 20.0,
                ),
              ),
              child: Text(
                'Ok',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
