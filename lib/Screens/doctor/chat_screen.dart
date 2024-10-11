import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  final String doctorId;

  const ChatScreen({Key? key, required this.doctorId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  File? _selectedImage;
  String? doctorName;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getDoctorName();
  }

  Future<void> _getDoctorName() async {
    DocumentSnapshot doctorSnapshot = await FirebaseFirestore.instance
        .collection('temp_d')
        .doc(widget.doctorId)
        .get();

    if (doctorSnapshot.exists) {
      setState(() {
        doctorName = doctorSnapshot['name'];
      });
    }
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    if (_messageController.text.trim().isEmpty && imageUrl == null) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('doctor_chats').add({
      'doctorId': widget.doctorId,
      'userId': user.uid,
      'message': _messageController.text.trim(),
      'imageUrl': imageUrl,
      'timestamp': Timestamp.now(),
    });

    _messageController.clear();
    _scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      User? user = FirebaseAuth.instance.currentUser;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('doctor_chats/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(_selectedImage!);
      final imageUrl = await storageRef.getDownloadURL();

      _sendMessage(imageUrl: imageUrl);
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance.collection('doctor_chats').doc(messageId).delete();
  }

  Future<void> _editMessage(String messageId, String currentText) async {
    TextEditingController editController = TextEditingController(text: currentText);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Message'),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(hintText: 'Edit your message'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (editController.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('doctor_chats')
                      .doc(messageId)
                      .update({'message': editController.text.trim()});
                }
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: Text(
          doctorName != null ? 'Dr. $doctorName' : 'Chat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          CircleAvatar(
            backgroundColor: Colors.orangeAccent,
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('doctor_chats')
                    .where('doctorId', isEqualTo: widget.doctorId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
                  }

                  var messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index].data() as Map<String, dynamic>;
                      String messageId = messages[index].id;
                      bool isCurrentUser = message['userId'] == FirebaseAuth.instance.currentUser!.uid;

                      return Align(
                        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: isCurrentUser
                              ? () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext bc) {
                                      return Wrap(
                                        children: [
                                          ListTile(
                                            leading: Icon(Icons.edit, color: Colors.orangeAccent),
                                            title: Text('Edit'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _editMessage(messageId, message['message'] ?? '');
                                            },
                                          ),
                                          ListTile(
                                            leading: Icon(Icons.delete, color: Colors.red),
                                            title: Text('Delete'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _deleteMessage(messageId);
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              : null,
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCurrentUser ? Colors.orangeAccent : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message['imageUrl'] != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      message['imageUrl'],
                                      width: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                if (message['message'] != null)
                                  Text(
                                    message['message'],
                                    style: TextStyle(
                                      color: isCurrentUser ? Colors.white : Colors.black87,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.photo, color: Colors.orangeAccent),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.send, color: Colors.white),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}