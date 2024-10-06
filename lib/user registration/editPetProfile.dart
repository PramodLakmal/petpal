import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditPet extends StatefulWidget {
  final String name;
  final String breed;
  final String age;
  final String gender;
  final String weight;
  final String
      petId; // Use this if you have a petId for identifying the document in Firestore

  // final String petId; // Use this if you have a petId for identifying the document in Firestore

  const EditPet({
    super.key,
    required this.name,
    required this.breed,
    required this.age,
    required this.gender,
    required this.weight,
    required this.petId,
    // required this.petId,
  });

  @override
  State<EditPet> createState() => _EditPetState();
}

class _EditPetState extends State<EditPet> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();

    // Initialize the text controllers with existing pet data
    _nameController = TextEditingController(text: widget.name);
    _breedController = TextEditingController(text: widget.breed);
    _ageController = TextEditingController(text: widget.age);
    _genderController = TextEditingController(text: widget.gender);
    _weightController = TextEditingController(text: widget.weight);
  }

  // Function to update pet details in Firestore
  Future<void> _updatePetData() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Assuming each pet has a unique document in Firestore
        await FirebaseFirestore.instance
            .collection('pets')
            .doc(
                widget.petId) // Use pet name or pet ID to identify the document
            .update({
          'name': _nameController.text,
          'breed': _breedController.text,
          'age': _ageController.text,
          'gender': _genderController.text,
          'weight': _weightController.text,
        });

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet details updated successfully!')),
        );

        // Navigate back to the previous screen
        Navigator.pop(context, {
          'name': _nameController.text,
          'breed': _breedController.text,
          'age': _ageController.text,
          'gender': _genderController.text,
          'weight': _weightController.text,
        });
      } catch (e) {
        // Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update pet: $e')),
        );
      }
    }
  }

  //
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Pet Profile"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Pet Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the pet\'s name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Breed'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the pet\'s breed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the pet\'s age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _genderController,
                decoration: const InputDecoration(labelText: 'Gender'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the pet\'s gender';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the pet\'s weight';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updatePetData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
