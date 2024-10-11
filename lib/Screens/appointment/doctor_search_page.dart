import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'appointment_booking_page.dart';

class DoctorSearchPage extends StatefulWidget {
  const DoctorSearchPage({super.key});

  @override
  _DoctorSearchPageState createState() => _DoctorSearchPageState();
}

class _DoctorSearchPageState extends State<DoctorSearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> doctorList = [];
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _getRandomDoctors();
  }

  _getRandomDoctors() async {
    // First, get all doctors
    FirebaseFirestore.instance.collection('doctors').get().then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.length > 0) {
        // Create a list of all doctors
        List<QueryDocumentSnapshot> allDoctors = querySnapshot.docs;
        
        // Randomly select 5 doctors (or less if total doctors are less than 5)
        int numberOfDoctors = min(5, allDoctors.length);
        List<QueryDocumentSnapshot> randomDoctors = [];
        
        // Create a copy of the list to avoid modifying the original
        List<QueryDocumentSnapshot> tempList = List.from(allDoctors);
        
        for (int i = 0; i < numberOfDoctors; i++) {
          int randomIndex = Random().nextInt(tempList.length);
          randomDoctors.add(tempList[randomIndex]);
          tempList.removeAt(randomIndex);
        }

        setState(() {
          doctorList = randomDoctors;
        });
      }
    });
  }

  _searchDoctorsByLocation(String location) async {
    setState(() {
      isSearching = true;
    });

    if (location.isEmpty) {
      _getRandomDoctors();
      setState(() {
        isSearching = false;
      });
      return;
    }

    FirebaseFirestore.instance.collection('doctors')
        .where('location', isGreaterThanOrEqualTo: location)
        .where('location', isLessThanOrEqualTo: location + '\uf8ff')
        .get().then((value) {
      setState(() {
        doctorList = value.docs;
        isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Doctors')),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search doctors by location...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.location_on, color: Colors.orange),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _getRandomDoctors();
                        },
                      )
                    : IconButton(
                        icon: Icon(Icons.search, color: Colors.orange),
                        onPressed: () {
                          _searchDoctorsByLocation(_searchController.text);
                        },
                      ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                _searchDoctorsByLocation(value);
              },
            ),
          ),
          if (isSearching)
            Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          if (!isSearching && doctorList.isEmpty)
            Padding(
              padding: EdgeInsets.all(20),
              child: Text('No doctors found in this location',
                  style: TextStyle(color: Colors.grey)),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: doctorList.length,
              itemBuilder: (context, index) {
                return DoctorCard(
                  doctor: doctorList[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final QueryDocumentSnapshot doctor;

  DoctorCard({
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                doctor['doctorPhoto'],
                width: 130,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor['name'], 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text(doctor['location'], 
                    style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0))),
                  SizedBox(height: 5),
                  Text('Payment: LKR ${doctor['payment']}', 
                    style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0))),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppointmentBookingPage(
                                doctorData: doctor,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: Text('Book'),
                      ),
                      Spacer(),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.orange, size: 16),
                          SizedBox(width: 2),
                          Text('5.0'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}