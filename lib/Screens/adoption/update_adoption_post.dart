import 'dart:convert'; // Required for base64 decoding
import 'dart:io'; // Required to handle files
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/Screens/adoption/adoption.dart'; // For navigating to AdoptionPage

class UpdateAdoptionPost extends StatefulWidget {
  final String postId;

  const UpdateAdoptionPost({Key? key, required this.postId}) : super(key: key);

  @override
  _UpdateAdoptionPostState createState() => _UpdateAdoptionPostState();
}

class _UpdateAdoptionPostState extends State<UpdateAdoptionPost> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String _gender = 'Male'; // Default value
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage; // File to store the picked image
  String? _existingImageBase64; // To store existing image data

  @override
  void initState() {
    super.initState();
    _fetchPostDetails();
  }

  // Fetch post details from Firestore
  Future<void> _fetchPostDetails() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('adoption').doc(widget.postId).get();
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _ageController.text = data['age']?.toString() ?? '';
      _breedController.text = data['breed'] ?? '';
      _weightController.text = data['weight']?.toString() ?? '';
      _descriptionController.text = data['description'] ?? '';
      _gender = data['gender'] ?? 'Male';
      _existingImageBase64 = data['imageBase64']; // Store existing image Base64 string

      // Debugging: Print fetched data to console
      print('Fetched Data: $data');
      print('Existing Image Base64: $_existingImageBase64');
    } else {
      print('No data found for this post.');
    }

    setState(() {}); // Call setState to update UI with fetched data
  }

  // Function to pick an image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path); // Store the picked image
      });
    }
  }

  // Function to update the post in Firestore
  Future<void> _updatePost() async {
    if (_formKey.currentState!.validate()) {
      String? imageBase64;

      // If a new image is picked, encode it to Base64
      if (_pickedImage != null) {
        List<int> imageBytes = await _pickedImage!.readAsBytes();
        imageBase64 = base64Encode(imageBytes); // Convert image to Base64
      } else {
        // Use existing image if no new image is picked
        imageBase64 = _existingImageBase64;
      }

      await FirebaseFirestore.instance.collection('adoption').doc(widget.postId).update({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()), // Convert to int
        'breed': _breedController.text.trim(),
        'weight': double.tryParse(_weightController.text.trim()), // Convert to double
        'description': _descriptionController.text.trim(),
        'gender': _gender,
        'imageBase64': imageBase64, // Store Base64-encoded image
      });

      // Navigate to AdoptionPage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AdoptionPage()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Adoption Post',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ClipOval(
                  child: _pickedImage != null
                      ? Image.file(
                          _pickedImage!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : _existingImageBase64 != null
                          ? Image.memory(
                              base64Decode(_existingImageBase64!), // Decode and display existing image
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.pets, size: 120), // Placeholder icon
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Pick Image',
                  style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter age' : null,
              ),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Breed'),
                validator: (value) => value!.isEmpty ? 'Please enter a breed' : null,
              ),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter weight' : null,
              ),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _gender = value;
                    });
                  }
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updatePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Update Post',
                style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
