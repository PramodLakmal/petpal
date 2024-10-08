import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Screens/newsfeed/news_feed_screen.dart';

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

// Function to delete a post
Future<void> deletePost(String postId, List<dynamic> imageUrls) async {
  try {
    // Get current user
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    // 1. Delete images associated with the post from Firebase Storage
    if (imageUrls.isNotEmpty) {
      for (String imageUrl in imageUrls) {
        // Extract the file path from the image URL
        Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
        await storageRef.delete(); // Delete the image from Firebase Storage
      }
    }

    // 2. Delete the post document from Firestore
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

    print("Post deleted successfully");
  } catch (e) {
    print('Error deleting post: $e');
    throw Exception('Failed to delete post');
  }
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  // Edit, delete, logout icons moved to top-right corner
                  Positioned(
                    top: 20,
                    right: 16,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: _editProfile,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () async {
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
                              _deleteProfile();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: _logout,
                        ),
                      ],
                    ),
                  ),
                  // Profile photo positioned bottom-left corner over cover photo
                  Positioned(
                    right: 16,
                    bottom: -60,
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
                  
                  // Name, followers, bio moved to bottom-left corner
                  Positioned(
                    bottom: -170,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userDetails['name'] ?? 'User Name',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${userDetails['followers'] ?? 0} Followers | ${userDetails['following'] ?? 0} Following',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          userDetails['bio'] ?? 'No bio available',
                          style: const TextStyle(fontSize: 14, color: Colors.black),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            // Placeholder for follow/unfollow logic
                          },
                          child: const Text('Follow'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, backgroundColor: Colors.orange, // Text color
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 190),
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
                                  return PostWidget(postData: post, postId: posts[index].id);
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
  final String postId; // Post ID is needed to delete the specific post

  const PostWidget({required this.postData, required this.postId, Key? key}) : super(key: key);

  Future<void> _deletePost(BuildContext context) async {
    try {
      // Show confirmation dialog before deleting the post
      bool? confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Post', style: TextStyle(color: Colors.orange)),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.orange)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      if (confirmDelete == true) {
        // Call the backend logic to delete the post
        await (context.findAncestorStateOfType<_UserProfileState>())?.deletePost(postId, postData['images'] ?? []); // Using postId correctly
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
      }
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete post')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Icon(postData['profilePhotoUrl'] != null ? Icons.person : Icons.person),
            ),
            title: Text(postData['username'] ?? 'Unknown'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.orange),
              onPressed: () => _deletePost(context), // Pass context to _deletePost correctly
              tooltip: 'Delete Post',
            ),
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