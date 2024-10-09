import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/Screens/adoption/adoption.dart';
import 'package:petpal/Screens/completedvaccines.dart';
import 'package:petpal/Screens/upcomingVaccines.dart';
import 'package:petpal/user%20registration/editPetProfile.dart';
import 'package:petpal/user%20registration/homeScreen.dart';

class PetProfile extends StatefulWidget {
  final String name;
  final String breed;
  final int age;
  final String gender;
  final double weight;
  final String petId;

  const PetProfile({
    super.key,
    required this.name,
    required this.breed,
    required this.age,
    required this.gender,
    required this.weight,
    required this.petId,
  });

  @override
  State<PetProfile> createState() => _PetProfileState();
}

class _PetProfileState extends State<PetProfile> {
  late String name;
  late String breed;
  late int age;
  late String gender;
  late double weight;

  Uint8List? petImage;

  @override
  void initState() {
    super.initState();
    name = widget.name;
    breed = widget.breed;
    age = widget.age;
    gender = widget.gender;
    weight = widget.weight;
    _fetchPetImage();
  }

  Future<void> _fetchPetImage() async {
    try {
      DocumentSnapshot petDoc = await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.petId)
          .get();

      if (petDoc.exists) {
        String? imageBase64 = petDoc['imageBase64'];
        if (imageBase64 != null && imageBase64.isNotEmpty) {
          setState(() {
            petImage = base64Decode(imageBase64);
          });
        }
      }
    } catch (e) {
      print('Failed to fetch pet image: $e');
    }
  }

  Future<void> _updatePetImage(Uint8List imageBytes) async {
    try {
      String base64Image = base64Encode(imageBytes);
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.petId)
          .update({'imageBase64': base64Image});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet image updated successfully!')),
      );
      setState(() {
        petImage = imageBytes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update pet image: $e')),
      );
    }
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      Uint8List imageBytes = await image.readAsBytes();
      await _updatePetImage(imageBytes);
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevents dialog from closing if tapped outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 10),
              Text('Delete Pet'),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this pet profile? This action cannot be undone.',
            style: TextStyle(fontSize: 18),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Close the dialog without deleting
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog before deleting
                await _deletePet(); // Call the delete method
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
      appBar: AppBar(
        toolbarHeight: 112.0,
        backgroundColor: const Color(0xFFFA6650),
        title: Center(
            child: Text(
          "$name's Profile",
          style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
        )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        // Make the body scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  petImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                              16), // Adjust the radius as needed
                          child: Image.memory(
                            petImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(
                              16), // Adjust the radius as needed
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.pets,
                                size: 100,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.black,
                        size: 30,
                      ),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // About Section with modern UI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFA6650).withOpacity(0.8),
                    Colors.pink[50]!
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 3,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "$name's About",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Divider(thickness: 1.5, color: Colors.pink[50]),
                  const SizedBox(height: 10),
                  buildPetDetailRow(Icons.pets, "Name", name),
                  buildPetDetailRow(Icons.person, "Breed", breed),
                  buildPetDetailRow(Icons.cake, "Age", age.toString()),
                  buildPetDetailRow(Icons.female, "Gender", gender),
                  buildPetDetailRow(
                      Icons.monitor_weight, "Weight", "${weight} kg"),

                  const SizedBox(height: 20),

                  // Row of icon buttons for edit and delete
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.black87, size: 30),
                        onPressed: () async {
                          final updatedData = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPet(
                                name: name,
                                breed: breed,
                                age: age.toString(),
                                gender: gender,
                                weight: weight.toString(),
                                petId: widget.petId,
                              ),
                            ),
                          );
                          if (updatedData != null) {
                            setState(() {
                              name = updatedData['name'];
                              breed = updatedData['breed'];
                              age = int.parse(updatedData['age']);
                              gender = updatedData['gender'];
                              weight = double.parse(updatedData['weight']);
                            });
                          }
                        },
                        tooltip: 'Edit Pet',
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red, size: 30),
                        onPressed: () => _showDeleteConfirmationDialog(context),
                        tooltip: 'Delete Pet',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Custom buttons for appointments and vaccines
            ListTile(
              leading:
                  const Icon(Icons.calendar_today, color: Color(0xFFFA6650)),
              title: const Text('Appointments', style: TextStyle(fontSize: 18)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                // Add functionality for appointments
              },
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.vaccines, color: Color(0xFFFA6650)),
              title: const Text('Upcoming Vaccines',
                  style: TextStyle(fontSize: 18)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpcomingVaccines(petId: widget.petId),
                  ),
                );
              },
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.done, color: Color(0xFFFA6650)),
              title: const Text('Completed Vaccines',
                  style: TextStyle(fontSize: 18)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Completed(petId: widget.petId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPetDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$title: $value',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
