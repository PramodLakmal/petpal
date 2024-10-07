import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:petpal/user%20registration/login.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  Future<DocumentSnapshot> _getUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User is not logged in");
    }
    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  Stream<QuerySnapshot> _getUserPosts() {
    User? user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _getUserPets() {
    User? user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('pets')
        .where('userId', isEqualTo: user!.uid)
        .snapshots();
  }

  // Upload profile photo
  Future<void> _uploadProfilePhoto() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      File file = File(pickedFile.path);

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/profile_photo.jpg');
      await storageRef.putFile(file);

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profilePhotoUrl': downloadUrl});
    } catch (e) {
      print('Error uploading profile photo: $e');
    }
  }

  // Upload cover photo
  Future<void> _uploadCoverPhoto() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      File file = File(pickedFile.path);

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/cover_photo.jpg');
      await storageRef.putFile(file);

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'coverPhotoUrl': downloadUrl});
    } catch (e) {
      print('Error uploading cover photo: $e');
    }
  }

  // Function to edit profile
  Future<void> _editProfile() async {
    // Implement the logic for editing the user's profile here
    print('Edit Profile pressed');
  }

  // Function to delete profile
  Future<void> _deleteProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Delete user data from Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // Delete user authentication account
      await user.delete();

      // Navigate to the login screen or a suitable page
      Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                    );
    } catch (e) {
      print('Error deleting profile: $e');
    }
  }

  // Logout function
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Owner Profile', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orangeAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _editProfile, // Edit profile functionality
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () async {
              // Show confirmation dialog before deleting the profile
              bool? confirmDelete = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Profile', style: TextStyle(color: Colors.orange)),
                  content: const Text('Are you sure you want to delete your profile?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    TextButton(
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              );

              if (confirmDelete == true) {
                _deleteProfile(); // Delete profile functionality
              }
            },
            tooltip: 'Delete Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout, // Logout functionality
            tooltip: 'Logout',
          ),
        ],
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

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top user cover photo + profile section
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background Cover Photo
                    GestureDetector(
                      onTap: _uploadCoverPhoto,
                      child: Image.network(
                        userDetails['coverPhotoUrl'] ?? 'https://via.placeholder.com/150',
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: -40,
                      child: GestureDetector(
                        onTap: _uploadProfilePhoto,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(
                            userDetails['profilePhotoUrl'] ?? 'https://via.placeholder.com/80',
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -25,
                      right: 16,
                      child: ElevatedButton(
                        onPressed: () {
                          // Add button logic for follow/unfollow
                        },
                        child: const Text('Follow', style: TextStyle(color: Colors.orange)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                // User info
                Text(
                  userDetails['name'] ?? 'User Name',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  '${userDetails['followers'] ?? 0} Followers | ${userDetails['following'] ?? 0} Following',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                Text(
                  userDetails['bio'] ?? 'No bio available',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                // My pet section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My pet',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: _getUserPets(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          var pets = snapshot.data!.docs;

                          if (pets.isEmpty) {
                            return const Text("No pets found.");
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: pets.length,
                            itemBuilder: (context, index) {
                              var pet = pets[index].data() as Map<String, dynamic>;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                      pet['petPhotoUrl'] ?? 'https://via.placeholder.com/80'),
                                ),
                                title: Text(pet['name']),
                                subtitle: Text(pet['breed']),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Posts section
                DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      TabBar(
                        indicatorColor: Colors.orange,
                        labelColor: Colors.orange,
                        tabs: const [
                          Tab(text: 'Posts'),
                          Tab(text: 'Groups'),
                          Tab(text: 'Events'),
                          Tab(text: 'Photos'),
                        ],
                      ),
                      SizedBox(
                        height: 400,
                        child: TabBarView(
                          children: [
                            // Posts section
                            StreamBuilder<QuerySnapshot>(
                              stream: _getUserPosts(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const CircularProgressIndicator();
                                }

                                var posts = snapshot.data!.docs;

                                if (posts.isEmpty) {
                                  return const Text("No posts found.");
                                }

                                return ListView.builder(
                                  itemCount: posts.length,
                                  itemBuilder: (context, index) {
                                    var post = posts[index].data() as Map<String, dynamic>;
                                    return PostWidget(postData: post);
                                  },
                                );
                              },
                            ),
                            const Center(child: Text('Groups section')),
                            const Center(child: Text('Events section')),
                            const Center(child: Text('Photos section')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PostWidget extends StatelessWidget {
  final Map<String, dynamic> postData;

  const PostWidget({required this.postData, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Icon(postData['profilePhotoUrl'] != null
                  ? Icons.person
                  : Icons.person),
            ),
            title: Text(postData['username'] ?? 'Unknown'),
          ),
          const SizedBox(height: 8),
          Text(postData['content'] ?? 'No content'),
          const SizedBox(height: 8),
          if (postData['images'] != null && postData['images'].isNotEmpty)
            Column(
              children: List<Widget>.from(
                postData['images'].map<Widget>((imageUrl) {
                  return Image.network(imageUrl);
                }),
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.thumb_up_alt_outlined),
                onPressed: () {},
              ),
              Text('${postData['likes'] ?? 0} Likes'),
              IconButton(
                icon: const Icon(Icons.comment),
                onPressed: () {
                  // Handle comment press
                },
              ),
              Text('${postData['comments']?.length ?? 0} Comments'),
            ],
          ),
        ],
      ),
    );
  }
}
