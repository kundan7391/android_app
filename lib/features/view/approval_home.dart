import 'package:flutter/material.dart';
import 'Approval_msg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApprovalPage extends StatefulWidget {
  @override
  _ApprovalPageState createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? userPhoneNumber;
  late Future<List<Map<String, dynamic>>> _receivedApprovalsFuture;
  late Future<List<Map<String, dynamic>>> _sentApprovalsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _receivedApprovalsFuture = fetchApprovals(sent: false);
    _sentApprovalsFuture = fetchApprovals(sent: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchApprovals(
      {required bool sent}) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;
    setState(() {
      userPhoneNumber = user?.phoneNumber;
    });
    String? number;
    number = userPhoneNumber?.substring(3);
    final response = await http.post(
      Uri.parse('http://192.168.1.36/get_approval/'),
      body: {
        'phone_number': userPhoneNumber!,
        'sent': sent
            .toString(), // Indicate whether to fetch sent or received approvals
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      List<Map<String, dynamic>> approvals = [];

      for (var data in responseData) {
        if ((sent && data['sender__phone'] == number) ||
            (!sent && data['sender__phone'] != number)) {
          approvals.add({
            'sender__user_unique_name__username':
                data['sender__user_unique_name__username'],
            'id': data['id'],
            'title': data['title'],
            'message': data['message'],
            'status': data['status']
          });
        }
      }
      return approvals;
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Approval'),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ApprovalMsgPage()),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.lightBlue.shade900,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Received Tab
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _receivedApprovalsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      List<Map<String, dynamic>>? receivedApprovals =
                          snapshot.data;
                      if (receivedApprovals != null &&
                          receivedApprovals.isNotEmpty) {
                        return ListView.builder(
                          itemCount: receivedApprovals.length,
                          itemBuilder: (context, index) {
                            return _buildApprovalCard(receivedApprovals[index]);
                          },
                        );
                      } else {
                        return Center(child: Text('No received approvals'));
                      }
                    }
                  },
                ),
                // Sent Tab
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _sentApprovalsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      List<Map<String, dynamic>>? sentApprovals = snapshot.data;
                      if (sentApprovals != null && sentApprovals.isNotEmpty) {
                        return ListView.builder(
                          itemCount: sentApprovals.length,
                          itemBuilder: (context, index) {
                            return _buildApprovalCardsent(sentApprovals[index]);
                          },
                        );
                      } else {
                        return Center(child: Text('No sent approvals'));
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          // Plain area showing default group
          Container(
            padding: EdgeInsets.all(10),
            color: Colors.grey[200],
            child: Text('Default Group'),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> approval) {
    bool isApproved = approval['status'] == 'approved';
    bool isDenied = approval['status'] == 'denied';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Sender: ${approval['sender__user_unique_name__username']}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Title: ${approval['title']}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Message: ${approval['message']}',
                style: TextStyle(fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Status: ${approval['status']}',
                style: TextStyle(fontSize: 14),
              ),
            ),
            if (!isApproved &&
                !isDenied) // Only show buttons if not approved or denied
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _performAction(approval['id'], 'approved')
                          .then((success) {
                        if (success) {
                          setState(() {
                            // Refresh the page
                            _receivedApprovalsFuture =
                                fetchApprovals(sent: false);
                            _sentApprovalsFuture = fetchApprovals(sent: true);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Failed to approve.'),
                          ));
                        }
                      });
                    },
                    child: Text('Approve'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _performAction(approval['id'], 'denied').then((success) {
                        if (success) {
                          setState(() {
                            // Refresh the page
                            _receivedApprovalsFuture =
                                fetchApprovals(sent: false);
                            _sentApprovalsFuture = fetchApprovals(sent: true);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Failed to deny.'),
                          ));
                        }
                      });
                    },
                    child: Text('Deny'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _performAction(int id, String action) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.36/process_approval/'),
        body: {
          'id': id.toString(),
          'action': action,
        },
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Widget _buildApprovalCardsent(Map<String, dynamic> approval) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Sender: ${approval['sender__user_unique_name__username']}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Title: ${approval['title']}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Message: ${approval['message']}',
                style: TextStyle(fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Status: ${approval['status']}',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
