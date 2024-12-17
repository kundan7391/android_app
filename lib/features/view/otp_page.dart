import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

class OtpPage extends StatelessWidget {
  final String verificationId;

  OtpPage({required this.verificationId});

  final TextEditingController _otpController = TextEditingController();
  Future<void> _verifyOtp(BuildContext context) async {
    try {
      // Verify the OTP using the provided verification ID and user input
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: _otpController.text,
      );

      // Sign in using the credential
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Check if sign-in was successful
      if (userCredential.user != null) {
        // Navigate to the home page after successful sign-in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(),
          ),
        );
      } else {
        // Handle sign-in failure
        print('Sign in failed: User is null');
      }
    } catch (e) {
      // Handle sign-in failure
      print('Sign in failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OTP Verification'),
        backgroundColor: Colors.lightBlue.shade900,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Enter OTP',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'OTP',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _verifyOtp(context),
                child: Text('Verify OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
