import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_screen.dart';

class PetPalPlusScreen extends StatefulWidget {
  @override
  _PetPalPlusScreenState createState() => _PetPalPlusScreenState();
}

class _PetPalPlusScreenState extends State<PetPalPlusScreen> {
  bool _isLoading = true;
  bool _isMember = false;

  @override
  void initState() {
    super.initState();
    _checkMembershipStatus();
  }

  Future<void> _checkMembershipStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var membershipSnapshot = await FirebaseFirestore.instance
        .collection('premium_memberships')
        .doc(user.uid)
        .get();

    setState(() {
      _isMember = membershipSnapshot.exists &&
          membershipSnapshot.data()?['membershipStatus'] == 'active';
      _isLoading = false;
    });
  }

  Future<void> _buyMembership() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentScreen(onSuccess: () async {
        await FirebaseFirestore.instance
            .collection('premium_memberships')
            .doc(user.uid)
            .set({
          'userId': user.uid,
          'membershipStatus': 'active',
          'startDate': Timestamp.now(),
          'plan': 'PetPal Plus',
        });

        setState(() {
          _isMember = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome to PetPal Plus!')));
      })),
    );
  }

  Future<void> _cancelMembership() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('premium_memberships')
        .doc(user.uid)
        .update({'membershipStatus': 'canceled'});

    setState(() {
      _isMember = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Membership canceled.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'PetPal Plus',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://images.unsplash.com/photo-1544568100-847a948585b9',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.white],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Elevate Your Pet Care Experience',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Join PetPal Plus and unlock a world of premium features designed to give your furry friends the VIP treatment they deserve!',
                          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 32),
                        _buildPriceInfo(),
                        SizedBox(height: 32),
                        _buildFeaturesList(),
                        SizedBox(height: 32),
                        if (!_isMember)
                          _buildJoinButton()
                        else
                          _buildMembershipStatus(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      '24/7 Vet Chat Support',
      'Personalized Pet Care Plans',
      'Exclusive Discounts on Products',
      'Priority Grooming Appointments',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premium Features',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 16),
        ...features.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.orange, size: 24),
                  SizedBox(width: 16),
                  Text(feature, style: TextStyle(fontSize: 18, color: Colors.black)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildPriceInfo() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '\$2.99',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'per month',
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _buyMembership,
        child: Text(
          'Join PetPal Plus',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          backgroundColor: Colors.orange,
          textStyle: TextStyle(fontSize: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
      ),
    );
  }

  Widget _buildMembershipStatus() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.pets, color: Colors.green, size: 36),
              SizedBox(width: 16),
              Text(
                'Active Plus Member',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Enjoy your premium benefits and give your pet the best care possible!',
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _cancelMembership,
            child: Text('Cancel Membership'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              textStyle: TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}