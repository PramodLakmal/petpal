import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'pet_report_detail_screen.dart';
import 'report_pet_screen.dart';

class NewsFeedScreen extends StatefulWidget {
  @override
  _NewsFeedScreenState createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen>
    with SingleTickerProviderStateMixin {
  String filterType = 'all';
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            filterType = 'all';
            break;
          case 1:
            filterType = 'lost';
            break;
          case 2:
            filterType = 'found';
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.25,
          minChildSize: 0.2,
          maxChildSize:
              0.25, 
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey[100]!], // Soft gradient
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle with modern design
                  GestureDetector(
                    onTap: () {
                      // Optionally make this tappable to expand or collapse the sheet
                    },
                    child: Container(
                      margin: EdgeInsets.only(top: 10),
                      width: 50,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  SizedBox(height: 15), // Space between handle and content
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      children: [
                        // Redesigned ListTile for 'Report Lost Pet'
                        _buildCustomTile(
                          icon: Icons.pets,
                          iconColor: Colors.red,
                          title: 'Report Lost Pet',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ReportPetScreen(reportType: 'lost'),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 15), // Space between tiles
                        // Redesigned ListTile for 'Report Found Pet'
                        _buildCustomTile(
                          icon: Icons.pets,
                          iconColor: Colors.green,
                          title: 'Report Found Pet',
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Custom ListTile Builder Function
  Widget _buildCustomTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Custom Icon with circular background
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            SizedBox(width: 20),
            // Title Text with modern style
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[50],
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.orangeAccent,
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('News Feed',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'images/login.png',
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.orangeAccent,
                  labelColor: Colors.black87,
                  unselectedLabelColor: Colors.black54,
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Lost'),
                    Tab(text: 'Found'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: StreamBuilder<QuerySnapshot>(
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
                  child: Text('No reports available for the selected filter'));
            }

            return MasonryGridView.count(
              crossAxisCount: 2,
              itemCount: reports.length,
              itemBuilder: (context, index) {
                DocumentSnapshot doc = reports[index];
                return PetReportCard(doc: doc, onLike: toggleLike);
              },
              mainAxisSpacing: 4.0,
              crossAxisSpacing: 4.0,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportOptions,
        icon: Icon(Icons.add),
        label: Text('Report'),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.error),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
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
                            fontSize: 16,
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
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: Colors.amber[700]),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
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
                          size: 14, color: Colors.amber[700]),
                      SizedBox(width: 4),
                      Text(timeAgo,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => onLike(doc),
                        child: Row(
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.orange[300],
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text('$likes', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.comment_outlined,
                              color: Colors.orangeAccent, size: 18),
                          SizedBox(width: 4),
                          Text('${comments.length}',
                              style: TextStyle(fontSize: 12)),
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
