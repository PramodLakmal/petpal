import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchAdoptionPostDetails extends StatelessWidget {
  final String postId;

  const SearchAdoptionPostDetails({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DocumentReference postRef = FirebaseFirestore.instance.collection('adoption').doc(postId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoption Post Details'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: postRef.get(), // Get the document snapshot from Firestore
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: post['imageBase64'] != null
                      ? Image.memory(
                          base64Decode(post['imageBase64']), // Convert Base64 to image
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.pets, size: 120), // Placeholder icon
                ),
                const SizedBox(height: 20),
                Text(
                  post['name'] ?? 'Unnamed Pet',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('Age: ${post['age'] ?? 'N/A'} years', style: const TextStyle(fontSize: 18)),
                Text('Weight: ${post['weight'] ?? 'N/A'} kg', style: const TextStyle(fontSize: 18)),
                Text('Breed: ${post['breed'] ?? 'N/A'}', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                const Text('Description:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(
                  post['description'] ?? 'No description available.',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
