import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/user%20registration/SignUp.dart';
import 'package:petpal/user%20registration/login.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _profileImageUrl;

  Future<DocumentSnapshot> _getUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User is not logged in");
    }
    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  Future<void> _updateUserDetails(String phone, String address) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User is not logged in");
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'phone': phone,
      'address': address,
      'profilePhoto': _profileImageUrl,
    });

    // Update the text controllers to reflect the new data immediately
    setState(() {
      _phoneController.text = phone;
      _addressController.text = address;
    });
  }

  Future<void> _uploadProfilePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.gallery);

    if (photo != null) {
      File file = File(photo.path);
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference reference =
          FirebaseStorage.instance.ref().child('profile_photos/$fileName');
      await reference.putFile(file);
      String downloadUrl = await reference.getDownloadURL();
      setState(() {
        _profileImageUrl = downloadUrl;
      });
      // Optionally update Firestore with the new photo URL
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profilePhoto': _profileImageUrl});
      }
    }
  }

  Future<void> _deleteUser() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User is not logged in");
    }

    // Delete pets associated with the user
    var petsSnapshot = await FirebaseFirestore.instance
        .collection('pets')
        .where('userId', isEqualTo: user.uid)
        .get();

    for (var pet in petsSnapshot.docs) {
      await pet.reference.delete();
    }

    // Delete user from the 'users' collection
    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

    // Optionally, delete the user account from Firebase Auth
    await user.delete();

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const SignUp())); // Adjust as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _getUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No user details found."));
          }

          var userDetails = snapshot.data!.data() as Map<String, dynamic>;
          _phoneController.text = userDetails['phone'] ?? '';
          _addressController.text = userDetails['address'] ?? '';
          _profileImageUrl = userDetails['profilePhoto'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Information',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: _uploadProfilePhoto,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null
                          ? const Icon(Icons.add_a_photo, size: 50)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // User Details Card
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildUserDetailRow(
                          icon: Icons.person,
                          label: 'Name',
                          value: userDetails['name'] ?? 'N/A',
                        ),
                        const Divider(),
                        _buildUserDetailRow(
                          icon: Icons.email,
                          label: 'Email',
                          value: userDetails['email'] ?? 'N/A',
                        ),
                        const Divider(),
                        _buildUserDetailRow(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: _phoneController.text.isNotEmpty
                              ? _phoneController.text
                              : 'null',
                          onEdit: () => _showUpdateDialog('phone'),
                        ),
                        const Divider(),
                        _buildUserDetailRow(
                          icon: Icons.home,
                          label: 'Address',
                          value: _addressController.text.isNotEmpty
                              ? _addressController.text
                              : 'null',
                          onEdit: () => _showUpdateDialog('address'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Delete button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirmation = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Confirm Deletion'),
                            content: const Text(
                                'Are you sure you want to delete your account? This action cannot be undone.'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmation == true) {
                        await _deleteUser();
                        Navigator.of(context)
                            .pushReplacementNamed('/login'); // Adjust as needed
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserDetailRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent),
            onPressed: onEdit,
          ),
      ],
    );
  }

  void _showUpdateDialog(String type) {
    TextEditingController controller =
        type == 'phone' ? _phoneController : _addressController;

    String title = type.capitalize();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update $title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: title),
            keyboardType: type == 'phone'
                ? TextInputType.phone
                : TextInputType.streetAddress,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String updatedValue = controller.text.trim();
                if (type == 'phone') {
                  await _updateUserDetails(
                      updatedValue, _addressController.text.trim());
                } else {
                  await _updateUserDetails(
                      _phoneController.text.trim(), updatedValue);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Profile updated successfully!')),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return this.isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}
