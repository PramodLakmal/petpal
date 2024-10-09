import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting the date

class AppointmentHistoryPage extends StatefulWidget {
  @override
  _AppointmentHistoryPageState createState() => _AppointmentHistoryPageState();
}

class _AppointmentHistoryPageState extends State<AppointmentHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // Method to fetch appointments from Firestore
  Stream<QuerySnapshot> _getAppointments(String status) {
    try {
      return FirebaseFirestore.instance
          .collection('appointments')
          .where('status', isEqualTo: status)
          .orderBy('appointmentDate', descending: false)
          .snapshots();
    } catch (e) {
      print('Error fetching appointments: $e');
      rethrow; // Rethrow the error for StreamBuilder to handle
    }
  }

  // Method to format Date
  String formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat.yMMMMd().format(date); // e.g., October 12, 2024
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Upcoming Appointments
          _buildAppointmentList('pending'),

          // Completed Appointments
          _buildAppointmentList('completed'),

          // Cancelled Appointments
          _buildAppointmentList('cancelled'),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getAppointments(status),
      builder: (context, snapshot) {
        // Handle if the connection is waiting or an error occurred
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error fetching data: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No appointments found'));
        }

        // Build a list of appointment cards
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var appointment = snapshot.data!.docs[index];
            return _buildAppointmentCard(appointment);
          },
        );
      },
    );
  }

  // Method to build individual appointment card
  Widget _buildAppointmentCard(QueryDocumentSnapshot appointment) {
    String doctorName = appointment['doctorName'];
    String appointmentTime = appointment['appointmentTime'];
    String petBreed = appointment['petBreed'];
    String payment = appointment['payment'];
    Timestamp appointmentDate = appointment['appointmentDate'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dr. $doctorName', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Pet: $petBreed'),
            Text('Appointment Time: $appointmentTime'),
            Text('Appointment Date: ${formatDate(appointmentDate)}'),
            Text('Payment: LKR $payment'),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (appointment['status'] == 'pending')
                  IconButton(
                    icon: Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      _cancelAppointment(appointment.id);
                    },
                  ),
                if (appointment['status'] == 'pending')
                  IconButton(
                    icon: Icon(Icons.done, color: Colors.green),
                    onPressed: () {
                      _completeAppointment(appointment.id);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Method to mark an appointment as completed
  void _completeAppointment(String appointmentId) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'status': 'completed',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment marked as completed')),
      );
    } catch (e) {
      print('Error updating appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark appointment as completed')),
      );
    }
  }

  // Method to cancel an appointment
  void _cancelAppointment(String appointmentId) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment cancelled')),
      );
    } catch (e) {
      print('Error cancelling appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel appointment')),
      );
    }
  }
}
