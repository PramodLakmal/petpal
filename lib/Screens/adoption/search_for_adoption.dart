import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/Screens/adoption/search_adoption_post_details.dart';

class SearchForAdoption extends StatefulWidget {
  const SearchForAdoption({super.key});

  @override
  _SearchForAdoptionState createState() => _SearchForAdoptionState();
}

class _SearchForAdoptionState extends State<SearchForAdoption> {
  final TextEditingController _searchController = TextEditingController();
  final CollectionReference _adoptionCollection =
      FirebaseFirestore.instance.collection('adoption');

  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;

  void _searchPosts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true; // Start searching
    });

    try {
      // Perform a case-insensitive search in Firestore
      QuerySnapshot querySnapshot = await _adoptionCollection
          .where('name', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('name', isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
          .orderBy('name')
          .get();

      QuerySnapshot breedSnapshot = await _adoptionCollection
          .where('breed', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('breed', isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
          .orderBy('breed')
          .get();

      // Combine both name and breed results
      setState(() {
        _searchResults = [...querySnapshot.docs, ...breedSnapshot.docs]; // Update search results
        _searchResults = _searchResults.toSet().toList(); // Remove duplicates
        _isSearching = false; // Stop searching
      });
    } catch (e) {
      setState(() {
        _isSearching = false; // Stop searching on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching posts: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose the controller to free resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search for Adoption"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Pet Name or Breed',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _searchPosts(_searchController.text.trim());
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: _searchPosts, // Trigger search on submit
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? const Center(child: Text('No matching posts found.'))
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final post = _searchResults[index].data() as Map<String, dynamic>;
                            final postId = _searchResults[index].id;

                            return _buildPostCard(post, postId); // Build each post card
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildPostCard(Map<String, dynamic> post, String postId) {
    return GestureDetector(
      onTap: () {
        // Navigate to the details page for the searched post
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchAdoptionPostDetails(postId: postId), // Pass postId to the new details page
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Display the pet's photo
              ClipOval(
                child: post['imageBase64'] != null 
                  ? Image.memory(
                      base64Decode(post['imageBase64']), // Convert Base64 to image
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.pets, size: 60), // Placeholder icon
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
                    Text('Age: ${post['age'] ?? 'N/A'} years'), // Default value if null
                    Text('Weight: ${post['weight'] ?? 'N/A'} kg'), // Default value if null
                    Text('Breed: ${post['breed'] ?? 'N/A'}'), // Display the breed
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
