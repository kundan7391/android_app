import 'package:android_project_grp/features/view/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'features/view/login.dart';
import 'features/view/registration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: await _loadFirebaseOptions(),
  );

  runApp(MyApp());
}

Future<FirebaseOptions> _loadFirebaseOptions() async {
  String jsonString =
  await rootBundle.loadString('android/app/google-services.json');

  Map<String, dynamic> firebaseConfig = json.decode(jsonString);

  // Check if the client field exists and is not null
  if (firebaseConfig['client'] == null || firebaseConfig['client'].isEmpty) {
    throw Exception('Client field is missing or empty in google-services.json');
  }

  // Access the API key directly from the first client object
  String? apiKey = firebaseConfig['client'][0]['api_key'][0]['current_key'];

  // Check if apiKey is null or empty
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception('API key not found in google-services.json');
  }

  // Access the mobilesdk_app_id field from client_info
  String? appId =
  firebaseConfig['client'][0]['client_info']['mobilesdk_app_id'];
  if (appId == null || appId.isEmpty) {
    throw Exception('App ID is missing or empty in google-services.json');
  }

  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: firebaseConfig['project_info']['project_number'],
    projectId: firebaseConfig['project_info']['project_id'],
    authDomain:
    '${firebaseConfig['project_info']['project_id']}.firebaseapp.com',
    databaseURL:
    'https://${firebaseConfig['project_info']['project_id']}.firebaseio.com',
    storageBucket:
    '${firebaseConfig['project_info']['project_id']}.appspot.com',
    measurementId: appId, // Use appId as measurementId
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Add a loading indicator while checking authentication state
        }
        if (snapshot.hasData) {
          // User is authenticated, redirect to the appropriate registration page
          User user = snapshot.data as User;
          if (user != null) {
            // Implement logic to determine which registration page to show based on user role or other criteria
            // For now, let's assume all users are redirected to the Society Manager registration page
            return ChatPage();
          } else {
            // User is not authenticated, redirect to login page
            return LoginPage();
          }
        } else {
          // User is not authenticated, redirect to login page
          return LoginPage();
        }
      },
    );
  }
}