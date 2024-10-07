import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:geolocator/geolocator.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;
  DocumentSnapshot? userDoc;
  String username = "";

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _initializeUserDoc();
  }

  Future<void> _initializeUserDoc() async {
    userDoc = await _firestore.collection('users').doc(user?.uid).get();
    setState(() {
      username = userDoc?['name'] ?? "";
    });
  }

  List<XFile>? _imageFiles = [];
  String postContent = "";
  String postVisibility = "Public"; // Default visibility
  List<String> hashtags = [];
  String? locationTag;
  bool isLoading = false;
  double uploadProgress = 0.0;

  Future<void> uploadPost() async {
    setState(() {
      isLoading = true;
    });

    // Upload images to Firebase Storage
    List<String> imageUrls = [];
    for (var imageFile in _imageFiles!) {
      String? imageUrl = await uploadImage(imageFile);
      if (imageUrl != null) {
        imageUrls.add(imageUrl);
      }
    }

    // Create the post in Firestore
    final user = _auth.currentUser;
    await _firestore.collection('posts').add({
      'content': postContent,
      'userId': user?.uid,
      'username': username,
      'images': imageUrls,
      'likes': 0,
      'comments': [],
      'timestamp': FieldValue.serverTimestamp(),
      'visibility': postVisibility,
      'hashtags': hashtags,
      'location': locationTag,
    });

    setState(() {
      isLoading = false;
      _imageFiles = [];
      postContent = "";
      hashtags = [];
      locationTag = null;
      uploadProgress = 0.0;
    });

    // Go back to the feed screen
    Navigator.pop(context);
  }

  Future<String?> uploadImage(XFile image) async {
    try {
      final userId = _auth.currentUser?.uid;
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('posts/$userId/${DateTime.now().millisecondsSinceEpoch}');
      UploadTask uploadTask = ref.putFile(File(image.path));

      // Listen for progress changes
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  void pickImage() async {
    final pickedImages = await _picker.pickMultiImage();
    setState(() {
      if (pickedImages != null) {
        _imageFiles = pickedImages;
      }
    });
  }

 /* Future<void> getLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      locationTag = "${position.latitude}, ${position.longitude}";
    });
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: isLoading || (postContent.isEmpty && _imageFiles!.isEmpty)
                  ? null
                  : uploadPost,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: Colors.orange,
                disabledForegroundColor: Colors.white,
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text("Post")
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Post something new",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            TextField(
              maxLines: null,
              decoration: InputDecoration(
                hintText: "What you're thinking right now...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  postContent = value;
                });
              },
            ),
            SizedBox(height: 20),
            // Picture upload button
            IconButton(
              icon: Icon(Icons.photo_library, size: 30),
              onPressed: pickImage,
            ),
            if (_imageFiles!.isNotEmpty)
              Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageFiles!.length + 1,
                  itemBuilder: (context, index) {
                    if (index < _imageFiles!.length) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.file(
                          File(_imageFiles![index].path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    } else {
                      return GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add),
                        ),
                      );
                    }
                  },
                ),
              ),
            SizedBox(height: 20),
            // Upload progress indicator
            if (uploadProgress > 0 && uploadProgress < 1)
              LinearProgressIndicator(value: uploadProgress),
            SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.location_on, color: Colors.black),
                  label: Text("Location", style: TextStyle(color: Colors.black)),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    // Handle privacy change
                  },
                  icon: Icon(Icons.public, color: Colors.black),
                  label: DropdownButton<String>(
                    value: postVisibility,
                    onChanged: (String? newValue) {
                      setState(() {
                        postVisibility = newValue!;
                      });
                    },
                    items: <String>['Public', 'Friends', 'Private']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            TextField(
              decoration: InputDecoration(
                hintText: "Add hashtags (separated by commas)",
              ),
              onChanged: (value) {
                setState(() {
                  hashtags = value.split(",").map((tag) => tag.trim()).toList();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
