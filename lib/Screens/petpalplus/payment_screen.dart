import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  final Function onSuccess;

  PaymentScreen({required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Payment Method'),
        backgroundColor: Colors.amber[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 30),
            Text(
              'Enter your card details to purchase PetPal Plus',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            TextField(
              decoration: InputDecoration(
                labelText: 'Card Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Expiry Date',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'CVV',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Simulate a successful payment
                onSuccess();
                Navigator.pop(context); // Go back to the previous screen
              },
              child: Text('Confirm Payment'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.amber[800],
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
