import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class History extends StatefulWidget {
  final String petId;

  const History({Key? key, required this.petId}) : super(key: key);

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  @override
  Widget build(BuildContext context) {
    // Querying petvaccines collection with petId filter
    Stream<QuerySnapshot> _vaccinesStream = FirebaseFirestore.instance
        .collection('petvaccines')
        .where('petId', isEqualTo: widget.petId)
        // Order by timestamp for recent entries
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: const Text(
          'Vaccine History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        )),
        backgroundColor: Color(0xFFFA6650),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _vaccinesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No vaccine history found.'));
          }

          var vaccines = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView.builder(
              itemCount: vaccines.length,
              itemBuilder: (context, index) {
                var vaccine = vaccines[index].data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vaccine['vaccineName'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                            Icons.calendar_today, vaccine['date'] ?? 'N/A'),
                        _buildInfoRow(
                            Icons.access_time, vaccine['time'] ?? 'N/A'),
                        _buildInfoRow(
                            Icons.location_on, vaccine['venue'] ?? 'N/A'),
                        const SizedBox(height: 10),
                        Text(
                          vaccine['description'] ?? 'No description provided.',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        _buildStatusChip(vaccine['status'] ?? 'N/A'),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String info) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Color(0xFFFA6650)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            info,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    if (status == 'completed') {
      chipColor = Colors.green;
    } else if (status == 'pending') {
      chipColor = Colors.orange;
    } else {
      chipColor = Colors.red; // For unknown or error status
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
