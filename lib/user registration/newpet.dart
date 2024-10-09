import 'dart:io'; // Required to handle files
import 'dart:convert'; // Required for Base64 encoding
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:petpal/user%20registration/homeScreen.dart';
import 'package:petpal/user%20registration/login.dart';

class AddPet extends StatefulWidget {
  const AddPet({super.key});

  @override
  State<AddPet> createState() => _AddPetState();
}

class _AddPetState extends State<AddPet> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers to capture form input
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Gender dropdown value
  String _gender = 'Male'; // Default value

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage; // File to store the picked image

  // Function to pick an image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path); // Store the picked image
      });
    }
  }

  // Function to convert image to Base64 string
  Future<String?> _convertImageToBase64() async {
    if (_pickedImage == null) return null;
    try {
      List<int> imageBytes = await _pickedImage!.readAsBytes();
      return base64Encode(imageBytes);
    } catch (e) {
      print('Error encoding image: $e');
      return null;
    }
  }

  // Helper method to capitalize the first letter of the name
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text; // Return as is if empty
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Function to add pet data to Firestore
  Future<void> _addPet() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user is currently signed in.')),
          );
          return;
        }

        // Convert image to Base64
        final imageBase64 = await _convertImageToBase64();

        // Generate a new document reference with a unique ID
        DocumentReference docRef =
            FirebaseFirestore.instance.collection('pets').doc();

        // Use the generated document ID as petId
        String petId = docRef.id;

        // Add pet data to Firestore, including the petId and Base64 image
        await docRef.set({
          'petId': petId, // Include petId in the document
          'name': _capitalizeFirstLetter(
              _nameController.text.trim()), // Capitalize first letter
          'age': int.parse(_ageController.text.trim()), // Convert to int
          'breed': _breedController.text.trim(),
          'gender': _gender,
          'weight':
              double.parse(_weightController.text.trim()), // Convert to double
          'description': _descriptionController.text.trim(),
          'userId': user.uid,
          'imageBase64': imageBase64, // Store Base64-encoded image
          'timestamp': FieldValue.serverTimestamp(), // Optional: Add timestamp
        });

        // Clear form fields after adding pet data
        _nameController.clear();
        _ageController.clear();
        _breedController.clear();
        _weightController.clear();
        _descriptionController.clear();
        setState(() {
          _pickedImage = null; // Clear the picked image
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet added successfully!')),
        );

        // Navigate back to HomeScreen
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const HomeScreen()));
      } catch (e) {
        // Log the error for debugging
        print('Error adding pet: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding pet: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _nameController.dispose();
    _ageController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 112.0,
        title: Center(
            child: const Text(
          'Register Pet',
          style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
        )),
        backgroundColor: Color(0xFFFA6650),
      ),
      body: SingleChildScrollView(
        // To prevent overflow when keyboard appears
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey, // Associate the form key
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Stretch children to fill width
            children: [
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _pickedImage != null
                      ? FileImage(_pickedImage!)
                      : null, // Display the picked image
                  child: _pickedImage == null
                      ? IconButton(
                          icon: const Icon(Icons.add_a_photo,
                              color: Color(0xFFFA6650)),
                          onPressed:
                              _pickImage, // Handle add photo functionality
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _pickImage, // Pick image on button press
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFA6650),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Add Photo',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: const Text(
                        'Add Your pet',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Name:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your pet\'s name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              10.0), // Optional: Rounded corners
                          borderSide:
                              BorderSide.none, // Optional: Removes the border
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the pet\'s name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Age:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _ageController,
                      decoration: InputDecoration(
                        hintText: 'Enter your pet\'s age',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              10.0), // Optional: Rounded corners
                          borderSide:
                              BorderSide.none, // Optional: Removes the border
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the pet\'s age';
                        }
                        if (int.tryParse(value.trim()) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Breed:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _breedController,
                      decoration: InputDecoration(
                        hintText: 'Enter your pet\'s breed',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              10.0), // Optional: Rounded corners
                          borderSide:
                              BorderSide.none, // Optional: Removes the border
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the pet\'s breed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Gender:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'Female', child: Text('Female')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _gender = value!;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              10.0), // Optional: Rounded corners
                          borderSide:
                              BorderSide.none, // Optional: Removes the border
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Weight (in kg):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _weightController,
                      decoration: InputDecoration(
                        hintText: 'Enter your pet\'s weight',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              10.0), // Optional: Rounded corners
                          borderSide:
                              BorderSide.none, // Optional: Removes the border
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the pet\'s weight';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3, // Allows multiple lines for description
                      decoration: InputDecoration(
                        hintText: 'Enter a brief description of your pet',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              10.0), // Optional: Rounded corners
                          borderSide:
                              BorderSide.none, // Optional: Removes the border
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description for your pet';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _addPet, // Call function to add pet data
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFA6650),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Register Pet',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
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
    );
  }
}
