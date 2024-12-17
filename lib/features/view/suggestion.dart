import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class SuggestionsTab extends StatefulWidget {
  @override
  _SuggestionsTabState createState() => _SuggestionsTabState();
}

class _SuggestionsTabState extends State<SuggestionsTab> {
  final TextEditingController _textEditingController = TextEditingController();
  String? userPhoneNumber;
  bool isAdmin = false;
  @override
  void initState() {
    super.initState();
    _getUserPhoneNumber().then((_) {
      _fetchAdmin();
    });
  }


  Future<List<String>> fetchSuggestions() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;
    setState(() {
      userPhoneNumber = user?.phoneNumber;
    });

    final response = await http.post(
      Uri.parse('http://192.168.1.36/get_suggestions/'),
      body: {
        'phone_number': userPhoneNumber!,
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      List<String> suggestions = [];
      for (var data in responseData) {
        String suggestion = data['creator__user_unique_name__username'] +
            ': ' +
            data['description'];
        suggestions.add(suggestion);
      }
      return suggestions;
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  Future<void> _getUserPhoneNumber() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;
    setState(() {
      userPhoneNumber = user?.phoneNumber;
    });
  }

  Future<void> _fetchAdmin() async {
    if (userPhoneNumber != null) {
      final response = await http.post(
        Uri.parse('http://192.168.1.36/user_type/'),
        body: {
          'phone_number': userPhoneNumber!,
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey('exists') && responseData['exists']) {
          setState(() {
           isAdmin = true;
          });
        }
      }
    }
  }

  void _sendMessage() async {
    String message = _textEditingController.text;
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;
    setState(() {
      userPhoneNumber = user?.phoneNumber;
    });

    if (message.isNotEmpty) {
      final response = await http.post(
        Uri.parse('http://192.168.1.36/create_suggestion/'),
        body: {
          'title': 'New Suggestion',
          'description': message,
          'phone_number': userPhoneNumber,
        },
      );

      if (response.statusCode == 201) {
        print('Suggestion sent successfully');
        setState(() {
          _textEditingController.clear();
        });
      } else {
        print('Failed to send suggestion. Error: ${response.statusCode}');
      }
    }
  }

  // Button action example
  void _onCardButtonPressed(String suggestion) {
    // Define the action here, e.g., show a dialog or make a request
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Action on Suggestion'),
          content: Text('You pressed the button for: "$suggestion"'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if(isAdmin)
        Expanded(
          child: FutureBuilder<List<String>>(
            future: fetchSuggestions(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(snapshot.data![index]),
                        trailing: TextButton(
                          onPressed: () => _onCardButtonPressed(snapshot.data![index]),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.lightBlue.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),

                          child: Text(
                            'Status',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              return Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<String>>(
            future: fetchSuggestions(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(snapshot.data![index]),
                        trailing: TextButton(
                          onPressed: () => _onCardButtonPressed(snapshot.data![index]),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.lightBlue.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),

                          child: Text(
                            'Status',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              return Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ),

        Container(
          padding: EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textEditingController,
                  decoration: InputDecoration(
                    hintText: 'Type your suggestion',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  ),
                ),
              ),
              SizedBox(width: 8.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade900,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                  iconSize: 30,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
