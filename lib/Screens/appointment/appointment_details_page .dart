import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppointmentDetailsPage extends StatelessWidget {
  final QueryDocumentSnapshot appointment;

  AppointmentDetailsPage({required this.appointment});

  Future<DocumentSnapshot> _getDoctorDetails(String doctorId) async {
    return await FirebaseFirestore.instance.collection('doctors').doc(doctorId).get();
  }

  @override
  Widget build(BuildContext context) {
    String doctorId = appointment['doctorId'];
    String appointmentTime = appointment['appointmentTime'];
    String petBreed = appointment['petBreed'];
    String location = appointment['location'];
    String payment = appointment['payment'];
    String petWeight = appointment['petWeight'];
    Timestamp appointmentDate = appointment['appointmentDate'];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Appointment Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _getDoctorDetails(doctorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Error fetching doctor details'));
          }

          var doctorData = snapshot.data!.data() as Map<String, dynamic>;
          String doctorName = doctorData['name'];
          String doctorPhoto = doctorData['doctorPhoto'];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Card
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          doctorPhoto,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Dr. $doctorName',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Appointment Details Card
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildDetailTile(
                        icon: Icons.calendar_today,
                        title: 'Date',
                        value: formatDate(appointmentDate),
                      ),
                      _buildDivider(),
                      _buildDetailTile(
                        icon: Icons.access_time,
                        title: 'Time',
                        value: appointmentTime,
                      ),
                      _buildDivider(),
                      _buildDetailTile(
                        icon: Icons.pets,
                        title: 'Pet Breed',
                        value: petBreed,
                      ),
                      _buildDivider(),
                      _buildDetailTile(
                        icon: Icons.monitor_weight,
                        title: 'Pet Weight',
                        value: '$petWeight kg',
                      ),
                      _buildDivider(),
                      _buildDetailTile(
                        icon: Icons.location_on,
                        title: 'Location',
                        value: location,
                      ),
                      _buildDivider(),
                      _buildDetailTile(
                        icon: Icons.payment,
                        title: 'Payment',
                        value: 'LKR $payment',
                        valueColor: Colors.blue,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.orange, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[200],
      indent: 16,
      endIndent: 16,
    );
  }

  String formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat.yMMMMd().format(date);
  }
}