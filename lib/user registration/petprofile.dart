import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:petpal/user%20registration/editPetProfile.dart';
import 'package:petpal/user%20registration/homeScreen.dart';

class PetProfile extends StatefulWidget {
  final String name;
  final String breed;
  final int age; // Change age to int
  final String gender;
  final double weight; // Change weight to double
  final String petId; // Add petId to identify the pet
  // final String imageUrl; // Add imageUrl to hold the pet's image

  const PetProfile({
    super.key,
    required this.name,
    required this.breed,
    required this.age, // Accept age as int
    required this.gender,
    required this.weight, // Accept weight as double
    required this.petId, // Accept petId
    // required this.imageUrl, // Accept imageUrl
  });

  @override
  State<PetProfile> createState() => _PetProfileState();
}

class _PetProfileState extends State<PetProfile> {
  late String name;
  late String breed;
  late int age; // Change to int
  late String gender;
  late double weight; // Change to double

  @override
  void initState() {
    super.initState();
    // Initialize mutable state variables
    name = widget.name;
    breed = widget.breed;
    age = widget.age; // Initialize as int
    gender = widget.gender;
    weight = widget.weight; // Initialize as double
  }

  Future<void> _deletePet() async {
    try {
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.petId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet deleted successfully!')),
      );
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete pet: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: Text("$name's Profile", style: const TextStyle(fontSize: 24)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  '', // Use imageUrl passed from constructor
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100, // Light yellow background
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orangeAccent, width: 2),
                ),

                // Pet details

                child: Column(children: [
                  Text(
                    "$name's About",
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  buildPetDetailRow("Name", name),
                  buildPetDetailRow("Breed", breed),
                  buildPetDetailRow(
                      "Age", age.toString()), // Convert age to string
                  buildPetDetailRow("Gender", gender),
                  buildPetDetailRow("Weight", "${weight.toString()} kg"),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          final updatedData = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPet(
                                name: name,
                                breed: breed,
                                age: age.toString(), // Pass age as string
                                gender: gender,
                                weight:
                                    weight.toString(), // Pass weight as string
                                petId: widget.petId, // Pass the petId here
                              ),
                            ),
                          );

                          // Check if updated data is not null
                          if (updatedData != null) {
                            // Update the state with the new data
                            setState(() {
                              name = updatedData['name'];
                              breed = updatedData['breed'];
                              age = int.parse(
                                  updatedData['age']); // Parse back to int
                              gender = updatedData['gender'];
                              weight = double.parse(updatedData[
                                  'weight']); // Parse back to double
                            });
                          }
                        },
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: _deletePet,
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                ])),

            const SizedBox(height: 20),

            // Buttons for additional options
            ElevatedButton.icon(
              onPressed: () {}, // Add functionality here
              icon: const Icon(Icons.calendar_today),
              label: const Text("Appointments"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {}, // Add functionality here
              icon: const Icon(Icons.vaccines),
              label: const Text("Upcoming Vaccine"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {}, // Add functionality here
              icon: const Icon(Icons.history),
              label: const Text("Vaccination History"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to build rows for pet details
  Widget buildPetDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          Text(value, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
