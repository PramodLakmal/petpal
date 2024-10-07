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
        // Ordering by timestamp
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccine History'),
        backgroundColor: Colors.purple,
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

          return ListView.builder(
            itemCount: vaccines.length,
            itemBuilder: (context, index) {
              var vaccine = vaccines[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vaccine['vaccineName'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 5),
                          Text(vaccine['date'] ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 5),
                          Text(vaccine['time'] ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 5),
                          Text(vaccine['venue'] ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        vaccine['description'] ?? 'No description provided.',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            vaccine['status'] ?? 'N/A',
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
