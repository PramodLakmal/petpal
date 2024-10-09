import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Required for base64 decoding
import 'package:petpal/Screens/adoption/update_adoption_post.dart'; // Import the update page

class AdoptionPostDetails extends StatelessWidget {
  final String postId;

  const AdoptionPostDetails({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fetch the post details from Firestore
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoption Post Details'),
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to the update page with the postId
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UpdateAdoptionPost(postId: postId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('adoption').doc(postId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Post not found.'));
          }

          final post = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipOval(
                    child: post['imageBase64'] != null 
                      ? Image.memory(
                          base64Decode(post['imageBase64']), // Convert Base64 to image
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.pets, size: 120), // Placeholder icon
                  ),
                ),
                const SizedBox(height: 16),
                Text('Name: ${post['name'] ?? 'Unnamed Pet'}', style: const TextStyle(fontSize: 20)),
                Text('Age: ${post['age'] ?? 'N/A'} years'),
                Text('Breed: ${post['breed'] ?? 'Unknown'}'),
                Text('Weight: ${post['weight'] ?? 'N/A'} kg'),
                Text('Gender: ${post['gender'] ?? 'N/A'}'),
                const SizedBox(height: 16),
                Text('Description:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(post['description'] ?? 'No description available.'),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Delete the post from Firestore
                await FirebaseFirestore.instance.collection('adoption').doc(postId).delete();
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the previous screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted successfully.')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
