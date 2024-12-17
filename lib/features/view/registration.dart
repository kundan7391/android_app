import 'package:android_project_grp/features/view/region_admin_regi.dart';
import 'package:android_project_grp/features/view/society_admin_regi.dart';
import 'package:android_project_grp/features/view/society_manager_regi.dart';
import 'package:android_project_grp/features/view/society_regi.dart';
import 'package:android_project_grp/features/view/user_regi.dart';
import 'package:flutter/material.dart';

import 'login.dart';


class RegistrationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SocietyManagerRegistrationForm(),
                  ),
                );
              },
              child: Text('Society Manager Registration'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Region_Admin_Regi_Page(),
                  ),
                );
              },
              child: Text('Region Admin Registration'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SocietyAdminRegistrationForm(),
                  ),
                );
              },
              child: Text('Society Admin Registration'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SocietyRegistrationForm(),
                  ),
                );
              },
              child: Text('Society Registration'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserRegistrationForm(),
                  ),
                );
              },
              child: Text('User Registration'),
            ),
              SizedBox(height: 8.0),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: Text(
                  "Already  have an account? Login",
                  style: TextStyle(
                    color: Colors.black54, // Change the text color to blue
                    decoration: TextDecoration.underline, // Underline the text
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }
}

