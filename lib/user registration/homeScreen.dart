import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petpal/Screens/community_chat_screen.dart';
import 'package:petpal/Screens/community_feed_screen.dart';
import 'package:petpal/user%20registration/login.dart';
import 'package:petpal/user%20registration/newpet.dart';
import 'package:petpal/user%20registration/petprofile.dart';
import 'package:petpal/user%20registration/userprofile.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomescreenState();
  const HomeScreen({super.key});
}

class _HomescreenState extends State<HomeScreen> {
  // Function to fetch pets from Firestore for the currently logged-in user
  Stream<QuerySnapshot> _getPets() {
    User? user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('pets')
        .where('userId', isEqualTo: user!.uid)
        .snapshots();
  }

  int selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    Center(child: Text('Home Page Content', style: TextStyle(fontSize: 24))),
    CommunityFeedScreen(),
    AddPet(),
    CommunityChatScreen(),
    UserProfile()
  ];

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: (selectedIndex == 0) // Show AppBar for home and profile only
          ? AppBar(
              backgroundColor: Colors.blue,
              title: const Center(
                child: Text(
                  "PetPal",
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      letterSpacing: 1.2),
                ),
              ),
            )
          : null,
      body: selectedIndex == 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image and Header Section
                SizedBox(
                  width: double.infinity,
                  height: height / 3.5,
                  child: Image.asset(
                    "images/login.png",
                    height: 40,
                  ),
                ),
                const SizedBox(height: 20),

                // "My Pets" Section with Title and Paw Icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Text(
                            "My Pets",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                          SizedBox(width: 10),
                          Image(
                            image: AssetImage("images/catpaw.png"),
                            height: 30,
                            width: 30,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.orangeAccent),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AddPet()));
                        },
                      )
                    ],
                  ),
                ),

                // Search bar (optional)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search ...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),

                // Fetching and Displaying Pet Data
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _getPets(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text("No pets found for the current user."),
                        );
                      }

                      // Display list of pets
                      var pets = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: pets.length,
                        itemBuilder: (context, index) {
                          var pet = pets[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Container(
                              width: double
                                  .infinity, // Set width to fill the available space
                              height: 200,
                              // Set a fixed height for the card
                              child: Card(
                                color: Colors.amber,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        15), // Round the corners
                                    child: Image.asset(
                                      "images/catpaw.png", // Use a placeholder or actual image
                                      fit: BoxFit
                                          .cover, // Cover the entire space of the rectangle
                                      width: 60, // Set a width for the image
                                      height: 60, // Set a height for the image
                                    ),
                                  ),
                                  title: Text(
                                    pet['name'],
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Card(
                                      color: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text('"${pet['description']}"')),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => PetProfile(
                                                  name: pet['name'],
                                                  breed: pet['breed'],
                                                  age: pet['age'],
                                                  gender: pet['gender'],
                                                  weight: pet['weight'],
                                                  petId: pet.id,
                                                  //  imageUrl: pet['imageUrl'],
                                                )));
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            )
          : _pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.pets,
            ),
            label: 'My pets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            label: 'Add Pet',
          ),
          
          BottomNavigationBarItem(
            icon: Icon(Icons.message), 
            label: 'Chat'
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),
          
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Colors.orange,
        selectedLabelStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
    );
  }
}
