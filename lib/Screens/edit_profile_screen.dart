import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage package
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Image picker package

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  File? _profileImage; // Profile image file
  File? _coverImage; // Cover image file
  String? _profileImageUrl; // Profile image URL from Firebase Storage
  String? _coverImageUrl; // Cover image URL from Firebase Storage
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  // Load current user details into form fields
  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

    _nameController.text = userData['name'] ?? '';
    _bioController.text = userData['bio'] ?? '';
    _profileImageUrl = userData['profileImageUrl'];
    _coverImageUrl = userData['coverImageUrl'];
    setState(() {}); // Trigger UI update
  }

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user details into the form on initialization
  }

  // Save updated profile details to Firestore
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // Save profile data (name, bio, profile image URL, cover image URL) to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text,
          'bio': _bioController.text,
          'profilePhotoUrl': _profileImageUrl,
          'coverPhotoUrl': _coverImageUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));

        Navigator.pop(context); // Go back to the previous screen after saving
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
      }
    }
  }

  // Upload image to Firebase Storage and return the download URL
  Future<String?> _uploadImage(File image, String filePath) async {
    try {
      Reference storageReference = FirebaseStorage.instance.ref().child(filePath);
      UploadTask uploadTask = storageReference.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Pick and upload profile image
  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _profileImage = File(pickedFile.path);
      String? downloadUrl = await _uploadImage(_profileImage!, 'profile_pictures/${FirebaseAuth.instance.currentUser!.uid}/profile.jpg');
      setState(() {
        _profileImageUrl = downloadUrl; // Set profile image URL
      });
    }
  }

  // Pick and upload cover image
  Future<void> _pickCoverImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _coverImage = File(pickedFile.path);
      String? downloadUrl = await _uploadImage(_coverImage!, 'cover_pictures/${FirebaseAuth.instance.currentUser!.uid}/cover.jpg');
      setState(() {
        _coverImageUrl = downloadUrl; // Set cover image URL
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0, // Removes shadow
        iconTheme: const IconThemeData(color: Colors.black), // Back button color
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cover Photo Section
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // Placeholder color for cover image
                    image: _coverImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_coverImageUrl!), // Display cover image from URL
                            fit: BoxFit.cover,
                          )
                        : null, // Add cover image URL if loaded from the database
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.orange, size: 30),
                    onPressed: _pickCoverImage, // Function to pick cover image
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Profile Image Section
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : const NetworkImage("https://via.placeholder.com/150"), // Placeholder or loaded image
              child: Align(
                alignment: Alignment.bottomRight,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.orange),
                  onPressed: _pickProfileImage, // Function to pick profile image
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Form for name and bio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Name Input Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.orange),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Bio Input Field
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.orange),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a bio';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 40),

                    // Save Changes Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
