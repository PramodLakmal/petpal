import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'appointment_booking_page.dart';

class DoctorSearchPage extends StatefulWidget {
  const DoctorSearchPage({super.key});

  @override
  _DoctorSearchPageState createState() => _DoctorSearchPageState();
}

class _DoctorSearchPageState extends State<DoctorSearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> doctorList = [];

  @override
  void initState() {
    super.initState();
    _getDefaultDoctors();
  }

  _getDefaultDoctors() async {
    FirebaseFirestore.instance.collection('doctors').limit(10).get().then((value) {
      setState(() {
        doctorList = value.docs;
      });
    });
  }

  _searchDoctorsByLocation(String location) async {
    FirebaseFirestore.instance.collection('doctors')
        .where('location', isEqualTo: location)
        .get().then((value) {
      setState(() {
        doctorList = value.docs;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Doctors')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search a Doctor',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _searchDoctorsByLocation(_searchController.text);
                  },
                ),
              ),
            ),
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
                    style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 5),
                  Text('Payment: LKR ${doctor['payment']}', 
                    style: TextStyle(color: Colors.grey)),
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