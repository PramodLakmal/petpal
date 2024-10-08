import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart';
import 'pet_report_detail_screen.dart';
import 'report_pet_screen.dart';

class NewsFeedScreen extends StatefulWidget {
  @override
  _NewsFeedScreenState createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  String filterType = 'all';
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> fetchReports() {
    CollectionReference reportsRef =
        FirebaseFirestore.instance.collection('pet_reports');

    if (filterType == 'all') {
      return reportsRef.orderBy('timestamp', descending: true).snapshots();
    } else {
      return reportsRef
          .where('type', isEqualTo: filterType)
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
  }

  Future<void> toggleLike(DocumentSnapshot doc) async {
    String reportId = doc.id;
    List likedBy = doc['likedBy'] ?? [];
    String? userId = currentUser?.uid;

    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('pet_reports')
          .doc(reportId)
          .update({
        'likedBy': likedBy.contains(userId)
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
        'likes': FieldValue.increment(likedBy.contains(userId) ? -1 : 1),
      });
    }
  }

  void _showReportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.pets, color: Colors.red),
                title: Text('Report Lost Pet'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportPetScreen(reportType: 'lost'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.pets, color: Colors.green),
                title: Text('Report Found Pet'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ReportPetScreen(reportType: 'found'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[20],
      appBar: AppBar(
        title: Text(
          'News Feed',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orangeAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilterChip(
                  label: Text('All'),
                  selected: filterType == 'all',
                  onSelected: (selected) {
                    setState(() => filterType = 'all');
                  },
                  backgroundColor: Colors.amber[100],
                  selectedColor: Colors.orange[200],
                ),
                FilterChip(
                  label: Text('Lost'),
                  selected: filterType == 'lost',
                  onSelected: (selected) {
                    setState(() => filterType = 'lost');
                  },
                  backgroundColor: Colors.amber[100],
                  selectedColor: Colors.orange[200],
                ),
                FilterChip(
                  label: Text('Found'),
                  selected: filterType == 'found',
                  onSelected: (selected) {
                    setState(() => filterType = 'found');
                  },
                  backgroundColor: Colors.amber[100],
                  selectedColor: Colors.orange[200],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fetchReports(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error loading reports: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final reports = snapshot.data!.docs;

                if (reports.isEmpty) {
                  return Center(
                      child:
                          Text('No reports available for the selected filter'));
                }

                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = reports[index];
                    return PetReportCard(doc: doc, onLike: toggleLike);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showReportOptions,
        child: Icon(Icons.add),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }
}

class PetReportCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final Function(DocumentSnapshot) onLike;

  PetReportCard({required this.doc, required this.onLike});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String animalType = data['animalType'] ?? '';
    String breed = data['breed'] ?? '';
    String location = data['location'] ?? '';
    String imageUrl = data['imageUrl'] ?? '';
    Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
    int likes = data['likes'] ?? 0;
    List likedBy = data['likedBy'] ?? [];
    List comments = data['comments'] ?? [];
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    DateTime postedTime = timestamp.toDate();
    String timeAgo = timeago.format(postedTime);

    bool isLiked = likedBy.contains(userId);

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetReportDetailScreen(doc: doc),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: Icon(Icons.error, color: Colors.red),
                        );
                      },
                    )
                  : Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child:
                          Icon(Icons.pets, size: 80, color: Colors.grey[500]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '$animalType - $breed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: data['type'] == 'lost'
                              ? Colors.red[100]
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data['type'] == 'lost' ? 'Lost' : 'Found',
                          style: TextStyle(
                            color: data['type'] == 'lost'
                                ? Colors.red[700]
                                : Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.amber[700]),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.amber[700]),
                      SizedBox(width: 4),
                      Text(timeAgo, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => onLike(doc),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.orange[300],
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text('$likes'),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.comment_outlined,
                              color: Colors.orangeAccent, size: 20),
                          SizedBox(width: 4),
                          Text('${comments.length}'),
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
