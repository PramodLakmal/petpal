import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportPetScreen extends StatefulWidget {
  final String reportType;

  ReportPetScreen({required this.reportType});

  @override
  _ReportPetScreenState createState() => _ReportPetScreenState();
}

extension StringExtension on String {
  String capitalize() {
    return this.isEmpty
        ? this
        : this[0].toUpperCase() + this.substring(1).toLowerCase();
  }
}

class _ReportPetScreenState extends State<ReportPetScreen> {
  final _formKey = GlobalKey<FormState>();
  String animalType = '';
  String breed = '';
  String color = '';
  String location = '';
  String name = '';
  String contactNumber = '';
  File? _image;

  final picker = ImagePicker();

  Future pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future uploadPetReport() async {
    if (_formKey.currentState!.validate() && _image != null) {
      _formKey.currentState!.save();

      User? user = FirebaseAuth.instance.currentUser;
      String? userId = user?.uid;

      String fileName = DateTime.now().toString();
      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child('pet_images/$fileName');
      UploadTask uploadTask = firebaseStorageRef.putFile(_image!);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('pet_reports').add({
        'type': widget.reportType,
        'animalType': animalType,
        'breed': breed,
        'color': color,
        'location': location,
        'name': name,
        'contactNumber': contactNumber,
        'imageUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
        'comments': [],
        'status': 'not solved',
        'userId': userId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${widget.reportType.capitalize()} Pet Report Submitted')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report ${widget.reportType.capitalize()} Pet'),
        backgroundColor: Colors.amber[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildTextField('What kind of animal?',
                                (value) => animalType = value!),
                            _buildTextField('Breed', (value) => breed = value!),
                            _buildTextField('Color', (value) => color = value!),
                            _buildTextField('Address / Location',
                                (value) => location = value!),
                            _buildTextField(
                                'Your Name', (value) => name = value!),
                            _buildTextField('Contact Number',
                                (value) => contactNumber = value!),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    _image == null
                        ? _buildImagePlaceholder()
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(_image!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          ),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add_a_photo),
                      label: Text('Upload Image'),
                      onPressed: pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[300],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      child: Text('Submit Report'),
                      onPressed: uploadPetReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String?) onSaved) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.amber[700]!),
          ),
        ),
        onSaved: onSaved,
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Icon(
          Icons.add_photo_alternate,
          size: 50,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
