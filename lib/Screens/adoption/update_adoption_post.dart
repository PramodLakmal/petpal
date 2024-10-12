import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/Screens/adoption/adoption.dart';

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
  
  String _gender = 'Male';
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  String? _existingImageBase64;

  @override
  void initState() {
    super.initState();
    _fetchPostDetails();
  }

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
      _existingImageBase64 = data['imageBase64'];
    }

    setState(() {});
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updatePost() async {
    if (_formKey.currentState!.validate()) {
      String? imageBase64;

      if (_pickedImage != null) {
        List<int> imageBytes = await _pickedImage!.readAsBytes();
        imageBase64 = base64Encode(imageBytes);
      } else {
        imageBase64 = _existingImageBase64;
      }

      await FirebaseFirestore.instance.collection('adoption').doc(widget.postId).update({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'breed': _breedController.text.trim(),
        'weight': double.tryParse(_weightController.text.trim()),
        'description': _descriptionController.text.trim(),
        'gender': _gender,
        'imageBase64': imageBase64,
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AdoptionPage()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully!')),
      );
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[700]),
      prefixIcon: Icon(icon, color: Colors.orange),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.orange, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Update Adoption Post',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[100],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.1),
                              spreadRadius: 5,
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _pickedImage != null
                              ? Image.file(_pickedImage!, fit: BoxFit.cover)
                              : _existingImageBase64 != null
                                  ? Image.memory(base64Decode(_existingImageBase64!), fit: BoxFit.cover)
                                  : Icon(Icons.pets, size: 80, color: Colors.orange),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.orange,
                          radius: 24,
                          child: IconButton(
                            icon: Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 8,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: _buildInputDecoration('Pet Name', Icons.pets),
                        validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _ageController,
                        decoration: _buildInputDecoration('Age (years)', Icons.calendar_today),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Please enter age' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _breedController,
                        decoration: _buildInputDecoration('Breed', Icons.category),
                        validator: (value) => value!.isEmpty ? 'Please enter a breed' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _weightController,
                        decoration: _buildInputDecoration('Weight (kg)', Icons.monitor_weight),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Please enter weight' : null,
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: _buildInputDecoration('Gender', Icons.person),
                        items: ['Male', 'Female'].map((String gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _gender = value);
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _buildInputDecoration('Description', Icons.description)
                            .copyWith(alignLabelWithHint: true),
                        maxLines: 4,
                        validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.orange[700]!, Colors.orange],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _updatePost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Update Post',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}