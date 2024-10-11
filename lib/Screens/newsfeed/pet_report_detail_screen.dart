import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'edit_report_screen.dart';

class PetReportDetailScreen extends StatefulWidget {
  final DocumentSnapshot doc;

  PetReportDetailScreen({required this.doc});

  @override
  _PetReportDetailScreenState createState() => _PetReportDetailScreenState();
}

class _PetReportDetailScreenState extends State<PetReportDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _commentsToShow = 5;

  Future<void> _toggleLike() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var docRef =
        FirebaseFirestore.instance.collection('pet_reports').doc(widget.doc.id);
    var currentLikes = List<String>.from(widget.doc['likedBy'] ?? []);
    var likesCount = widget.doc['likes'] ?? 0;

    if (currentLikes.contains(user.uid)) {
      currentLikes.remove(user.uid);
      likesCount--;
    } else {
      currentLikes.add(user.uid);
      likesCount++;
    }

    await docRef.update({
      'likes': likesCount,
      'likedBy': currentLikes,
    });
  }

  Future<void> _addComment() async {
    User? user = FirebaseAuth.instance.currentUser;
    String comment = _commentController.text.trim();
    if (user == null || comment.isEmpty) return;

    var docRef =
        FirebaseFirestore.instance.collection('pet_reports').doc(widget.doc.id);

    var commentData = {
      'userId': user.uid,
      'comment': comment,
      'timestamp': Timestamp.now(),
    };

    await docRef.update({
      'comments': FieldValue.arrayUnion([commentData]),
    });

    setState(() {
      _commentController.clear();
    });
  }

  Future<void> _markAsSolved() async {
    await FirebaseFirestore.instance
        .collection('pet_reports')
        .doc(widget.doc.id)
        .update({'status': 'solved'});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pet_reports')
          .doc(widget.doc.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var reportData = snapshot.data!.data() as Map<String, dynamic>;
        bool isOwner =
            FirebaseAuth.instance.currentUser?.uid == reportData['userId'];
        bool isSolved = reportData['status'] == 'solved';

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: NestedScrollView(
                    headerSliverBuilder:
                        (BuildContext context, bool innerBoxIsScrolled) {
                      return <Widget>[
                        SliverAppBar(
                          backgroundColor: Colors.orangeAccent,
                          expandedHeight: 300,
                          floating: false,
                          pinned: true,
                          flexibleSpace: FlexibleSpaceBar(
                            title: Text(
                                '${reportData['animalType']} (${reportData['breed']})'),
                            background: Image.network(
                              reportData['imageUrl'],
                              fit: BoxFit.cover,
                            ),
                          ),
                          actions: [
                            if (isOwner)
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditReportScreen(doc: widget.doc),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ];
                    },
                    body: SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoCard(reportData),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        _buildLikeSection(),
                                      ],
                                    ),
                                    if (isOwner)
                                      ElevatedButton(
                                        onPressed:
                                            isSolved ? null : _markAsSolved,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isSolved
                                              ? Colors.grey
                                              : Colors.orangeAccent,
                                        ),
                                        child: Text(
                                            isSolved
                                                ? 'Solved'
                                                : 'Mark as Solved',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14)),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                Text(
                                  'Comments',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[800]),
                                ),
                                SizedBox(height: 8),
                                _buildCommentSection(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildCommentInput(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> reportData) {
    String timeAgo = timeago.format(reportData['timestamp'].toDate());

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.redAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reportData['location'],
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.pets, color: Colors.brown),
                SizedBox(width: 8),
                Text(
                  'Color: ${reportData['color']}',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.orangeAccent),
                SizedBox(width: 8),
                Text(
                  'Posted: $timeAgo',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text(
                  'Reported by: ${reportData['name']}',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.greenAccent),
                SizedBox(width: 8),
                Text(
                  'Contact: ${reportData['contactNumber']}',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pet_reports')
          .doc(widget.doc.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();

        var report = snapshot.data!.data() as Map<String, dynamic>;
        bool isLiked = List<String>.from(report['likedBy'])
            .contains(FirebaseAuth.instance.currentUser!.uid);
        int likes = report['likes'] ?? 0;

        return Row(
          children: [
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: IconButton(
                key: ValueKey<bool>(isLiked),
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey,
                ),
                onPressed: _toggleLike,
              ),
            ),
            Text(
              '$likes likes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pet_reports')
          .doc(widget.doc.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber)));
        }

        var updatedReportData = snapshot.data!.data() as Map<String, dynamic>;
        var comments = updatedReportData['comments'] ?? [];

        List reversedComments = List.from(comments.reversed);
        int totalComments = reversedComments.length;

        return Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _commentsToShow > totalComments
                  ? totalComments
                  : _commentsToShow,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.amber[100]),
              itemBuilder: (context, index) {
                var comment = reversedComments[index];
                return _buildCommentTile(comment, updatedReportData['userId']);
              },
            ),
            if (_commentsToShow < totalComments)
              TextButton(
                onPressed: () {
                  setState(() {
                    _commentsToShow += 5;
                  });
                },
                child: Text('Load more comments',
                    style: TextStyle(color: Colors.amber[800])),
              ),
            if (_commentsToShow >= totalComments && totalComments > 5)
              TextButton(
                onPressed: () {
                  setState(() {
                    _commentsToShow = 5;
                  });
                },
                child: Text('Show less comments',
                    style: TextStyle(color: Colors.amber[800])),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> comment, String reportUserId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(comment['userId'])
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String commenterName = userData['name'] ?? 'Anonymous';
        String commenterImageUrl = userData['profileImageUrl'] ??
            'https://www.example.com/placeholder.jpg';
        bool isAuthor = comment['userId'] == reportUserId;

        String timeAgo = timeago.format(comment['timestamp'].toDate());

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(commenterImageUrl),
            radius: 20,
          ),
          title: Row(
            children: [
              Text(
                commenterName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              if (isAuthor)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Author',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(comment['comment']),
              SizedBox(height: 4),
              Text(
                timeAgo,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _addComment,
            ),
          ),
        ],
      ),
    );
  }
}
