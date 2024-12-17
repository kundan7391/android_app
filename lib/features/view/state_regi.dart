import 'package:flutter/material.dart';
import '../models/state_database.dart';

class State_regi_page extends StatefulWidget {
  @override
  State_regi_page_form createState() => State_regi_page_form();
}
class State_regi_page_form extends State<State_regi_page> {
  final TextEditingController stateController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: stateController,
              decoration: InputDecoration(labelText: 'state'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String state = stateController.text;

                State_User(state);
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
