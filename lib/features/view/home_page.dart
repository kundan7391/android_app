import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'approval_home.dart';
import 'logout.dart';
import 'polls.dart';
import 'suggestion.dart';
import 'user_folder.dart';
import 'package:web_socket_channel/io.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  String? userPhoneNumber;
  late final IOWebSocketChannel channel;
  String? mtoken;
  final picker = ImagePicker();

  Map<int, bool> pressedMessages = {};

  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
    add_token();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _getUserPhoneNumber().then((_) {
      if (userPhoneNumber != null && userPhoneNumber!.isNotEmpty) {
        String numberWithoutPrefix = userPhoneNumber!.substring(3);  // Remove country code

        // WebSocket connection
        channel = IOWebSocketChannel.connect('ws://192.168.1.36/ws/chat/$numberWithoutPrefix/');

        // Send a request to get chat messages
        channel.sink.add(json.encode({
          'type': 'get_chat_messages',
          'phone_number': userPhoneNumber
        }));

        // Listen for incoming messages
        channel.stream.listen(
              (message) {
            try {
              void handleParsedMessage(dynamic parsedMessage) {
                final String messageType = parsedMessage['message_type'] ?? 'unknown';
                final String sender = parsedMessage['sender'];
                final String phoneNumber = parsedMessage['phone_number'];
                final String content = parsedMessage['content'];
                final String fileUrl = parsedMessage['message_url'] ?? '';

                final String date = parsedMessage['message_date']?.toString() ?? 'No date';
                final String time = parsedMessage['message_time']?.toString() ?? 'No time';
                final int? id = parsedMessage['message_id'] ;
                final String? name = parsedMessage['name'];
                final String? phone = parsedMessage['phone'];


                setState(() {
                  // Add the parsed message to the list
                  messages.add({
                    'sender': sender,
                    'content': content,
                    'phone_number': phoneNumber,
                    'date': date,
                    'time': time,
                    'message_url': fileUrl,
                    'message_type': messageType,
                    'message_id': id,
                    'name': name,
                    'phone': phone
                  });
                });

                // Scroll to the bottom after a new message arrives
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
              }

              if (message.startsWith('[') && message.endsWith(']')) {
                final List<dynamic> parsedMessages = json.decode(message);
                for (final dynamic parsedMessage in parsedMessages) {
                  handleParsedMessage(parsedMessage);
                }
              } else {
                handleParsedMessage(json.decode(message));
              }
            } catch (e) {
              print('Error parsing message: $e');
            }
          },
          onError: (error) {
            print('WebSocket error: $error');
          },
          onDone: () {
            print('WebSocket connection closed');
          },
        );
      } else {
        print('User phone number is not available');
      }
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _getUserPhoneNumber() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;
    setState(() {
      userPhoneNumber = user?.phoneNumber;
    });
  }

  Future<void> deleteMessage(int id) async {
    final url = Uri.parse('http://192.168.1.36/delete-message/$id/');
    final response = await http.delete(url);
    if (response.statusCode == 200) {
      print("Message deleted successfully");
    } else {
      print("Failed to delete message");
    }
  }

  void _sendMessage() {
    final text = _messageController.text;
    if (text.isNotEmpty && userPhoneNumber != null) {
      channel.sink.add(json.encode({
        'type': 'send_message',
        'phone_number': userPhoneNumber,
        'message_content': text,
        'message_type': 'text',
        'message_url': 'fileUrl'
      }));
      setState(() {
        _messageController.clear();
      });
      _scrollToBottom();
      _accesstokendjango(text);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      print("Scrolling to: ${_scrollController.position.maxScrollExtent}");
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      print("ScrollController has no clients");
    }
  }

  Future<void> downloadAndOpenFile(String url) async {
    // Ensure the URL is not empty
    if (url.isEmpty) {
      print("Error: URL is empty.");
      return;
    }
    print("kundan$url");
    final tempDir = await getTemporaryDirectory();  // Get the temporary directory
    final filePath = '${tempDir.path}/file.pdf';  // Path where the file will be saved
    print("file path:$filePath");
    try {
      // Attempt to download the file from the URL
      await Dio().download(url, filePath);

      print("File downloaded successfully: $filePath");

      // After downloading, try to open the file using OpenFile
      OpenFile.open(filePath);

      print("File opened successfully.");
    } catch (e) {
      // Catch and print any errors that occur during download or file opening
      print("Error downloading or opening file: $e");
    }
  }
  void _showAttachmentOptions(BuildContext context) async {
    // Get the current user's phone number
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;
    final String? userPhoneNumber = user?.phoneNumber;

    if (userPhoneNumber == null) {
      print('User phone number is not available.');
      return; // Exit if the phone number is not available
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo),
                title: Text('Gallery'),
                onTap: () {
                  _pickImage();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.attach_file),
                title: Text('Documents'),
                onTap: () {
                  // Call uploadFile with the current user's phone number
                  uploadFile(userPhoneNumber);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.contacts),
                title: Text('Contacts'),
                onTap: () {
                   _pickContact();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  // Image picking function (Gallery)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      print('Picked image: ${image.path}');
    }
  }

  // File picking function (Documents)
  Future<void> uploadFile(String phoneNumber) async {
    // Pick a document
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],  // Allowed file types
    );

    if (result == null) {
      print('No file selected');
      return; // No file selected
    }

    final file = File(result.files.single.path!);
    var request = http.MultipartRequest('POST', Uri.parse('http://192.168.1.36/upload_file/'));

    // Attach phone number
    request.fields['phone_number'] = phoneNumber;

    // Attach file
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType('application', 'octet-stream'),  // Adjust content type if needed
    ));

    // Send request
    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        print('File uploaded successfully');

        // Assuming the server sends the URL of the file in the response body as JSON
        String responseBody = await response.stream.bytesToString();
        var responseJson = json.decode(responseBody);

        // Extract the relative file URL from the response JSON
        String fileUrl = responseJson['file_url'];

        // Concatenate the base URL with the relative file path
        String fullFileUrl = 'http://192.168.1.36$fileUrl'; // Prepend the base URL to the file path
        print("Full File URL: $fullFileUrl");

        // Send the document message with the full file URL
        _sendDocumentMessage(fullFileUrl, result.files.single.name);
      } else {
        print('File upload failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during file upload: $e');
    }
  }

  void _sendDocumentMessage(String fileUrl, String fileName) {
    if (userPhoneNumber != null && fileUrl.isNotEmpty) {
      // Prepare the message payload with file URL and file name
      final message = json.encode({
        'type': 'send_message',         // Message type
        'message_type': 'file',         // File type message
        'phone_number': userPhoneNumber, // User's phone number
        'message_content':fileName, // Content text for the message
        'message_url': fileUrl,         // The actual file URL
      });

      // Send the message via WebSocket
      channel.sink.add(message);
      print("File URL sent: $fileUrl");

      setState(() {
        // channel.sink.add(message);
      });

      // Scroll to the bottom of the chat after sending the message
      _scrollToBottom();
      _accesstokendjango(message);
    } else {
      print("Error: No phone number or file URL.");
    }

  }
  Future<void> _pickContact() async {
    final FlutterNativeContactPicker _contactPicker = FlutterNativeContactPicker();

    try {
      // Open the native contact picker
      final contact = await _contactPicker.selectContact();

      if (contact != null) {
        // Display the contact name
        print('Picked contact: ${contact.fullName}');

        // Check if the phoneNumbers list is not null and has at least one phone number
        if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
          // Access the first phone number from the list
          String phoneNumber = contact.phoneNumbers!.first;

          print('Phone number: $phoneNumber');

          // Send the phone number and name
          _sendTextMessage(phoneNumber, contact.fullName ?? 'Unknown Name');
        } else {
          print("No phone number found for this contact");
        }
      } else {
        print("No contact selected");
      }
    } catch (e) {
      print("Error picking contact: $e");
    }
  }

  void _sendTextMessage(String phoneNumber, String name) async {
    // Check if WebSocket is closed and reconnect if necessary
    if (channel.closeCode != null) {
      print("WebSocket is closed. Reconnecting...");
      String numberWithoutPrefix = userPhoneNumber!.substring(3); // Adjust based on your needs
      channel = IOWebSocketChannel.connect('ws://192.168.1.36/ws/chat/$numberWithoutPrefix/');
    }

    final message = json.encode({
      'type': 'send_message',
      'message_type': 'contact', // Text message
      'phone_number': userPhoneNumber, // User's phone number
      'message_content': 'Name: $name, Phone: $phoneNumber', // Content text for the message
      'message_url': "fileUrl", // Adjust this if needed
    });

    // Send the message via WebSocket
    channel.sink.add(message);
    print("Message sent: $message");
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.lightBlue.shade900,
          title: Text(
            'Society Chat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Chat'),
              Tab(text: 'Suggestions'),
              Tab(text: 'Poll'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LogoutPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.approval, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ApprovalPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.folder, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FolderPage()),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            // Background Image
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/chat_back.jpg'), // Replace with your image asset path
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Existing content
            TabBarView(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController, // Scroll controller to manage scrolling
                        itemCount: messages.length,     // The number of messages to display
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final senderName = message['sender']; // Sender's name
                          final senderPhoneNumber = message['phone_number']; // Sender's phone number
                          final isYou = senderPhoneNumber == userPhoneNumber?.substring(3); // Check if it's the current user

                          final messageType = message['message_type']; // Message type (e.g., 'text', 'file')
                          final content = message['content']; // Message content
                          final fileUrl = message['message_url'] ?? ''; // File URL if it's a file message
                          final dateStr = message['date']; // Message date
                          final time = message['time']; // Message time
                          final id = message['message_id'];
                          final name = message['name'] ;
                          final phone = message['phone'];



                          // Format the date
                          DateTime messageDate = DateTime.parse(dateStr);
                          String displayDate;

                          DateTime now = DateTime.now();
                          DateTime today = DateTime(now.year, now.month, now.day);
                          DateTime yesterday = today.subtract(Duration(days: 1));

                          if (messageDate.isAtSameMomentAs(today)) {
                            displayDate = "Today";
                          } else if (messageDate.isAtSameMomentAs(yesterday)) {
                            displayDate = "Yesterday";
                          } else {
                            displayDate = "${DateFormat('MMMM').format(messageDate)} ${DateFormat('dd, yyyy').format(messageDate)}";
                          }

                          // Determine if we need to show the date
                          bool showDate = index == 0 || messages[index - 1]['date'] != dateStr;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display the date only if it's the first message of the date group
                                if (showDate)
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.lightBlue.shade900, // Background color of the date box
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(color: Colors.grey[400]!, width: 1), // Border styling
                                      ),
                                      child: Text(
                                        displayDate, // Display date label
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                Align(
                                  alignment: isYou ? Alignment.centerRight : Alignment.centerLeft,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        // Toggle pressed state for the specific message
                                        pressedMessages[index] = !(pressedMessages[index] ?? false);
                                      });
                                    },
                                   child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isYou ? Color(0xFFDCF8C6) : Colors.grey[200], // Message background color
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                        bottomLeft: isYou ? Radius.circular(20) : Radius.circular(0),
                                        bottomRight: isYou ? Radius.circular(0) : Radius.circular(20),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2), // Shadow effect
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isYou ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        if (!isYou)
                                          Text(
                                            senderName,
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        const SizedBox(height: 4),

                                        // Check for file message type
                                        if (messageType == 'file') ...[
                                          GestureDetector(
                                            onTap: () {
                                              downloadAndOpenFile(fileUrl); // Function to download and open the file
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey.withOpacity(0.5),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2), // Shadow position
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(10),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blueAccent.withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.insert_drive_file,
                                                      color: Colors.blueAccent,
                                                      size: 30,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Document: $content',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                            color: Colors.blueAccent,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 5),
                                                        Text(
                                                          'Tap to open',
                                                          style: TextStyle(
                                                            color: Colors.grey[600],
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    time,
                                                    style: TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 11,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.download_rounded,
                                                    color: Colors.blueAccent,
                                                    size: 24,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ] else if (messageType == 'text') ...[
                                          Text(
                                            content,
                                            style: TextStyle(
                                              color: isYou ? Colors.black : Colors.black87,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4), // Space between the message and the time
                                          Text(
                                            time,
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ]else if (messageType == 'contact') ...[
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.blueAccent, width: 1),
                                            ),
                                            child: Row(
                                              children: [
                                                // Contact icon
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blueAccent.withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.contact_phone,
                                                    color: Colors.blueAccent,
                                                    size: 30,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),

                                                // Contact details
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      // Name display
                                                      Text(
                                                        'Name: $name',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                          color: Colors.blueAccent,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),

                                                      // Phone number display and copy functionality
                                                      GestureDetector(
                                                        onTap: () {
                                                          Clipboard.setData(ClipboardData(text: phone));
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('Phone number copied!')),
                                                          );
                                                        },
                                                        child: Text(
                                                          'Phone: $phone',
                                                          style: const TextStyle(
                                                            color: Colors.blue,
                                                            fontSize: 14,
                                                            decoration: TextDecoration.underline,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                const SizedBox(width: 10),
                                                Text(
                                                  time,
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),

                                                // Call button
                                                GestureDetector(
                                                  onTap: () async {
                                                    Uri phoneUri = Uri.parse('tel:$phone');
                                                    if (await canLaunchUrl(phoneUri)) {
                                                      await launchUrl(phoneUri);
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Unable to make the call')),
                                                      );
                                                    }
                                                  },
                                                  child: const Icon(
                                                    Icons.call,
                                                    color: Colors.green,
                                                    size: 24,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],

                                        if (pressedMessages[index] == true)
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              // Check if the message ID is valid
                                              if (id == null) {
                                                print("Invalid message ID");
                                                return;
                                              }

                                              // Show the confirmation dialog
                                              bool confirmDelete = await showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text("Delete Message"),
                                                    content: Text("Are you sure you want to delete this message?"),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(false),
                                                        child: Text("Cancel"),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(true),
                                                        child: Text("Delete"),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );

                                              if (confirmDelete) {
                                                // Call deleteMessage function with the valid message ID
                                                await deleteMessage(id);

                                                setState(() {
                                                  // Remove the message from the list
                                                  messages.removeAt(index);

                                                  // Remove the state for this specific message
                                                  pressedMessages.remove(index);
                                                });
                                              }
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                ),
                                const SizedBox(height: 10),
                          // Space between different messages
                              ],
                            ),
                          );
                        },
                      ),
                    ),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: "Type a message",
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.attach_file), // Attachment icon
                                  onPressed: () {
                                    _showAttachmentOptions(context);
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 20),
                              ),

                            ),
                          ),
                          SizedBox(width: 10),
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
                ),
                SuggestionsTab(),
                PollTab(),
              ],
            ),
          ],
        ),
      ),
    );
  }





  void requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User denied permission');
    }
  }

  void getDeviceToken() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        mtoken = token;
        print('user token $mtoken');
      });
    });
  }

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print("Handling a background message: ${message.notification?.title}");
    print("Handling a background message: ${message.notification?.body}");

    String? title = message.notification?.title;
    String? body = message.notification?.body;

    if (title != null && body != null) {
      const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
        'chat_notification_channel',
        'Channel Name',
        importance: Importance.max,
        priority: Priority.high,
        channelShowBadge: true,
        channelDescription: 'Receive notifications for new chat messages',
      );

      await FlutterLocalNotificationsPlugin().show(
        0,
        title,
        body,
        NotificationDetails(android: androidNotificationDetails),
      );
    }
  }

  Future<void> _accesstokendjango(String text) async {
    String? mtoken = await FirebaseMessaging.instance.getToken();
    final response = await http.post(
      Uri.parse('http://192.168.1.36/get_access_token/'),
      body: {
        'mtoken': mtoken,
        'phone_number': userPhoneNumber,
        'text': text,
      },
    );
    if (response.statusCode == 200) {
      print(response.body);
    } else {
      throw Exception('Failed to fetch access token');
    }
  }

  Future<void> add_token() async {
    String? mtoken = await FirebaseMessaging.instance.getToken();
    final response = await http.post(
      Uri.parse('http://192.168.1.36/add_token/'),
      body: {
        'mtoken': mtoken,
        'phone_number': userPhoneNumber,
      },
    );
    if (response.statusCode == 200) {
      print(response.body);
    } else {
      throw Exception('Failed to add token');
    }
  }
}