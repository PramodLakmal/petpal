import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String selectedUserId;
  final String selectedUserName;

  ChatScreen({required this.selectedUserId, required this.selectedUserName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late String _currentUserId;
  String? _currentUserName; // Allow null until loaded
  String? _currentUserProfilePhotoUrl; // Add for the current user
  String? receiverProfilePhotoUrl; // Add for the receiver
  bool _isLoading = true; // To track loading state

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
  }

  // Function to get current user's ID and Name
  void _getCurrentUserId() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.uid;

      // Fetch current user's name
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      setState(() {
        _currentUserName = userDoc['name']; // Store the current user's name
        _currentUserProfilePhotoUrl =
            userDoc['profilePhotoUrl']; // Store profile photo URL
        _isLoading = false; // Data has been fetched, stop loading
      });
    }
  }

  // Function to get receiver's user ID and profile photo URL by their name
  Future<Map<String, String?>> _getReceiverUserDetails(String receiverName) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('name', isEqualTo: receiverName)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      var userDoc = querySnapshot.docs.first;
      return {
        'userId': userDoc.id, // User ID
        'profilePhotoUrl': userDoc['profilePhotoUrl'], // Profile photo URL
      };
    }
    return {'userId': null, 'profilePhotoUrl': null}; // Return nulls if no user was found
  }

  // Function to send a message
  void _sendMessage(String message) async {
    if (message.isEmpty || _currentUserName == null) {
      print("Message is empty or user data is not ready"); // Debug statement
      return;
    }

    Map<String, String?> receiverDetails = await _getReceiverUserDetails(widget.selectedUserName);
    String? receiverUserId = receiverDetails['userId'];
    String? receiverProfilePhotoUrl = receiverDetails['profilePhotoUrl'];

    if (receiverUserId == null) {
      print("Receiver user ID not found");
      return; // Exit if the receiver user ID couldn't be found
    }

    await _firestore.collection('messages').add({
      'senderName': _currentUserName,
      'sender': _currentUserId,
      'receiverName': widget.selectedUserName,
      'receiver': receiverUserId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'senderProfilePhotoUrl': _currentUserProfilePhotoUrl,
      'receiverProfilePhotoUrl': receiverProfilePhotoUrl,
    });

    await _firestore
        .collection('chats')
        .doc(_getChatDocId())
        .set({
      'userIds': [_currentUserId, widget.selectedUserId, receiverUserId],
      'lastMessage': message,
      'senderName': _currentUserName,
      'receiverName': widget.selectedUserName,
      'timestamp': FieldValue.serverTimestamp(),
      'senderProfilePhotoUrl': _currentUserProfilePhotoUrl,
      'receiverProfilePhotoUrl': receiverProfilePhotoUrl,
    }, SetOptions(merge: true)); // Merge to avoid overwriting other data

    print("Message sent successfully!"); // Debug statement
    _messageController.clear();
  }

  String _getChatDocId() {
    List<String> ids = [_currentUserId, widget.selectedUserId];
    ids.sort(); // Ensure consistent order
    return ids.join('_'); // Return a concatenated string as the document ID
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(receiverProfilePhotoUrl ??
                  'https://www.citypng.com/public/uploads/preview/download-profile-user-round-orange-icon-symbol-png-11639594360ksf6tlhukf.png'), // Default avatar
            ),
            SizedBox(width: 10),
            Text(widget.selectedUserName),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange,))
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('messages')
                        .where('sender', whereIn: [_currentUserId, widget.selectedUserId])
                        .where('receiver', whereIn: [_currentUserId, widget.selectedUserId])
                        .orderBy('timestamp', descending: false) // Order by timestamp ascending
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator(color: Colors.orange,));
                      }

                      final messages = snapshot.data!.docs;

                      return ListView.builder(
                        reverse: false, // Latest messages at the bottom
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final messageData = messages[index].data() as Map<String, dynamic>; // Ensure you get data as Map
                          final message = messageData['message'];
                          final senderId = messageData['sender'];

                          return ListTile(
                            leading: senderId == _currentUserId
                                ? null // If the current user sent the message, don't show avatar
                                : CircleAvatar(
                                    backgroundImage: NetworkImage(receiverProfilePhotoUrl ??
                                        'https://www.citypng.com/public/uploads/preview/download-profile-user-round-orange-icon-symbol-png-11639594360ksf6tlhukf.png'), // Receiver's avatar
                                  ),
                            title: Align(
                              alignment: senderId == _currentUserId
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: senderId == _currentUserId
                                      ? Colors.orange[100]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(message),
                              ),
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
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: '     Enter a message',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.grey[100]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.orange), // Change to desired color
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          _sendMessage(_messageController.text);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
