import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Completed extends StatefulWidget {
  final String petId;

  const Completed({super.key, required this.petId});

  @override
  State<Completed> createState() => _CompletedState();
}

class _CompletedState extends State<Completed> {
  // List to store completed vaccines
  List<Map<String, dynamic>> completedVaccines = [];
  List<Map<String, dynamic>> filteredVaccines =
      []; // To store filtered vaccines
  String searchQuery = ''; // To store the search query

  @override
  void initState() {
    super.initState();
    _fetchCompletedVaccines(); // Fetch completed vaccines when the screen loads
  }

  // Function to fetch completed vaccines based on petId and status
  Future<void> _fetchCompletedVaccines() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('petvaccines')
          .where('petId', isEqualTo: widget.petId)
          .where('status',
              isEqualTo:
                  'vaccined') // Only fetch vaccines with status 'vaccined'
          .get();

      setState(() {
        completedVaccines = snapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'id':
                      doc.id // Include the document ID for potential future use
                })
            .toList();
        filteredVaccines = completedVaccines; // Initialize filteredVaccines
      });
    } catch (e) {
      print('Failed to fetch completed vaccines: $e');
    }
  }

  // Function to filter vaccines based on search query
  void _filterVaccines(String query) {
    setState(() {
      searchQuery = query
          .toLowerCase(); // Convert to lowercase for case insensitive search
      filteredVaccines = completedVaccines.where((vaccine) {
        return vaccine['vaccineName']
                .toLowerCase()
                .contains(searchQuery) || // Match vaccine name
            vaccine['date'].toLowerCase().contains(searchQuery); // Match date
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 112.0,
        title: const Text(
          'Completed Vaccines',
          style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color(0xFFFA6650),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar for filtering vaccines
            TextField(
              onChanged: _filterVaccines,
              decoration: InputDecoration(
                labelText: 'Search Vaccines',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.green),
                ),
              ),
            ),
            const SizedBox(height: 16.0), // Space between search bar and list
            Expanded(
              child: filteredVaccines.isEmpty
                  ? const Center(
                      child:
                          CircularProgressIndicator()) // Show loading spinner while fetching data
                  : ListView.builder(
                      itemCount: filteredVaccines.length,
                      itemBuilder: (context, index) {
                        final vaccine = filteredVaccines[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              // Optionally, handle tap on the card
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(
                                        0, 3), // changes position of shadow
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  vaccine['vaccineName'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green,
                                  ),
                                ),
                                subtitle: Text(
                                  'Date: ${vaccine['date']}\nVenue: ${vaccine['venue']}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: const Icon(Icons.check_circle,
                                    color: Colors.green, size: 30),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
