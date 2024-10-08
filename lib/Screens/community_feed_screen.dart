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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Community Feed',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              color: Colors.black,
            ),
            onPressed: () {
              // Handle notifications icon tap here
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180.0,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('posts')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No posts yet.'));
                    }

                    final posts = snapshot.data!.docs;

                    if (index >= posts.length) {
                      return SizedBox.shrink(); // Empty widget if index out of range
                    }

                    final post = posts[index];

                    // Fetch post uploader's name
                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore
                          .collection('users')
                          .doc(post['userId'])
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                          return Center(child: Text('User data unavailable'));
                        }

                        final userName = userSnapshot.data!['name'] ?? 'User';

                        return _buildPostItem(context, post, userName);
                      },
                    );
                  },
                );
              },
              childCount: 1000, // Adjust based on your needs
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(
    BuildContext context, DocumentSnapshot post, String userName) {
  final postId = post.id;
  final content = post['content'] ?? 'No content available';
  final images = List<String>.from(post['images'] ?? []);
  final likes = post['likes'] ?? 0;
  final comments = List<String>.from(post['comments'] ?? []);

  return FutureBuilder<DocumentSnapshot>(
    future: _firestore.collection('users').doc(post['userId']).get(),
    builder: (context, userSnapshot) {
      if (userSnapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
        return Center(child: Text('User data unavailable'));
      }

      final userData = userSnapshot.data!;
      final userProfilePicture = userData['profilePhotoUrl'] ?? '';

      return PostCard(
        postId: postId,
        content: content,
        images: images,
        likes: likes,
        comments: comments,
        userName: userName,
        userProfilePicture: userProfilePicture, // Pass profile picture to PostCard
      );
    },
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
                image: NetworkImage(
                    'https://th.bing.com/th/id/R.86bebc8ceb313545207c639be56f0651?rik=JOO9Wnj8b0GWTA&riu=http%3a%2f%2fpngimg.com%2fuploads%2fdog%2fdog_PNG50380.png&ehk=othL9M41KKnxNrXWUSnkAmjsQ%2fiWbfeqyhCdWFCEDIQ%3d&risl=1&pid=ImgRaw&r=0'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 150,
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
                  hintStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
            bottom: 25,
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
}

class PostCard extends StatefulWidget {
  final String postId;
  final String content;
  final List<String> images;
  final int likes;
  final List<String> comments;
  final String userName;
  final String userProfilePicture;

  PostCard({
    required this.postId,
    required this.content,
    required this.images,
    required this.likes,
    required this.comments,
    required this.userName, 
    required this.userProfilePicture,
  });

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    checkIfLiked();
  }

  void checkIfLiked() async {
    final userId = _auth.currentUser?.uid;
    final likesDoc = await _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('likes')
        .doc(userId)
        .get();

    setState(() {
      isLiked = likesDoc.exists;
    });
  }

  void toggleLike() async {
    final userId = _auth.currentUser?.uid;
    final postRef = _firestore.collection('posts').doc(widget.postId);

    if (isLiked) {
      await postRef.collection('likes').doc(userId).delete();
      postRef.update({'likes': FieldValue.increment(-1)});
    } else {
      await postRef.collection('likes').doc(userId).set({});
      postRef.update({'likes': FieldValue.increment(1)});
    }

    setState(() {
      isLiked = !isLiked;
    });
  }

  void addComment(String commentText) async {
    final userId = _auth.currentUser?.uid;
    final comment = {
      'userId': userId,
      'comment': commentText,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add(comment);
  }

 @override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(2.0), // Add padding around the card
    child: Card(
      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Padding( // Add padding inside the card
        padding: const EdgeInsets.all(10.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                  radius: 20.0,
                  backgroundImage: widget.userProfilePicture.isNotEmpty
                      ? NetworkImage(widget.userProfilePicture)
                      : AssetImage('images/catpaw.png') // Fallback to a placeholder image
                          as ImageProvider,      
                ),
              title: Text(widget.userName, style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 10.0),
            Text(widget.content, style: TextStyle(fontSize: 18.0)),
            SizedBox(height: 10.0),
            if (widget.images.isNotEmpty)
              Column(
                children: widget.images
                    .map((imageUrl) => Image.network(imageUrl))
                    .toList(),
              ),
            SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: isLiked ? Colors.orange : null,
                  ),
                  onPressed: toggleLike,
                ),
                Text('${widget.likes} Likes', style: TextStyle(color: isLiked ? Colors.orange : null)),
                SizedBox(width: 16.0),
                IconButton(
                  icon: Icon(Icons.comment),
                  onPressed: () {
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return CommentSection(postId: widget.postId);
                        });
                  },
                ),
                Text('${widget.comments.length} Comments'), // Display comment count
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

}

class CommentSection extends StatefulWidget {
  final String postId;

  CommentSection({required this.postId});

  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void postComment() async {
    if (_commentController.text.isEmpty) return;

    await _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'text': _commentController.text,
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
      
    });

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('posts')
                .doc(widget.postId)
                .collection('comments')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No comments yet.'));
              }

              final comments = snapshot.data!.docs;

              return ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return ListTile(
                    title: Text(comment['text'] ?? 'No text'),
                    subtitle: FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('users').doc(comment['userId']).get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return Text('Loading...');
                        }
                        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                          return Text('User not found');
                        }
                        final userName = userSnapshot.data!['name'] ?? 'User';
                        return Text('User: $userName');
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(hintText: 'Enter your comment'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: postComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
