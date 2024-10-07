import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/Screens/chat_screen.dart';

class UserSelectionScreen extends StatefulWidget {
  @override
  _UserSelectionScreenState createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = user.displayName ?? 'Anonymous';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Go back action
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.black),
            onPressed: () {
              // Action to add new contacts
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                hintText: 'Search a Friend',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                // Implement search functionality if needed
              },
            ),
          ),

          // Horizontal avatars at the top
          Container(
            height: 90,
            padding: const EdgeInsets.only(left: 10),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;

                if (users.isEmpty) {
                  return Center(child: Text('No users available'));
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>?;

                    if (user == null) {
                      print('User data is null for document: ${users[index].id}');
                      return Container(); // Return empty container for invalid user
                    }

                    final userId = users[index].id;
                    final userName = user['name'] ?? 'Unknown User';
                    final userAvatar = user['profilePhotoUrl'] ??
                        'https://cdn-icons-png.flaticon.com/512/5404/5404433.png';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              selectedUserId: userId,
                              selectedUserName: userName,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(userAvatar),
                            radius: 30,
                          ),
                          SizedBox(height: 5),
                          Text(
                            userName,
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // List of chat contacts (showing last message and timestamp)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .where('userIds', arrayContains: _currentUserId) // Fetch chats where current user is involved
                  .orderBy('timestamp', descending: true) // Order by the latest message
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final chats = snapshot.data!.docs;

                if (chats.isEmpty) {
                  return Center(child: Text('No chats available'));
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chatData = chats[index].data() as Map<String, dynamic>?;

                    if (chatData == null) {
                      print('Chat data is null for document: ${chats[index].id}');
                      return Container();
                    }

                    final userIds = chatData['userIds'] as List<dynamic>;
                    final otherUserId = userIds.firstWhere(
                      (id) => id != _currentUserId,
                      orElse: () => null,
                    );

                    // Attempt to fetch the other user's information
                    final lastMessage = chatData['lastMessage'] ?? '';
                    final timestamp = chatData['timestamp'] as Timestamp?;
                    final userAvatar = chatData['senderProfilePhotoUrl'] ??
                        'https://cdn-icons-png.flaticon.com/512/5404/5404433.png';
                    final userName = chatData['senderName'] ?? 'Unknown User'; // Get the receiver name

                    // Fallback to the other user's ID if the name is not available
                    if (otherUserId != null) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(userAvatar),
                        ),
                        title: Text(userName),
                        subtitle: Text(lastMessage),
                        trailing: Text(
                          timestamp != null ? _formatTimestamp(timestamp) : '',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          // Navigate to chat screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                selectedUserId: otherUserId,
                                selectedUserName: userName, // Use the receiver name
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      print("Error: Couldn't find the other user in this chat.");
                      return Container(); // Handle error gracefully
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to format timestamp (example formatting)
  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return "${dateTime.hour}:${dateTime.minute}";
  }
}
