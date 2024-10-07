import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:petpal/Screens/create_post_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  @override
  _CommunityFeedScreenState createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String postContent = "";

  Future<String?> uploadImage(XFile image) async {
    try {
      final userId = _auth.currentUser?.uid;
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('posts/$userId/${DateTime.now().millisecondsSinceEpoch}');
      UploadTask uploadTask = ref.putFile(File(image.path));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> createPost() async {
    if (postContent.isEmpty) return;
    final user = _auth.currentUser;

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await uploadImage(_imageFile!);
    }

    await _firestore.collection('posts').add({
      'content': postContent,
      'userId': user?.uid,
      'images': imageUrl != null ? [imageUrl] : [],
      'likes': 0,
      'comments': [],
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      postContent = "";
      _imageFile = null;
    });
  }

  void pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Community Feed', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
            Icon(Icons.notifications_none, color: Colors.black),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200.0,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildFilterButton(),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('posts').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No posts yet.'));
                    }

                    final posts = snapshot.data!.docs;

                    // Ensure the index is valid before accessing the posts list
                    if (index >= posts.length) {
                      return SizedBox.shrink(); // Return an empty widget if the index is out of range
                    }

                    final post = posts[index];

                    // Return the PostCard with dynamic data for each post
                    return _buildPostItem(context, post);
                  },
                );
              },
              childCount: 1000, // A large number, adjust based on your needs
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, DocumentSnapshot post) {
    final postId = post.id;
    final content = post['content'] ?? 'No content available';
    final images = List<String>.from(post['images'] ?? []);
    final likes = post['likes'] ?? 0;
    final comments = List<String>.from(post['comments'] ?? []);

    return PostCard(
      postId: postId,
      content: content,
      images: images,
      likes: likes,
      comments: comments,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              image: DecorationImage(
                image: NetworkImage('https://th.bing.com/th/id/R.86bebc8ceb313545207c639be56f0651?rik=JOO9Wnj8b0GWTA&riu=http%3a%2f%2fpngimg.com%2fuploads%2fdog%2fdog_PNG50380.png&ehk=othL9M41KKnxNrXWUSnkAmjsQ%2fiWbfeqyhCdWFCEDIQ%3d&risl=1&pid=ImgRaw&r=0'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Colors.black.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: 105,
            top: 16,
            child: Container(
              width: MediaQuery.of(context).size.width - 32,
              child: TextField(
                decoration: InputDecoration(
                  hintText: "How do you create your post?",
                  hintStyle: TextStyle(color: Colors.black, fontSize: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                ),
                onChanged: (value) {
                  setState(() {
                    postContent = value;
                  });
                },
              ),
            ),
          ),
          Positioned(
            right: 25,
            bottom: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreatePostScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text("Create"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.filter_list),
            label: Text('Filter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: Size(30, 30),
            ),
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final String postId;
  final String content;
  final List<String> images;
  final int likes;
  final List<String> comments;

  PostCard({
    required this.postId,
    required this.content,
    required this.images,
    required this.likes,
    required this.comments,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage('https://th.bing.com/th/id/OIP.jryuUgIHWL-1FVD2ww8oWgHaHa?rs=1&pid=ImgDetMain'),
                  radius: 20.0,
                ),
                SizedBox(width: 8.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Golden Retriever • Mobile', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () {
                    // Handle post options
                  },
                ),
              ],
            ),
            SizedBox(height: 12.0),
            Text(content, style: TextStyle(fontSize: 16.0)),
            SizedBox(height: 12.0),
            if (images.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(images[index], fit: BoxFit.cover),
                  );
                },
              ),
            SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.thumb_up, color: Colors.orangeAccent),
                      onPressed: () {
                        // Handle like
                      },
                    ),
                    Text('$likes'),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.comment, color: Colors.black),
                      onPressed: () {
                        // Handle comments
                      },
                    ),
                    Text('Comments (${comments.length})'),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.share, color: Colors.black),
                  onPressed: () {
                    // Handle share
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
