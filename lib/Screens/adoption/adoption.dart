import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth to get the current user
import 'package:flutter/material.dart';
import 'package:petpal/Screens/adoption/adoption_details.dart';
import 'package:petpal/Screens/adoption/create_adoption_post.dart';
import 'package:petpal/Screens/adoption/search_for_adoption.dart'; // Import the SearchForAdoption page

class AdoptionPage extends StatefulWidget {
  const AdoptionPage({super.key});

  @override
  _AdoptionPageState createState() => _AdoptionPageState();
}

class _AdoptionPageState extends State<AdoptionPage> {
  // Firestore collection reference
  final CollectionReference _adoptionCollection =
      FirebaseFirestore.instance.collection('adoption');

  // Get the current user's UID
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: const Text(
          "Adoption Posts",
          style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Top section with search button moved here
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Find Pets For Adoption',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.navigate_next,
                    size: 35,
                  ),
                  onPressed: () {
                    // Navigate to the search for adoption page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const SearchForAdoption()), // Navigate to search page
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 2, thickness: 2), // Divider between sections

          // Add "My Posts Section" heading
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Posts Section',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // My Adoption Posts section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _adoptionCollection
                  .where('userId',
                      isEqualTo:
                          _currentUserId) // Filter posts by logged-in user
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final posts = snapshot.data?.docs;

                if (posts == null || posts.isEmpty) {
                  return const Center(
                      child: Text('No adoption posts available.'));
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index].data() as Map<String, dynamic>;
                    return _buildPostCard(
                        post, posts[index].id); // Pass post and postId
                  },
                );
              },
            ),
          ),

          // "Create Post" button moved here
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Navigate to the page to create an adoption post
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateAdoptionPost()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'Create Post',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, String postId) {
    return GestureDetector(
      onTap: () {
        // Navigate to the details page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AdoptionPostDetails(postId: postId), // Pass postId
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(6),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Display the pet's photo with rounded corners
              ClipRRect(
                borderRadius: BorderRadius.circular(
                    8), // Adjust the value for more or less rounding
                child: SizedBox(
                  width: 130, // Set the width of the image
                  height: 150, // Set the height of the image
                  child: post['imageBase64'] != null
                      ? Image.memory(
                          base64Decode(
                              post['imageBase64']), // Convert Base64 to image
                          fit: BoxFit.cover, // Cover the entire container
                        )
                      : const Icon(Icons.pets, size: 60), // Placeholder icon
                ),
              ),
              const SizedBox(width: 10),
              // Display pet details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['name'] ?? 'Unnamed Pet', // Default value if null
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                        'Age: ${post['age'] ?? 'N/A'} years'), // Default value if null
                    Text(
                        'Weight: ${post['weight'] ?? 'N/A'} kg'), // Default value if null
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
