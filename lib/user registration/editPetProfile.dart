import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditPet extends StatefulWidget {
  final String name;
  final String breed;
  final String age;
  final String gender;
  final String weight;
  final String petId;

  const EditPet({
    super.key,
    required this.name,
    required this.breed,
    required this.age,
    required this.gender,
    required this.weight,
    required this.petId,
  });

  @override
  State<EditPet> createState() => _EditPetState();
}

class _EditPetState extends State<EditPet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;
  late TextEditingController _weightController;

  String? _imageBase64; // Pet image in Base64 format

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.name);
    _breedController = TextEditingController(text: widget.breed);
    _ageController = TextEditingController(text: widget.age);
    _genderController = TextEditingController(text: widget.gender);
    _weightController = TextEditingController(text: widget.weight);

    _fetchPetImage(); // Fetch the pet's image from Firestore
  }

  // Function to fetch pet's image from Firestore
  Future<void> _fetchPetImage() async {
    try {
      DocumentSnapshot petDoc = await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.petId)
          .get();

      if (petDoc.exists && petDoc['imageBase64'] != null) {
        setState(() {
          _imageBase64 = petDoc['imageBase64']; // Fetch the imageBase64 string
        });
      }
    } catch (e) {
      // Handle any errors
      print('Error fetching pet image: $e');
    }
  }

  // Function to update pet details in Firestore
  Future<void> _updatePetData() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('pets')
            .doc(widget.petId)
            .update({
          'name': _nameController.text,
          'breed': _breedController.text,
          'age': _ageController.text,
          'gender': _genderController.text,
          'weight': _weightController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet details updated successfully!')),
        );

        Navigator.pop(context, {
          'name': _nameController.text,
          'breed': _breedController.text,
          'age': _ageController.text,
          'gender': _genderController.text,
          'weight': _weightController.text,
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update pet: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Decode the imageBase64 into an Image widget if it exists
    Widget _buildProfileImage() {
      if (_imageBase64 != null) {
        Uint8List bytes = base64Decode(_imageBase64!);
        return CircleAvatar(
          radius: 60,
          backgroundImage: MemoryImage(bytes), // Display the decoded image
        );
      } else {
        return const CircleAvatar(
          radius: 60,
          backgroundImage:
              AssetImage('assets/profile_placeholder.png'), // Placeholder image
        );
      }
    }

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: 112.0,
          centerTitle: true,
          title: const Text("Edit Pet Profile",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 30)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Display pet image (or placeholder) in the profile picture
                _buildProfileImage(),
                const SizedBox(height: 20),

                // Form fields with icons
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Name Field with Icon
                      Card(
                        color: Colors.orange[50],
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Pet Name',
                              labelStyle: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold),
                              prefixIcon: Icon(Icons.pets), // Icon for name
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the pet\'s name';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Breed Field with Icon
                      Card(
                        color: Colors.orange[50],
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            controller: _breedController,
                            decoration: const InputDecoration(
                              labelText: 'Breed',
                              labelStyle: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold),
                              prefixIcon: Icon(Icons.pets), // Icon for breed
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the pet\'s breed';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Age Field with Icon
                      Card(
                        color: Colors.orange[50],
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            controller: _ageController,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              labelStyle: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold),
                              prefixIcon:
                                  Icon(Icons.calendar_today), // Icon for age
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the pet\'s age';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Gender Field with Icon
                      Card(
                        color: Colors.orange[50],
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: DropdownButtonFormField<String>(
                            value: _genderController.text.isNotEmpty
                                ? _genderController.text
                                : null, // Initial value
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              labelStyle: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold),
                              prefixIcon:
                                  Icon(Icons.transgender), // Icon for gender
                              border: InputBorder.none,
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Male', child: Text('Male')),
                              DropdownMenuItem(
                                  value: 'Female', child: Text('Female')),
                            ],
                            onChanged: (String? newValue) {
                              setState(() {
                                _genderController.text = newValue!;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a gender';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Weight Field with Icon
                      Card(
                        color: Colors.orange[50],
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            controller: _weightController,
                            decoration: const InputDecoration(
                              labelText: 'Weight',
                              labelStyle: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold),
                              prefixIcon:
                                  Icon(Icons.fitness_center), // Icon for weight
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the pet\'s weight';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Floating Save Button
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: FloatingActionButton.extended(
              onPressed: _updatePetData,
              label: const Text(
                'Update',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white),
              ),
              backgroundColor: Colors.orange,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat);
  }
}
