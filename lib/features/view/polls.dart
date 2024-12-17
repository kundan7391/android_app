import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/io.dart';

class PollTab extends StatefulWidget {
  @override
  _PollTabState createState() => _PollTabState();
}

class _PollTabState extends State<PollTab> {
  final TextEditingController _textEditingController = TextEditingController();
  final List<String> messages = []; // Store messages here
  String? userPhoneNumber;
  late final IOWebSocketChannel channel;
  bool isAdmin = false;
  List<Poll> polls = []; // Store polls here

  @override
  void initState() {
    super.initState();
    _getUserPhoneNumber().then((_) {
      _fetchAdmin();
      _fetchPolls();
    });
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

  Future<void> _fetchPolls() async {
    final response = await http.post(
      Uri.parse('http://192.168.1.36/get_polls/'),
      body: {
        'phone_number': userPhoneNumber!,
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      setState(() {
        polls = responseData.map((data) {
          List<PollOption> options =
              (data['options'] as List<dynamic>).map((optionJson) {
            PollOption option = PollOption.fromJson(optionJson);
            // Update isUserVoted based on whether the user has voted for this option
            String? numberr;
            numberr = userPhoneNumber?.substring(3);
            option.isUserVoted = option.voters.contains(numberr);
            return option;
          }).toList();
          return Poll.fromJson({
            ...data,
            'options': options,
          });
        }).toList();
      });
    } else {
      print('Failed to fetch polls. Status code: ${response.statusCode}');
    }
  }

  void _sendMessage() {
    String message = _textEditingController.text;
    if (message.isNotEmpty) {
      setState(() {
        messages.insert(0, message); // Add message to the top of the list
      });
      print("Sending message: $message");
      _textEditingController.clear();
    }
  }

  void _voteForOption(String pollId, String option) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;
    setState(() {
      userPhoneNumber = user?.phoneNumber;
    });
    print(option);
    final response = await http.post(
      Uri.parse('http://192.168.1.36/vote/'),
      body: {
        'poll_id': pollId,
        'option': option,
        'phone_number': userPhoneNumber,
      },
    );

    if (response.statusCode == 200) {
      _fetchPolls(); // Refresh polls after voting
    } else {
      print('Failed to record vote. Status code: ${response.statusCode}');
    }
  }

  // Function to delete a poll
  Future<void> _deletePoll(int pollId) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.36/delete_poll/'),
      body: jsonEncode({'poll_id': pollId}),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // Poll successfully deleted
      print('Poll $pollId deleted successfully');
      _fetchPolls(); // Refresh the polls list to update UI
    } else {
      print('Failed to delete poll. Status code: ${response.statusCode}');
    }
  }

  Future<void> _updatePollStatus(int pollId, String newStatus) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.36/update_poll_status/$pollId/'),
      body: jsonEncode({'status': newStatus}), // Sending the new status
      headers: {
        'Content-Type': 'application/json',
      },
    );
    print(newStatus);
    if (response.statusCode == 200) {
      // Successfully updated status
      print('Poll status updated successfully');
      _fetchPolls(); // Refresh polls to get updated status
    } else {
      print('Failed to update poll status. Status code: ${response.statusCode}');
    }
  }

  void _showStatusDialog(int pollId) {
    String newStatus = "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Poll Status'),
          content: TextField(
            onChanged: (value) {
              newStatus = value; // Capture the new status input
            },
            decoration: InputDecoration(hintText: "Enter new status"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                if (newStatus.isNotEmpty) {
                  _updatePollStatus(pollId, newStatus); // Call to update status
                } else {
                  // Optionally show a warning for empty input
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Status cannot be empty')),
                  );
                }
              },
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  Future<void> _checkPollStatus(int pollId) async {
    final url = Uri.parse('http://192.168.1.36/get_poll_status/$pollId/');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final  status = data['status'];
        if (status is String) {
          print(status);
          print("Status type: ${status.runtimeType}");
        }
        _showStatusDialog1(status);  // Display the status in an alert dialog
      } else if (response.statusCode == 404) {
        _showStatusDialog1("Poll not found.");
      } else {
        _showStatusDialog1("Failed to fetch status. Try again later.");
      }
    } catch (e) {
      _showStatusDialog1("An error occurred: $e");
    }
  }

  void _showStatusDialog1(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Poll Status"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      reverse: true, // Reverse the list to show newer messages at the top
      children: [
        // "Type your suggestion" and "Create Poll" sections
        Container(
          // padding: EdgeInsets.all(10),
          // decoration: BoxDecoration(
          //   color: Colors.grey[100],
          //   boxShadow: [
          //     BoxShadow(
          //       color: Colors.black12,
          //       blurRadius: 4,
          //       offset: Offset(0, -2),
          //     ),
          //   ],
          // ),
        //   child: Row(
        //     children: [
        //       Expanded(
        //         child: TextField(
        //           controller: _textEditingController,
        //           decoration: InputDecoration(
        //             hintText: 'Type your suggestion',
        //             border: OutlineInputBorder(
        //               borderRadius: BorderRadius.circular(20.0),
        //             ),
        //             filled: true,
        //             fillColor: Colors.white,
        //             contentPadding: EdgeInsets.symmetric(
        //                 vertical: 10, horizontal: 20),
        //           ),
        //         ),
        //       ),
        //       SizedBox(width: 8.0),
        //       Container(
        //       decoration: BoxDecoration(
        //       color: Colors.lightBlue.shade900,
        //       shape: BoxShape.circle,
        //       ),
        //       child: IconButton(
        //       icon: Icon(Icons.send, color: Colors.white),
        //       onPressed: _sendMessage,
        //       iconSize: 30,
        //       ),
        //       ),
        //     ],
        //
        //   ),
        //
        ),
        if (isAdmin)
          Padding(
            padding: EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Create Poll'),
                      content: Container(
                        width: double.maxFinite, // Allow the dialog to take full width
                        constraints: BoxConstraints(
                          maxHeight: 400, // Set a maximum height for the dialog
                        ),
                        child: SingleChildScrollView(
                          child: CreatePollPageContent(
                            questionController: TextEditingController(),
                            optionControllers: [
                              TextEditingController(),
                              TextEditingController(),
                            ],
                            startDateController: TextEditingController(),
                            endDateController: TextEditingController(),
                            pollTypeController: TextEditingController(),
                            formKey: GlobalKey<FormState>(),
                            onSubmit: () {
                              _fetchPolls(); // Refresh polls after submitting
                              Navigator.of(context).pop(); // Close dialog after submission
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Text('Create Poll'),
            ),
          ),
        // Wrap all polls in a container
        Container(
          padding: EdgeInsets.all(8.0), // Add padding if needed
          decoration: BoxDecoration(
            color: Colors.white, // Background color of the container
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: Colors.grey), // Border color if needed
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: polls.map((poll) {
              DateTime endDate = DateTime.parse(poll.endDate);
              bool isExpired = DateTime.now().isAfter(endDate);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(poll.question),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Poll Type: ${poll.pollType}'),
                        Text('Start Date: ${poll.startDate}'),
                        Text('End Date: ${poll.endDate}'),
                        Text('Status: ${poll.status}'),
                        ...poll.options.map((option) {
                          return Container(
                            color: option.isUserVoted
                                ? Colors.lightBlue.shade900.withOpacity(0.3)
                                : Colors.white,
                            child: RadioListTile(
                              title: Row(
                                children: [
                                  Text(
                                    '${option.optionText} (${option.voteCount})',
                                    style: TextStyle(
                                      color: option.isUserVoted ? Colors.black : null,
                                    ),
                                  ),
                                  if (option.isUserVoted) Text(' Your Vote'),
                                ],
                              ),
                              value: option.optionText,
                              groupValue: poll.selectedOption,
                              onChanged: (value) {
                                setState(() {
                                  poll.selectedOption = value;
                                });
                                _voteForOption(poll.pollId.toString(), value!);
                              },
                              activeColor: option.isUserVoted
                                  ? Colors.grey.withOpacity(0.99)
                                  : null,
                              controlAffinity: ListTileControlAffinity.trailing,
                            ),
                          );
                        }).toList(),
                        // Display "Take Action" button only if the poll has expired and user is admin
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isAdmin && isExpired)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, right: 8.0), // Add some right padding for spacing
                                child: ElevatedButton(
                                  onPressed: () {
                                    _deletePoll(poll.pollId); // Action logic for delete
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0), // Button padding
                                    backgroundColor: Colors.lightBlue.shade900, // Background color
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0), // Rounded corners
                                    ),
                                    shadowColor: Colors.black.withOpacity(0.3), // Shadow color
                                    elevation: 5, // Shadow elevation
                                  ),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ),
                            if (isAdmin)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, right: 8.0), // Add some right padding for spacing
                                child: ElevatedButton(
                                  onPressed: () {
                                    _showStatusDialog(poll.pollId); // Open dialog to update status
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0), // Button padding
                                    backgroundColor: Colors.lightBlue.shade900, // Background color
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0), // Rounded corners
                                    ),
                                    shadowColor: Colors.black.withOpacity(0.3), // Shadow color
                                    elevation: 5, // Shadow elevation
                                  ),
                                  child: Text(
                                    'Add Status',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0), // Top padding for alignment
                              child: ElevatedButton(
                                onPressed: () {
                                  _checkPollStatus(poll.pollId); // Open dialog to check status
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0), // Button padding
                                  backgroundColor: Colors.lightBlue.shade900, // Background color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0), // Rounded corners
                                  ),
                                  shadowColor: Colors.black.withOpacity(0.3), // Shadow color
                                  elevation: 5, // Shadow elevation
                                ),
                                child: Text(
                                  'Status',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )


                      ],
                    ),
                  ),
                  Divider(),
                ],
              );
            }).toList(),
          )

        ),
        // Chat-like messages (suggestions and created polls)
        ...messages.map((message) => ListTile(title: Text(message))).toList(),
      ],
    );
  }

}

class CreatePollPageContent extends StatefulWidget {
  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  final TextEditingController startDateController;
  final TextEditingController endDateController;
  final TextEditingController pollTypeController; // Added poll type controller
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;
  const CreatePollPageContent({
    required this.questionController,
    required this.optionControllers,
    required this.startDateController,
    required this.endDateController,
    required this.pollTypeController, // Updated constructor
    required this.formKey,
    required this.onSubmit,
  });

  @override
  _CreatePollPageContentState createState() => _CreatePollPageContentState();
}

class _CreatePollPageContentState extends State<CreatePollPageContent> {
  String? userPhoneNumber;

  void _addOptionField() {
    setState(() {
      widget.optionControllers.add(TextEditingController());
    });
  }

  Future<void> _submitForm() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;
    setState(() {
      userPhoneNumber = user?.phoneNumber;
    });
    // Prepare the data to be sent
    Map<String, dynamic> formData = {
      'phone': userPhoneNumber,
      'question': widget.questionController.text,
      'start_date': widget.startDateController.text,
      'end_date': widget.endDateController.text,
      'poll_type': widget.pollTypeController.text.isNotEmpty
          ? widget.pollTypeController.text
          : 'All Members',
      'options': widget.optionControllers
          .map((controller) => controller.text)
          .toList(),
    };

    // Send the data to your Django backend
    var url = Uri.parse('http://192.168.1.36/create_poll/');
    var response = await http.post(
      url,
      body: jsonEncode(formData),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    // Check if the request was successful
    if (response.statusCode == 201) {
      // Form submitted successfully
      print('Form submitted successfully');
      // Call the onSubmit callback to handle any necessary UI updates
      widget.onSubmit();
    } else {
      // Error occurred
      print('Error: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: widget.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: widget.questionController,
                decoration: InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontSize: 14.0), // Adjust font size
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a question';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: widget.pollTypeController.text.isEmpty
                    ? 'All Members'
                    : widget.pollTypeController.text,
                decoration: InputDecoration(
                  labelText: 'Poll Type',
                  border: OutlineInputBorder(),
                ),
                items: ['All Members', 'Board Members', 'Top Committee']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  widget.pollTypeController.text = newValue ??
                      'All Members'; // Set default to 'All Members' if newValue is null
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: widget.startDateController,
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontSize: 14.0), // Adjust font size
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101));
                  if (pickedDate != null)
                    widget.startDateController.text =
                    pickedDate.toString().split(' ')[0];
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: widget.endDateController,
                decoration: InputDecoration(
                  labelText: 'End Date',
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontSize: 14.0), // Adjust font size
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101));
                  if (pickedDate != null)
                    widget.endDateController.text =
                        pickedDate.toString().split(' ')[0];
                },
              ),
              SizedBox(height: 16.0),
              ListView.builder(
                shrinkWrap: true,
                itemCount: widget.optionControllers.length,
                itemBuilder: (BuildContext context, int index) {
                  return TextFormField(
                    controller: widget.optionControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Option ${index + 1}',
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(fontSize: 14.0), // Adjust font size
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter an option';
                      }
                      return null;
                    },
                  );
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addOptionField,
                child: Text('Add Option'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Poll {
  final int pollId;
  final String question;
  final String pollType;
  final String startDate;
  final String endDate;
  final List<PollOption> options;
  String? selectedOption;
  final String? status;

  Poll({
    required this.pollId,
    required this.question,
    required this.pollType,
    required this.startDate,
    required this.endDate,
    required this.options,
    this.status,
    this.selectedOption,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    List<PollOption> options =
        (json['options'] as List<dynamic>).cast<PollOption>();

    return Poll(
      pollId: json['poll_id'],
      question: json['question'],
      pollType: json['poll_type'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      status: json['status'],
      options: options,
    );
  }
}

class PollOption {
  final String optionText;
  final int voteCount;
  final List<String> voters;
  bool isUserVoted;

  PollOption({
    required this.optionText,
    required this.voteCount,
    required this.voters,
    this.isUserVoted = false,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      optionText: json['option_text'],
      voteCount: json['vote_count'] ?? 0,
      voters: List<String>.from(json['voters']),
    );
  }
}
