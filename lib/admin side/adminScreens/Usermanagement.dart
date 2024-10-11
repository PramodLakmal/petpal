import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petpal/admin%20side/adminScreens/VaccineScreen.dart';
import 'package:petpal/admin%20side/adminScreens/vaccineHistory.dart';
import 'package:petpal/admin%20side/admin_login.dart';

// UserPetsScreen to view a user's pets
class UserPetsScreen extends StatelessWidget {
  final String userId;

  const UserPetsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Reference to the pets collection filtered by userId
    Stream<QuerySnapshot> _petsStream = FirebaseFirestore.instance
        .collection('pets')
        .where('userId', isEqualTo: userId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: const Text(
          'User Pets',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        )),
        backgroundColor: Color(0xFFFA6650),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _petsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pets found for this user.'));
          }

          var pets = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Center(
              child: DataTable(
                columns: const [
                  DataColumn(
                    label: Text(
                      'Pet Name',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Age',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Breed',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Gender',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Weight',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Vaccines',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Vaccine History',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold),
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
                        ElevatedButton.icon(
                          onPressed: () {
                            String petId = petData['petId'] ?? petDoc.id;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Vaccinescreen(petId: petId),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.vaccines,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Vaccines',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFA6650),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        ElevatedButton.icon(
                          onPressed: () {
                            String petId = petData['petId'] ?? petDoc.id;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => History(petId: petId),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.history,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'View',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
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
        title: Center(
            child: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        )),
        backgroundColor: Color(0xFFFA6650),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const AdminLogin(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Log Out'),
          ),
        ],
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
            scrollDirection: Axis.vertical,
            child: Center(
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
            ),
          );
        },
      ),
    );
  }
}
