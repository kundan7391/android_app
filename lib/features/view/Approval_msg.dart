import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApprovalMsgPage extends StatefulWidget {
  @override
  _ApprovalMsgPageState createState() => _ApprovalMsgPageState();
}

class _ApprovalMsgPageState extends State<ApprovalMsgPage> {
  String _selectedPriority = 'High';
  bool _isBoardMemberSelected = true;
  bool _isTopMemberSelected = false;
  String? userPhoneNumber;

  // List<dynamic> approvals = [];
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  late final IOWebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    _create_approval();
  }

  void _create_approval() async {
    final text = _messageController.text;
    final title = _titleController.text;
    final topmemberselected = _isTopMemberSelected.toString();
    final boardmemberselected = _isBoardMemberSelected.toString();

    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;
    setState(() {
      userPhoneNumber = user?.phoneNumber;
    });

    if (text.isNotEmpty) {
      // Make a POST request to send the suggestion to the Django backend

      final response = await http.post(
        Uri.parse('http://192.168.1.36/create_approval/'),
        body: {
          'title': title, // You can customize the title here
          'text': text,
          'topmemberselected': topmemberselected,
          'boardmemberselected': boardmemberselected,
          'phone_number': userPhoneNumber,
        },
      );

      if (response.statusCode == 201) {
        print('Suggestion sent successfully');
        // Refresh the suggestions list after sending the suggestion
        setState(() {
          // You can call the fetchSuggestions() method again to update the UI
        });
      } else {
        print('Failed to send suggestion. Error: ${response.statusCode}');
      }
    }
    _messageController.clear();
    _titleController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Basic Request'),
        backgroundColor: Colors.lightBlue.shade900,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Title:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter title...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Message:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Enter message...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Add Approvers:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            CheckboxListTile(
              title: Text('Top Member'),
              value: _isBoardMemberSelected,
              onChanged: (value) {
                setState(() {
                  _isBoardMemberSelected = value!;
                });
              },
            ),
            CheckboxListTile(
              title: Text('Board Member'),
              value: _isTopMemberSelected,
              onChanged: (value) {
                setState(() {
                  _isTopMemberSelected = value!;
                });
              },
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _create_approval,
              child: Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
