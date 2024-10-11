import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import the intl package for DateFormat

class AppointmentDetailsPage extends StatelessWidget {
  final QueryDocumentSnapshot appointment;

  AppointmentDetailsPage({required this.appointment});

  // Method to fetch doctor details using doctorId
  Future<DocumentSnapshot> _getDoctorDetails(String doctorId) async {
    return await FirebaseFirestore.instance.collection('doctors').doc(doctorId).get();
  }

  @override
  Widget build(BuildContext context) {
    String doctorId = appointment['doctorId']; // Get the doctorId from appointment
    String appointmentTime = appointment['appointmentTime'];
    String petBreed = appointment['petBreed'];
    String location = appointment['location'];
    String payment = appointment['payment'];
    String petWeight = appointment['petWeight'];
    Timestamp appointmentDate = appointment['appointmentDate'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Appointment Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _getDoctorDetails(doctorId), // Fetch doctor details
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Error fetching doctor details'));
          }

          // Get the doctor's details from the snapshot
          var doctorData = snapshot.data!.data() as Map<String, dynamic>;
          String doctorName = doctorData['name'];
          String doctorPhoto = doctorData['doctorPhoto'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display doctor's photo and name
                Row(
                  children: [
                    Container(
                      width: 120,  // Set the width of the image
                      height: 150, // Set the height of the image
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(doctorPhoto), // Doctor's photo from Firestore
                          fit: BoxFit.cover, // Cover the entire container
                        ),
                        borderRadius: BorderRadius.zero, // Ensure no rounded corners
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Dr. $doctorName',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text('Appointment Date: ${formatDate(appointmentDate)}', style: TextStyle(fontSize: 18)),
                Text('Appointment Time: $appointmentTime', style: TextStyle(fontSize: 18)),
                SizedBox(height: 16),
                Text('Pet Breed: $petBreed', style: TextStyle(fontSize: 18)),
                Text('Pet Weight: $petWeight kg', style: TextStyle(fontSize: 18)),
                Text('Location: $location', style: TextStyle(fontSize: 18)),
                SizedBox(height: 16),
                Text('Payment: LKR $payment', style: TextStyle(fontSize: 18)),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to format Date
  String formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat.yMMMMd().format(date);
  }
}
