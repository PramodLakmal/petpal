import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Vaccinescreen extends StatefulWidget {
  final String petId; // Receive petId

  const Vaccinescreen({Key? key, required this.petId}) : super(key: key);

  @override
  State<Vaccinescreen> createState() => _VaccinescreenState();
}

class _VaccinescreenState extends State<Vaccinescreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _vaccineNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Function to add vaccine details to Firestore
  Future<void> _addVaccine() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Reference to the 'petvaccines' collection
        CollectionReference vaccinesCollection =
            FirebaseFirestore.instance.collection('petvaccines');

        // Add vaccine data with relevant petId
        await vaccinesCollection.add({
          'petId': widget.petId,
          'vaccineName': _vaccineNameController.text.trim(),
          'date': _dateController.text.trim(),
          'time': _timeController.text.trim(),
          'venue': _venueController.text.trim(),
          'description': _descriptionController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        // Clear form fields after adding vaccine data
        _vaccineNameController.clear();
        _dateController.clear();
        _timeController.clear();
        _venueController.clear();
        _descriptionController.clear();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaccine added successfully!')),
        );

        // Navigate back to previous screen
        Navigator.pop(context);
      } catch (e) {
        // Log the error for debugging
        print('Error adding vaccine: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding vaccine: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _vaccineNameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _venueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Function to pick a date
  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000), // Adjust as needed
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  // Function to pick a time
  Future<void> _pickTime() async {
    TimeOfDay? pickedTime =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (pickedTime != null) {
      setState(() {
        _timeController.text = pickedTime.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: const Text(
          'Add Vaccine Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        )),
        backgroundColor: Color(0xFFFA6650),
      ),
      body: Center(
        child: Container(
          width: 800, // Set a fixed width for desktop
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey, // Associate the form key
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: const Text(
                    'Vaccine Information',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildCard(
                  child: TextFormField(
                    controller: _vaccineNameController,
                    decoration: _inputDecoration(
                        label: 'Vaccine Name', icon: Icons.vaccines),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the vaccine name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildCard(
                        child: TextFormField(
                          controller: _dateController,
                          decoration: _inputDecoration(
                            label: 'Date',
                            icon: Icons.calendar_today,
                          ),
                          readOnly: true,
                          onTap: _pickDate,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please select a date';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildCard(
                        child: TextFormField(
                          controller: _timeController,
                          decoration: _inputDecoration(
                            label: 'Time',
                            icon: Icons.access_time,
                          ),
                          readOnly: true,
                          onTap: _pickTime,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please select a time';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildCard(
                  child: TextFormField(
                    controller: _venueController,
                    decoration: _inputDecoration(label: 'Venue'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the venue';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 15),
                _buildCard(
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: _inputDecoration(label: 'Description'),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _addVaccine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFA6650),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Add Vaccine',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget to build a card for form fields
  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: child,
      ),
    );
  }

  // Input decoration with an icon
  InputDecoration _inputDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFFA6650), width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      suffixIcon: icon != null ? Icon(icon, color: Color(0xFFFA6650)) : null,
    );
  }
}
