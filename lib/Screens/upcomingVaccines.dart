import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UpcomingVaccines extends StatefulWidget {
  final String petId; // Accept petId as a parameter

  const UpcomingVaccines({super.key, required this.petId});

  @override
  State<UpcomingVaccines> createState() => _UpcomingVaccinesState();
}

class _UpcomingVaccinesState extends State<UpcomingVaccines> {
  // List to store upcoming vaccines
  List<Map<String, dynamic>> upcomingVaccines = [];

  @override
  void initState() {
    super.initState();
    _fetchUpcomingVaccines(); // Fetch upcoming vaccines when the screen loads
  }

  // Function to fetch upcoming vaccines based on petId and status
  Future<void> _fetchUpcomingVaccines() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('petvaccines')
          .where('petId', isEqualTo: widget.petId)
          .where('status',
              isEqualTo: 'pending') // Only fetch vaccines with status 'pending'
          .get();

      setState(() {
        upcomingVaccines = snapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id // Include the document ID for updating
                })
            .toList();
      });
    } catch (e) {
      print('Failed to fetch upcoming vaccines: $e');
    }
  }

  // Function to update the vaccine status
  Future<void> _updateVaccineStatus(String vaccineId) async {
    try {
      await FirebaseFirestore.instance
          .collection('petvaccines')
          .doc(vaccineId)
          .update({'status': 'vaccined'}); // Update status to 'vaccined'

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vaccine status updated to vaccinated!')),
      );

      // Refresh the vaccine list
      _fetchUpcomingVaccines();
    } catch (e) {
      print('Failed to update vaccine status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating vaccine status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Vaccines'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: upcomingVaccines.isEmpty
            ? const Center(
                child:
                    CircularProgressIndicator()) // Show loading spinner while fetching data
            : ListView.builder(
                itemCount: upcomingVaccines.length,
                itemBuilder: (context, index) {
                  final vaccine = upcomingVaccines[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(vaccine['vaccineName']),
                      subtitle: Text('Scheduled Date: ${vaccine['date']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline,
                                color: Colors.green),
                            onPressed: () =>
                                _updateVaccineStatus(vaccine['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
