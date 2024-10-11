import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentBookingPage extends StatefulWidget {
  final QueryDocumentSnapshot doctorData;

  const AppointmentBookingPage({super.key, required this.doctorData});

  @override
  _AppointmentBookingPageState createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  DateTime selectedDate = DateTime.now();
  String selectedTime = '10:00 AM';
  String? selectedPetId;
  String? doctorDescription;
  final TextEditingController petWeightController = TextEditingController();
  final TextEditingController petBreedController = TextEditingController();

  List<String> availableTimes = [
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:30 PM',
    '2:30 PM',
    '3:00 PM',
    '3:30 PM',
    '4:00 PM',
  ];

  List<QueryDocumentSnapshot> pets = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctorDescription();
    _fetchUserPets();
  }

  void _fetchDoctorDescription() {
    FirebaseFirestore.instance
        .collection('doctors')
        .doc(widget.doctorData.id)
        .get()
        .then((doc) {
      if (doc.exists && doc.data()!.containsKey('description')) {
        setState(() {
          doctorDescription = doc.data()!['description'];
        });
      }
    });
  }

  void _fetchUserPets() {
    // Get current user's ID (assuming Firebase Auth)
    String userId = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance
        .collection('pets')
        .where('userId', isEqualTo: userId)
        .get()
        .then((querySnapshot) {
      setState(() {
        pets = querySnapshot.docs;
      });
    });
  }

  Future<void> _createAppointment() async {
    if (selectedPetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a pet')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('appointments').add({
        'doctorId': widget.doctorData.id,
        'location': widget.doctorData['location'],
        'doctorName': widget.doctorData['name'],
        'payment': widget.doctorData['payment'],
        'petId': selectedPetId, // Save petId in the appointment
        'appointmentDate': Timestamp.fromDate(selectedDate),
        'appointmentTime': selectedTime,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'petBreed': petBreedController.text, // Save pet breed
        'petWeight': petWeightController.text, // Save pet weight
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment booked successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking appointment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Appointment'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          widget.doctorData['doctorPhoto'],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. ${widget.doctorData['name']}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Veterinarian',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Payment:',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'LKR ${widget.doctorData['payment']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Doctor Description Section
              if (doctorDescription != null) ...[
                SizedBox(height: 24),
                Text(
                  'About Dr. ${widget.doctorData['name']}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  doctorDescription!,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],

              // Pet Selection Dropdown
              SizedBox(height: 24),
              DropdownButton<String>(
                value: selectedPetId,
                hint: Text('Select Pet'),
                items: pets.map((QueryDocumentSnapshot pet) {
                  return DropdownMenuItem<String>(
                    value: pet.id,
                    child: Text(pet['name']),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedPetId = newValue;
                  });
                },
              ),

              // Pet Breed and Weight Inputs
              SizedBox(height: 24),
              TextField(
                controller: petBreedController,
                decoration: InputDecoration(
                  labelText: 'Pet Breed',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: petWeightController,
                decoration: InputDecoration(
                  labelText: 'Pet Weight (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),

              // Time Selection
              SizedBox(height: 24),
              Text(
                'Available Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableTimes.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(availableTimes[index]),
                        selected: selectedTime == availableTimes[index],
                        onSelected: (bool selected) {
                          setState(() {
                            selectedTime = availableTimes[index];
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              // Date Selection
              SizedBox(height: 24),
              Text(
                'Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              CalendarDatePicker(
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(Duration(days: 30)),
                onDateChanged: (DateTime date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
              ),

              // Book Appointment Button
              SizedBox(height: 24,),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _createAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFA6650),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Book Appointment',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
