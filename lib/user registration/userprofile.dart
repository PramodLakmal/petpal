import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/Screens/edit_profile_screen.dart';
import 'dart:io';
import '../Screens/newsfeed/news_feed_screen.dart';
import 'package:petpal/user%20registration/login.dart';
import '../Screens/petpalplus/petpal_plus_screen.dart';

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
  if (user == null) {
    // User is not logged in, return an empty stream or handle the case properly
    return const Stream.empty();
  }
  
  return FirebaseFirestore.instance
      .collection('pets')
      .where('userId', isEqualTo: user.uid)
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
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => EditProfileScreen()),
  );
}

  // Function to delete profile
  Future<void> _deleteProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Delete user data from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

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
            return const Center(child: CircularProgressIndicator(color: Colors.orange,));
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
                        userDetails['coverPhotoUrl'] ??
                            'https://via.placeholder.com/150',
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
                                  title: const Text('Delete Profile',
                                      style: TextStyle(color: Colors.orange)),
                                  content: const Text(
                                      'Are you sure you want to delete your profile?'),
                                  actions: [
                                    TextButton(
                                      child: const Text('Cancel',
                                          style: TextStyle(color: Colors.grey)),
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                    ),
                                    TextButton(
                                      child: const Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
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
                            userDetails['profilePhotoUrl'] ??
                                'https://via.placeholder.com/80',
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
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              // Placeholder for follow/unfollow logic
                            },
                            child: const Text('Follow'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.orange, // Text color
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 190),
                // News Feed Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to NewsFeedScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NewsFeedScreen()),
                      );
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.orangeAccent,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Explore News Feed',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Browse lost and found pets in your community',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                  //premium membership section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to PetPalPlusScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PetPalPlusScreen()),
                      );
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors
                          .orangeAccent, 
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Join PetPal Plus',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Unlock premium features ',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                            return const CircularProgressIndicator(color: Colors.orange);
                          }

                          var pets = snapshot.data!.docs;
                          print("Pets data: ${pets.length}");

                          if (pets.isEmpty) {
                            return const Text("No pets found.");
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: pets.length,
                            itemBuilder: (context, index) {
                              var pet = pets[index].data() as Map<String, dynamic>;
                              print("Pet details: $pet"); // Debugging line
                              
                              // Decode the base64 image string if available
                              Uint8List? imageBytes;
                              if (pet['imageBase64'] != null && pet['imageBase64'].isNotEmpty) {
                                try {
                                  imageBytes = base64Decode(pet['imageBase64']);
                                } catch (e) {
                                  print("Error decoding image for pet ${pet['name']}: $e");
                                }
                              }

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: imageBytes != null
                                      ? MemoryImage(imageBytes)  // Use MemoryImage for base64 image
                                      : NetworkImage('https://via.placeholder.com/80'), // Fallback image
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
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        indicatorColor: Colors.orange,
                        labelColor: Colors.orange,
                        tabs: const [
                          Tab(text: 'Posts'),
                          Tab(text: 'Groups'),
                          Tab(text: 'Events'),
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
                                  return const CircularProgressIndicator(color: Colors.orange,);
                                }

                                var posts = snapshot.data!.docs;

                                if (posts.isEmpty) {
                                  return const Text("No posts found.");
                                }

                                return ListView.builder(
                                  itemCount: posts.length,
                                  itemBuilder: (context, index) {
                                    var post = posts[index].data()
                                        as Map<String, dynamic>;
                                    return PostWidget(
                                        postData: post,
                                        postId: posts[index].id);
                                  },
                                );
                              },
                            ),
                            ListView.builder(
                              itemCount: mockGroups.length,
                              itemBuilder: (context, index) {
                                var group = mockGroups[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: group['imageUrl'] != null && group['imageUrl'].isNotEmpty
                                        ? NetworkImage(group['imageUrl'])
                                        : NetworkImage('https://via.placeholder.com/80'),
                                  ),
                                  title: Text(group['name']),
                                  subtitle: Text(group['description']),
                                  trailing: Text("${group['memberCount']} members"),
                                );
                              },
                            ),
                            // Events Tab (Dummy Data)
                            ListView.builder(
                              itemCount: mockEvents.length,
                              itemBuilder: (context, index) {
                                var event = mockEvents[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(event['imageUrl']),
                                  ),
                                  title: Text(event['title']),
                                  subtitle: Text("${event['date']} • ${event['location']}"),
                                );
                              },
                            ),
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

  const PostWidget({required this.postData, required this.postId, Key? key})
      : super(key: key);

  Future<void> _deletePost(BuildContext context) async {
    try {
      // Show confirmation dialog before deleting the post
      bool? confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title:
              const Text('Delete Post', style: TextStyle(color: Colors.orange)),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child:
                  const Text('Delete', style: TextStyle(color: Colors.orange)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      if (confirmDelete == true) {
        // Call the backend logic to delete the post
        await (context.findAncestorStateOfType<_UserProfileState>())
            ?.deletePost(
                postId, postData['images'] ?? []); // Using postId correctly
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Post deleted')));
      }
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to delete post')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Rounded corners
      ),
      elevation: 2, // Slight shadow for depth
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 24.0, // Avatar size
                backgroundImage: postData['userProfilePicture'] != null &&
                        postData['userProfilePicture'].isNotEmpty
                    ? NetworkImage(postData['userProfilePicture'])
                    : NetworkImage('https://www.citypng.com/public/uploads/preview/download-profile-user-round-orange-icon-symbol-png-11639594360ksf6tlhukf.png') as ImageProvider,
              ),
              title: Text(
                postData['username'] ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              subtitle: Row(
                children: const [
                  Text('Golden Retriever • Fayetteville',
                      style: TextStyle(fontSize: 12.0)),
                ],
              ),
              trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.orange),
              onPressed: () => _deletePost(context), // Pass context to _deletePost correctly
              tooltip: 'Delete Post',
            ),

              
            ),
            const SizedBox(height: 8),
            Text(
              postData['content'] ?? 'No content',
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 8),
            if (postData['images'] != null && postData['images'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: postData['images'].map<Widget>((imageUrl) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            height: 250, // Adjust image height
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.thumb_up_alt_outlined),
                      onPressed: () {},
                    ),
                    Text('${postData['likes'] ?? 0} Likes'),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.comment),
                      onPressed: () {
                        // Handle comment press
                      },
                    ),
                    Text('${postData['comments']?.length ?? 0} Comments'),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () {
                        // Handle share press
                      },
                    ),
                    Text('${postData['shares']?.length ?? 0} Shares'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dummy data for groups
final List<Map<String, dynamic>> mockGroups = [
  {
    'name': "Dog's Life",
    'description': 'Dog knowledge sharing and offline exchanges.',
    'memberCount': 548,
    'imageUrl': 'https://th.bing.com/th/id/R.3decdf9501c7b6896087e43f4bb2a123?rik=sFSNimtXCpzMow&riu=http%3a%2f%2f3.bp.blogspot.com%2f-bPjs5rvhy8Q%2fUUGIG79FDqI%2fAAAAAAAAAts%2fQWqMBzROZ44%2fs1600%2fGolden%2bRetriever%2bDog08.jpg&ehk=uSaIvM3ssgGZ99jnzSgHcwtdswBQjCSsGQVLgtjFJIA%3d&risl=&pid=ImgRaw&r=0', // Replace with actual asset path
  },
  {
    'name': "Cat Lovers",
    'description': 'A place for cat enthusiasts.',
    'memberCount': 302,
    'imageUrl': 'https://th.bing.com/th/id/OIP.CiwY4gqtOT4H1dpytV32SQAAAA?w=300&h=300&rs=1&pid=ImgDetMain', // Replace with actual asset path
  },
  {
    'name': "Pet Owners",
    'description': 'General tips and tricks for pet owners.',
    'memberCount': 720,
    'imageUrl': 'https://th.bing.com/th/id/R.422da64b5d4c9753d101857671960901?rik=APlxNPUViFhaBQ&pid=ImgRaw&r=0', // Replace with actual asset path
  },
];

// Dummy data for events
final List<Map<String, dynamic>> mockEvents = [
  {
    'title': "Dog Training Workshop",
    'date': 'October 20, 2024',
    'location': 'Central Park, NYC',
    'imageUrl': 'https://i.pinimg.com/736x/54/db/a7/54dba7bfc7e3f3efdeb9e8f65e112485--air-force--uniform.jpg', // Replace with actual asset path
  },
  {
    'title': "Pet Adoption Fair",
    'date': 'November 5, 2024',
    'location': 'Pet Plaza, LA',
    'imageUrl': 'https://img.freepik.com/premium-photo/furry-friends-strike-pose-dogs-cats-capturing-pawsome-selfie-white-background_983420-23964.jpg?w=2000', // Replace with actual asset path
  },
  {
    'title': "Annual Pet Expo",
    'date': 'December 12, 2024',
    'location': 'Expo Center, San Francisco',
    'imageUrl': 'https://th.bing.com/th/id/OIP.E9yvXTMYr9WMMlyTe_muaQHaE7?w=626&h=417&rs=1&pid=ImgDetMain', // Replace with actual asset path
  },
];

