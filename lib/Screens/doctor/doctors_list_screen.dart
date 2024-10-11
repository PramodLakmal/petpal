import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../doctor/chat_screen.dart';
import '../petpalplus/petpal_plus_screen.dart';

class DoctorsListScreen extends StatelessWidget {
  const DoctorsListScreen({Key? key}) : super(key: key);

  Future<bool> _isPremiumMember() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // Get premium membership status from the 'premium_memberships' collection
      var snapshot = await FirebaseFirestore.instance
          .collection('premium_memberships')
          .doc(user.uid)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        // Check if the membershipStatus is 'active'
        return snapshot.data()!['membershipStatus'] == 'active';
      }
    } catch (e) {
      print('Error checking premium membership: $e');
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Doctors'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('temp_d').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No doctors available at the moment.'));
          }

          var doctors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              var doctorData = doctors[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      doctorData['photoUrl'] ?? 'https://via.placeholder.com/150',
                    ),
                    radius: 30,
                  ),
                  title: Text(doctorData['name'] ?? 'Doctor Name'),
                  subtitle: Text(doctorData['specialization'] ?? 'Specialization'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      bool isPremium = await _isPremiumMember();

                      if (isPremium) {
                        // User is a premium member, navigate to the chat screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(doctorId: doctors[index].id),
                          ),
                        );
                      } else {
                        // User is not a premium member, show alert and navigate to PetPal Plus screen
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Premium Feature'),
                            content: Text(
                                'You discovered a premium feature! Subscribe to PetPal Plus to chat with doctors.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PetPalPlusScreen(),
                                    ),
                                  );
                                },
                                child: Text('Go to PetPal Plus'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Chat button color
                    ),
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