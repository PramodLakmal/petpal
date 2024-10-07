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
          'date': _dateController.text
              .trim(), // Consider using Timestamp or Date object
          'time': _timeController.text.trim(),
          'venue': _venueController.text.trim(),
          'description': _descriptionController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending', // Optional: Add timestamp
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

        // Optionally, navigate back or reset the form
        Navigator.pop(context); // Navigate back to previous screen
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
        title: const Text('Add Vaccine Details'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey, // Associate the form key
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Stretch children to fill width
            children: [
              const SizedBox(height: 20),
              const Text(
                'Vaccine Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Vaccine Name
              TextFormField(
                controller: _vaccineNameController,
                decoration: const InputDecoration(
                  labelText: 'Vaccine Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the vaccine name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              // Date
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
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
              const SizedBox(height: 15),
              // Time
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
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
              const SizedBox(height: 15),
              // Venue
              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(
                  labelText: 'Venue',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the venue';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _addVaccine, // Trigger add vaccine function
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Add Vaccine'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
