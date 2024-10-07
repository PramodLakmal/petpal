import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petpal/admin%20side/adminScreens/VaccineScreen.dart';
import 'package:petpal/admin%20side/adminScreens/vaccineHistory.dart';

// Assuming you have a UserPetsScreen to view a user's pets
// Replace this with your actual implementation

class UserPetsScreen extends StatelessWidget {
  final String userId;

  const UserPetsScreen({Key? key, required this.userId}) : super(key: key);

  // Function to display vaccine details in a dialog
 

  @override
  Widget build(BuildContext context) {
    // Reference to the pets collection filtered by userId
    Stream<QuerySnapshot> _petsStream = FirebaseFirestore.instance
        .collection('pets')
        .where('userId', isEqualTo: userId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Pets'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _petsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // While waiting for data, show a loading indicator
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // If no data is found, display a message
            return const Center(child: Text('No pets found for this user.'));
          }

          var pets = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Enable horizontal scrolling
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical, // Enable vertical scrolling
              child: DataTable(
                columns: const [
                  DataColumn(
                    label: Text(
                      'Pet Name',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Age',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Breed',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Gender',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Weight',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Vaccines',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Vaccine History',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
                rows: pets.map((petDoc) {
                  var petData = petDoc.data() as Map<String, dynamic>;

                  return DataRow(
                    cells: [
                      DataCell(Text(petData['name'] ?? 'N/A')),
                      DataCell(Text(petData['age']?.toString() ?? 'N/A')),
                      DataCell(Text(petData['breed'] ?? 'N/A')),
                      DataCell(Text(petData['gender'] ?? 'N/A')),
                      DataCell(Text(petData['weight']?.toString() ?? 'N/A')),
                      DataCell(
                        ElevatedButton(
                          onPressed: () {

                            String  petId = petData['petId'] ?? petDoc.id;
                            // Assuming 'vaccines' is a list of vaccine names
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Vaccinescreen(
                                  petId: petId,
                                  
                                  
                                ),
                              ),
                            );
                          },
                          child: const Text('Vaccines'),
                        ),
                      ),
                        DataCell(
                        ElevatedButton(
                          onPressed: () {

                            String  petId = petData['petId'] ?? petDoc.id;
                            // Assuming 'vaccines' is a list of vaccine names
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => History(
                                  petId: petId,
                                  
                                  
                                ),
                              ),
                            );
                          },
                          child: const Text('View'),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                // Optional: Add sorting functionality
                sortAscending: true,
                sortColumnIndex: 0,
              ),
            ),
          );
        },
      ),
    );
  }
}

class Usermanagement extends StatefulWidget {
  const Usermanagement({super.key});

  @override
  State<Usermanagement> createState() => _UsermanagementState();
}

class _UsermanagementState extends State<Usermanagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to delete user data from Firestore
  Future<void> _deleteUser(String userId) async {
    try {
      // Delete pets associated with the user
      var petsSnapshot = await _firestore
          .collection('pets')
          .where('userId', isEqualTo: userId)
          .get();

      for (var pet in petsSnapshot.docs) {
        await pet.reference.delete();
      }

      // Delete user from the 'users' collection
      await _firestore.collection('users').doc(userId).delete();

      // Optionally, delete the user account from Firebase Auth
      // Note: This requires admin privileges and cannot be done securely from the client.
      // You might need to set up a Cloud Function to handle this.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    }
  }

  // Function to show a confirmation dialog before deletion
  Future<void> _confirmDelete(String userId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
              'Are you sure you want to delete this user? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel deletion
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm deletion
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteUser(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('isUser', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          var users = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Address')),
                DataColumn(label: Text('Mobile Number')),
                DataColumn(label: Text('Pets')),
                DataColumn(label: Text('Delete')),
              ],
              rows: users.map((userDoc) {
                var userData = userDoc.data() as Map<String, dynamic>;
                return DataRow(cells: [
                  DataCell(Text(userData['name'] ?? 'N/A')),
                  DataCell(Text(userData['email'] ?? 'N/A')),
                  DataCell(Text(userData['address'] ?? 'N/A')),
                  DataCell(Text(userData['phone'] ?? 'N/A')),
                  DataCell(
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UserPetsScreen(userId: userDoc.id),
                          ),
                        );
                      },
                      child: const Text('View Pets'),
                    ),
                  ),
                  DataCell(
                    ElevatedButton(
                      onPressed: () {
                        _confirmDelete(userDoc.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
