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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Find Pets For Adoption",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(.5),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for Pet',
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  suffixIcon: const Icon(Icons.mic, color: Colors.orange),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onChanged: _searchPosts,
              ),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 130,
            height: 150,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              image: post['imageBase64'] != null
                  ? DecorationImage(
                      image: MemoryImage(base64Decode(post['imageBase64'])),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: post['imageBase64'] == null
                ? const Center(child: Icon(Icons.pets))
                : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        post['breed'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${post['age'] ?? 'Unknown'} years',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    post['gender'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => _navigateToDetails(postId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Adopt',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
    );
  }
}