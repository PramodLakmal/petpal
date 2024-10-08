import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class EditReportScreen extends StatefulWidget {
  final DocumentSnapshot doc;

  EditReportScreen({required this.doc});

  @override
  _EditReportScreenState createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  late String animalType;
  late String breed;
  late String color;
  late String location;
  late String name;
  late String contactNumber;
  File? _image;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    var reportData = widget.doc.data() as Map<String, dynamic>;
    animalType = reportData['animalType'];
    breed = reportData['breed'];
    color = reportData['color'];
    location = reportData['location'];
    name = reportData['name'];
    contactNumber = reportData['contactNumber'];
    _imageUrl = reportData['imageUrl'];
  }

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

  Future<void> updatePetReport() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String? downloadUrl = _imageUrl;

      if (_image != null) {
        String fileName = DateTime.now().toString();
        Reference firebaseStorageRef =
            FirebaseStorage.instance.ref().child('pet_images/$fileName');
        UploadTask uploadTask = firebaseStorageRef.putFile(_image!);
        TaskSnapshot taskSnapshot = await uploadTask;
        downloadUrl = await taskSnapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('pet_reports')
          .doc(widget.doc.id)
          .update({
        'animalType': animalType,
        'breed': breed,
        'color': color,
        'location': location,
        'name': name,
        'contactNumber': contactNumber,
        'imageUrl': downloadUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pet Report Updated')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Pet Report'),
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
                            _buildTextField('What kind of animal?', (value) => animalType = value!, animalType),
                            _buildTextField('Breed', (value) => breed = value!, breed),
                            _buildTextField('Color', (value) => color = value!, color),
                            _buildTextField('Address / Location', (value) => location = value!, location),
                            _buildTextField('Your Name', (value) => name = value!, name),
                            _buildTextField('Contact Number', (value) => contactNumber = value!, contactNumber),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(_image!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          )
                        : _imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(_imageUrl!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover),
                              )
                            : _buildImagePlaceholder(),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add_a_photo),
                      label: Text('Change Image'),
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
                      child: Text('Update Report'),
                      onPressed: updatePetReport,
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

  Widget _buildTextField(String label, Function(String?) onSaved, String initialValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: initialValue,
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