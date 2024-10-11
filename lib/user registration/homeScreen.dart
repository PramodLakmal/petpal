import 'dart:async'; // For Timer
import 'dart:convert'; // For Base64 decoding
import 'dart:typed_data'; // For handling byte data

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petpal/Screens/adoption/adoption.dart';
import 'package:petpal/Screens/appointment/doctor_search_page.dart';
import 'package:petpal/Screens/community_chat_screen.dart';
import 'package:petpal/Screens/community_feed_screen.dart';
import 'package:petpal/user%20registration/login.dart';
import 'package:petpal/user%20registration/newpet.dart';

import 'package:petpal/user%20registration/petprofile.dart';
import 'package:petpal/user%20registration/userprofile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController; // Declare the PageController
  int _currentPage = 0;
  late Timer _timer;

  // Add a TextEditingController for the search bar
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _images = [
    "images/1.jpg",
    "images/2.jpg",
    "images/3.jpg" // Second image
    // Third image (You can add more images here)
  ];
  late AnimationController _animationController; // Controller for animation
  late Animation<double> _animation; // Animation variable for rotation

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(initialPage: 0); // Initialize the PageController
    _startImageCarousel();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true); // Repeat the animation

    // Create a tween for the rotation animation
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose(); // Dispose of the PageController
    _timer.cancel(); // Cancel the timer to avoid memory leaks
    _searchController.dispose(); // Dispose of the search controller
    _animationController.dispose(); // Dispose of the animation controller
    super.dispose();
  }

  void _startImageCarousel() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < _images.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  // Fetch the user profile from Firestore
  Future<DocumentSnapshot> _getUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
  }

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
    UserSelectionScreen(),
    UserProfile()
  ];

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  // Helper method to safely parse age
  int _parseAge(dynamic age) {
    if (age is int) {
      return age;
    } else if (age is String) {
      return int.tryParse(age) ?? 0;
    } else if (age is double) {
      return age.toInt();
    } else {
      return 0; // Default value
    }
  }

  // Helper method to safely parse weight
  double _parseWeight(dynamic weight) {
    if (weight is double) {
      return weight;
    } else if (weight is int) {
      return weight.toDouble();
    } else if (weight is String) {
      return double.tryParse(weight) ?? 0.0;
    } else {
      return 0.0; // Default value
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: (selectedIndex == 0)
          ? AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 112.0,
              backgroundColor: const Color(0xFFFA6650),
              title: StreamBuilder<DocumentSnapshot>(
                stream: _getUserProfile().asStream(),
                builder: (context, userSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _getPets(),
                    builder: (context, petSnapshot) {
                      int petCount = 0;
                      if (petSnapshot.hasData) {
                        petCount = petSnapshot
                            .data!.docs.length; // Count the number of pets
                      }

                      // Time-based greeting
                      String greeting;
                      final hour = DateTime.now().hour;
                      if (hour < 12) {
                        greeting = 'Good morning';
                      } else if (hour < 17) {
                        greeting = 'Good afternoon';
                      } else {
                        greeting = 'Good evening';
                      }

                      // Medal based on pet count
                      String medalType;
                      Color medalColor;
                      if (petCount > 7) {
                        medalType = "Gold ";
                        medalColor = Colors.yellow; // Gold color
                      } else if (petCount >= 2) {
                        medalType = "Bronze ";
                        medalColor = Color(0xFFCD7F32); // Bronze color
                      } else {
                        medalType = "Silver ";
                        medalColor = Colors.grey; // Silver color
                      }

                      // Get user name
                      String userName = "User"; // Default user name
                      if (userSnapshot.hasData) {
                        var userData =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        userName = userData['name'] ??
                            userName; // Get user name from Firestore
                      }

                      return Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: medalColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedBuilder(
                                      animation: _animation,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle: _animation.value *
                                              .5 *
                                              3.14, // Rotate by 360 degrees
                                          child: const Icon(Icons.star,
                                              color: Colors.white),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      medalType,
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                  height:
                                      4), // Space between medal and greeting
                              Text(
                                greeting, // Display time-based greeting
                                style: const TextStyle(
                                    fontSize: 20, color: Colors.white),
                              ),
                              const SizedBox(
                                  height:
                                      4), // Space between greeting and username
                              Text(
                                userName, // Display user's name
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                          const Spacer(), // Pushes the content to the left
                        ],
                      );
                    },
                  );
                },
              ),
            )
          : null,
      body: selectedIndex == 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image carousel section
                SizedBox(
                  width: double.infinity,
                  height: height / 3.5,
                  child: PageView.builder(
                    controller: _pageController, // Use the PageController
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Image.asset(
                        _images[index],
                        height: 40,
                        fit: BoxFit
                            .cover, // Ensure the image covers the container
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // "Category" Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Category",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                // Horizontal Category Scroll Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryItem(Icons.event_note, "Notices"),
                        _buildCategoryItem(Icons.schedule, "Appointment",
                            onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DoctorSearchPage(), // Navigate to AdoptionPage
                            ),
                          );
                        }), // Navigate to DoctorSearchPage
                        _buildCategoryItem(Icons.pets, "Adoption", onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AdoptionPage(), // Navigate to AdoptionPage
                            ),
                          );
                        }),
                        _buildCategoryItem(Icons.shopping_cart, "Pet Market"),
                        _buildCategoryItem(
                            Icons.miscellaneous_services, "Services"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // "My Pets" Section with Title and Paw Icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                    ],
                  ),
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10),
                  child: TextField(
                    controller: _searchController, // Assign the controller
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.grey[200],
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(30)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(30)),
                      hintText: "Search ...",
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery =
                            value.toLowerCase(); // Update the search query
                      });
                    },
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

                      // Filter pets based on search query
                      var pets = snapshot.data!.docs.where((pet) {
                        return pet['name']
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery);
                      }).toList();

                      // Display list of pets
                      return ListView.builder(
                        itemCount: pets.length,
                        itemBuilder: (context, index) {
                          var pet = pets[index];
                          var imageBase64 = pet['imageBase64'];

                          Uint8List? imageBytes;
                          if (imageBase64 != null && imageBase64.isNotEmpty) {
                            try {
                              imageBytes = base64Decode(imageBase64);
                            } catch (e) {
                              print(
                                  'Error decoding image for pet ${pet.id}: $e');
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              children: [
                                Container(
                                  width: double
                                      .infinity, // Set width to fill the available space
                                  height:
                                      200, // Set a fixed height for the card
                                  child: Card(
                                    color: Colors.pink[50],
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(
                                          16.0), // Padding inside the ListTile
                                      title: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Left side: Image container
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                15), // Rounded corners for the image
                                            child: Container(
                                              width: 150, // Adjusted width
                                              height:
                                                  150, // Adjusted height for better fit
                                              color: Colors.grey[300],
                                              child: imageBytes == null
                                                  ? Image.asset(
                                                      "images/catpaw.png",
                                                      fit: BoxFit.contain,
                                                    )
                                                  : Image.memory(
                                                      imageBytes,
                                                      fit: BoxFit.cover,
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(
                                              width:
                                                  16), // Space between image and text
                                          // Right side: Name and Description
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                                  child: Text(
                                                    pet['name'],
                                                    style: const TextStyle(
                                                      fontSize:
                                                          24, // Adjust font size for the name
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                    height:
                                                        8), // Space between name and description
                                                Center(
                                                  child: Container(
                                                    height: 50,
                                                    width: double.infinity,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10),
                                                    child: Text(
                                                      pet['description'],
                                                      style: const TextStyle(
                                                          fontSize:
                                                              16, // Adjust font size for description
                                                          color: Colors.black
                                                          // Optional: Add color for description
                                                          ),
                                                      maxLines:
                                                          2, // Limit the number of description lines
                                                      overflow: TextOverflow
                                                          .ellipsis, // Add ellipsis if text overflows
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        // Safely parse age and weight
                                        int petAge = _parseAge(pet['age']);
                                        double petWeight =
                                            _parseWeight(pet['weight']);

                                        // Debugging: Print types and values
                                        print('Navigating to PetProfile with:');
                                        print('Name: ${pet['name']}');
                                        print('Breed: ${pet['breed']}');
                                        print(
                                            'Age: $petAge (type: ${petAge.runtimeType})');
                                        print(
                                            'Weight: $petWeight (type: ${petWeight.runtimeType})');

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PetProfile(
                                              name: pet['name'],
                                              breed: pet['breed'],
                                              age: petAge, // Now safely int
                                              gender: pet['gender'],
                                              weight:
                                                  petWeight, // Now safely double
                                              petId: pet.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
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
              Icons.home,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            label: 'Add Pet',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chat'),
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
            TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
    );
  }

  // Helper function to build a category item with tap support
  Widget _buildCategoryItem(IconData iconData, String label,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color.fromARGB(
                  255, 255, 171, 64), // Updated color for icons
              child: Icon(iconData, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
