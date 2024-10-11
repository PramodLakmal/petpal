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

  // Function to show the description in a dialog
  void _showDescriptionDialog(String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vaccine Description'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(description),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
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
          'Upcoming Vaccine',
          style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add the clinic image at the start of the body
            SizedBox(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'images/clinic.jpg', // Path to your image
                  width: double.infinity, // Set the width of the image
                  height: 200, // Set the height of the image
                ),
              ),
            ),
            const SizedBox(height: 16), // Add some space after the image
            upcomingVaccines.isEmpty
                ? const Center(
                    child: Text(
                      "Your pet's health is up to date!",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: upcomingVaccines.length,
                      itemBuilder: (context, index) {
                        final vaccine = upcomingVaccines[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                                      0, 3), // changes position of shadow
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Heading "Vaccine Info"
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Vaccine Info',
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.medical_services,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Vaccine Name: ${vaccine['vaccineName']}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Date: ${vaccine['date']}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Time: ${vaccine['time']}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Venue: ${vaccine['venue']}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.description,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Description:',
                                            style: TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon:
                                                const Icon(Icons.arrow_forward),
                                            onPressed: () =>
                                                _showDescriptionDialog(
                                                    vaccine['description'] ??
                                                        ''),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                                // Check button to update vaccine status
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () =>
                                          _updateVaccineStatus(vaccine['id']),
                                      child: const Text(
                                        'Mark as Vaccinated',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 18),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
