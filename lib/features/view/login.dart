import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_page.dart';
import 'registration.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneNumberController = TextEditingController();
  bool _isLoading = false; // Loading state for progress indicator

  Future<void> _verifyPhoneNumber(BuildContext context) async {
    String phoneNumber = _phoneNumberController.text.trim();

    if (phoneNumber.isEmpty || phoneNumber.length != 10) {
      _showSnackbar(context, 'Please enter a valid 10-digit phone number.');
      return;
    }

    final String countryCode = "+91";
    String phoneNumberWithCode = countryCode + phoneNumber;

    setState(() {
      _isLoading = true;
    });

    final response = await http.get(
      Uri.parse('http://192.168.1.36/check_number/$phoneNumber/'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData.containsKey('exists') && responseData['exists']) {
        _startPhoneNumberVerification(phoneNumberWithCode, context);
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackbar(context, 'Phone number is not registered.');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      _showSnackbar(context, 'Error checking phone number.');
    }
  }

  void _startPhoneNumberVerification(String phoneNumber, BuildContext context) {
    PhoneVerificationCompleted verificationCompleted =
        (PhoneAuthCredential credential) async {
      try {
        await _auth.signInWithCredential(credential);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showSnackbar(context, 'Sign in failed.');
      }
    };

    PhoneVerificationFailed verificationFailed = (FirebaseAuthException e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackbar(context, 'Verification failed: ${e.message}');
    };

    PhoneCodeSent codeSent = (String verificationId, int? resendToken) async {
      setState(() {
        _isLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpPage(verificationId: verificationId),
        ),
      );
    };

    PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      setState(() {
        _isLoading = false;
      });
    };

    try {
      _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackbar(context, 'Phone number verification failed.');
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image displayed at the top
              Image.asset(
                'assets/images/back2.png', // Replace with your image path
                height: 150, // Adjust the height as per your need
              ),
              SizedBox(height: 50), // Spacing between the image and text

              // Welcome text
              Text(
                'Welcome to Society App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue.shade900, // Color for the text
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              // Phone number input
              TextField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  prefixIcon: Icon(Icons.phone, color: Colors.lightBlue.shade900),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlue.shade900),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.lightBlue.shade900, width: 2.0),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Loading Indicator
              if (_isLoading) CircularProgressIndicator(),

              SizedBox(height: 20),

              // Verify phone number button
              ElevatedButton(
                onPressed:
                    _isLoading ? null : () => _verifyPhoneNumber(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue.shade900,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 80.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child:
                    Text('Verify Phone Number', style: TextStyle(fontSize: 16)),
              ),
              SizedBox(height: 20),

              // Registration link
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegistrationPage()),
                  );
                },
                child: Text(
                  "Don't have an account? Register",
                  style: TextStyle(
                    color: Colors.lightBlue.shade900,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
