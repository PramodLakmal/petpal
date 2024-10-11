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
          .toLowerCase(); // Convert to lowercase for case-insensitive search
      filteredVaccines = completedVaccines.where((vaccine) {
        return vaccine['vaccineName']
                .toLowerCase()
                .contains(searchQuery) || // Match vaccine name
            vaccine['date'].toLowerCase().contains(searchQuery); // Match date
      }).toList();
    });
  }

  // Function to show a pop-up dialog with vaccine details
  void _showVaccineDetailsDialog(Map<String, dynamic> vaccine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vaccine Name
                Row(
                  children: [
                    const Icon(Icons.vaccines, color: Colors.green, size: 30),
                    const SizedBox(width: 8),
                    Text(
                      vaccine['vaccineName'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date and Time
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Date: ${vaccine['date']}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Time: ${vaccine['time'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Venue
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Venue: ${vaccine['venue']}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Row(
                  children: [
                    const Icon(Icons.description,
                        color: Colors.purple, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vaccine['description'] ?? 'No description available',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Close button
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 112.0,
        centerTitle: true,
        title: const Text(
          'Vaccination History',
          style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
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
                              _showVaccineDetailsDialog(
                                  vaccine); // Show pop-up on tap
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(
                                        0, 3), // Changes position of shadow
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
                                    color: Color(0xFFFA6650),
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
