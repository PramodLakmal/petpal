import 'dart:io'; // Required to handle files
import 'dart:convert'; // Required for Base64 encoding
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:petpal/Screens/adoption/adoption.dart'; // Import your AdoptionPage

class CreateAdoptionPost extends StatefulWidget {
  const CreateAdoptionPost({Key? key}) : super(key: key);

  @override
  State<CreateAdoptionPost> createState() => _CreateAdoptionPostState();
}

class _CreateAdoptionPostState extends State<CreateAdoptionPost> {
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

  // Function to add adoption post data to Firestore
  Future<void> _addAdoptionPost() async {
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
            FirebaseFirestore.instance.collection('adoption').doc();

        // Use the generated document ID as postId
        String postId = docRef.id;

        // Add adoption post data to Firestore, including the postId and Base64 image
        await docRef.set({
          'postId': postId, // Include postId in the document
          'name': _nameController.text.trim(),
          'age': int.parse(_ageController.text.trim()), // Convert to int
          'breed': _breedController.text.trim(),
          'gender': _gender,
          'weight': double.parse(_weightController.text.trim()), // Convert to double
          'description': _descriptionController.text.trim(),
          'userId': user.uid,
          'imageBase64': imageBase64, // Store Base64-encoded image
          'timestamp': FieldValue.serverTimestamp(), // Optional: Add timestamp
        });

        // Clear form fields after adding adoption post data
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
          const SnackBar(content: Text('Adoption post created successfully!')),
        );

        // Navigate to AdoptionPage after successfully creating the post
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdoptionPage()),
        );
      } catch (e) {
        // Log the error for debugging
        print('Error adding adoption post: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding adoption post: $e')),
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
        title: const Text('Create Adoption Post',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      body: SingleChildScrollView(
        // To prevent overflow when keyboard appears
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey, // Associate the form key
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children to fill width
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
                              color: Colors.orange),
                          onPressed: _pickImage, // Handle add photo functionality
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _pickImage, // Pick image on button press
                  style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Add Photo',
                  style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pet Info',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Name:'),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter pet\'s name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the pet\'s name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text('Age:'),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        hintText: 'Enter pet\'s age',
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
                    const Text('Breed:'),
                    TextFormField(
                      controller: _breedController,
                      decoration: const InputDecoration(
                        hintText: 'Enter pet\'s breed',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the pet\'s breed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text('Description:'),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Enter pet\'s description',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the pet\'s description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Gender:'),
                              DropdownButtonFormField<String>(
                                value: _gender,
                                onChanged: (newValue) {
                                  setState(() {
                                    _gender = newValue!;
                                  });
                                },
                                items: <String>[
                                  'Male',
                                  'Female'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Weight (kg):'),
                              TextFormField(
                                controller: _weightController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter weight',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter the pet\'s weight';
                                  }
                                  if (double.tryParse(value.trim()) == null) {
                                    return 'Please enter a valid weight';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addAdoptionPost, // Trigger add adoption post function
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Create Adoption Post',
                style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
