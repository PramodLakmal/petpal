import 'dart:convert';
import 'dart:math';
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
  List<DocumentSnapshot> _randomPets = [];
  bool _isSearching = false;
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    _loadRandomPets();
  }

  Future<void> _loadRandomPets() async {
    try {
      QuerySnapshot querySnapshot = await _adoptionCollection.get();
      List<DocumentSnapshot> allPets = querySnapshot.docs;

      if (allPets.length <= 5) {
        setState(() {
          _randomPets = allPets;
          _isLoadingInitial = false;
        });
        return;
      }

      // Randomly select 5 pets
      Random random = Random();
      List<DocumentSnapshot> randomSelection = [];
      List<int> usedIndices = [];

      while (randomSelection.length < 5) {
        int index = random.nextInt(allPets.length);
        if (!usedIndices.contains(index)) {
          usedIndices.add(index);
          randomSelection.add(allPets[index]);
        }
      }

      setState(() {
        _randomPets = randomSelection;
        _isLoadingInitial = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingInitial = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading pets: $e')),
      );
    }
  }

  void _searchPosts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
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

      setState(() {
        _searchResults = [...querySnapshot.docs, ...breedSnapshot.docs];
        _searchResults = _searchResults.toSet().toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching posts: $e')),
      );
    }
  }

  void _navigateToDetails(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchAdoptionPostDetails(postId: postId),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pets For Adoption"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for Pet',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.mic),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: _searchPosts,
            ),
          ),
          Expanded(
            child: _isLoadingInitial
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _searchResults.isEmpty
                        ? _randomPets.length
                        : _searchResults.length,
                    itemBuilder: (context, index) {
                      final post = (_searchResults.isEmpty
                              ? _randomPets
                              : _searchResults)[index]
                          .data() as Map<String, dynamic>;
                      final postId = (_searchResults.isEmpty
                              ? _randomPets
                              : _searchResults)[index]
                          .id;
                      return _buildPetCard(post, postId);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> post, String postId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: .2, vertical: 8), // Reduced horizontal margin
      height: 150,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image section
          Container(
            width: 130, // Increased width for the image
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: post['imageBase64'] != null
                  ? DecorationImage(
                      image: MemoryImage(base64Decode(post['imageBase64'])),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: post['imageBase64'] == null
                ? const Center(child: Icon(Icons.pets, size: 40))
                : null,
          ),
          // Content section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16), // Increased padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space evenly
                children: [
                  // Top section with breed and favorite icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          post['breed'] ?? 'Unknown Breed',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  // Middle section with age and gender
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      Text(
                        '${post['age'] ?? 'Unknown'} Years',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        post['gender'] == 'Male' ? Icons.male : Icons.female,
                        size: 16,
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post['gender'] ?? 'Unknown',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  // Add spacing between text and button
                  const Spacer(), // Push the button to the bottom
                  // Adopt Button (smaller and properly aligned at the bottom)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToDetails(postId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(255, 152, 0, 1), // Button background color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Rounded corners
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16), // Smaller button size
                      ),
                      icon: const Icon(Icons.pets, size: 18), // Smaller icon
                      label: const Text(
                        'Adopt',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
