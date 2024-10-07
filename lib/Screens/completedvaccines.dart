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
          .where('status', isEqualTo: 'vaccined') // Only fetch vaccines with status 'vaccined'
          .get();

      setState(() {
        completedVaccines = snapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id // Include the document ID for potential future use
                })
            .toList();
      });
    } catch (e) {
      print('Failed to fetch completed vaccines: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Vaccines'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: completedVaccines.isEmpty
            ? const Center(child: CircularProgressIndicator()) // Show loading spinner while fetching data
            : ListView.builder(
                itemCount: completedVaccines.length,
                itemBuilder: (context, index) {
                  final vaccine = completedVaccines[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(vaccine['vaccineName']),
                      subtitle: Text('Date: ${vaccine['date']}\nVenue: ${vaccine['venue']}'),
                      trailing: const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
