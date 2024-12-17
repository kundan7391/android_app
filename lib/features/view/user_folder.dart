import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FolderPage extends StatefulWidget {
  @override
  _FolderPageState createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  late String? userPhoneNumber;
  late Future<List<String>> _foldersFuture;
  late String? username;

  @override
  void initState() {
    super.initState();
    _foldersFuture = getUserFolders();
  }

  Future<List<String>> getUserFolders() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;
    setState(() {
      userPhoneNumber = user?.phoneNumber;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.36/get_management_folders/'),
        body: {'phone_number': userPhoneNumber!},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        List<String> folders = List<String>.from(responseData['folders']);
        username = responseData['username'];
        if (username == null) {
          throw Exception('Username not found');
        }
        return folders;
      } else {
        throw Exception('Failed to fetch user folders');
      }
    } catch (e) {
      print(e);
      throw Exception('Network error: $e');
    }
  }

  Future<List<String>> getFolderContents(String folderPath) async {
    print(folderPath);
    final response = await http.post(
      Uri.parse('http://192.168.1.36/get_inner_folders/'),
      body: {
        'phone_number': userPhoneNumber!,
        'folder_path': folderPath,
      },
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      List<dynamic> contentsData = responseData['contents'];
      List<String> contents = contentsData.map((e) => e.toString()).toList();
      return contents;
    } else {
      throw Exception('Failed to fetch folder contents');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        backgroundColor: Colors.lightBlue.shade900,
        title: Text('Folder'),
      ),
      body: FutureBuilder(
        future: _foldersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<String> userFolders = snapshot.data as List<String>;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                Text(
                  'Management Section',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: userFolders.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        onTap: () async {
                          String folderPath = userFolders[index];
                          List<String> contents =
                          await getFolderContents(folderPath);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FolderContentsPage(
                                folderPath: folderPath,
                                contents: contents,
                                getFolderContents: getFolderContents,
                                username: username,
                              ),
                            ),
                          );
                        },
                        leading: Icon(Icons.folder),
                        title: Text(userFolders[index]),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class FolderContentsPage extends StatelessWidget {
  final String folderPath;
  final List<String> contents;
  final Function(String) getFolderContents; // Pass the method reference
  final String? username;
  const FolderContentsPage({
    Key? key,
    required this.folderPath,
    required this.contents,
    required this.getFolderContents, // Receive the method reference
    required this.username,
  }) : super(key: key);

  Future<String> downloadPDF(String url) async {
    var response = await http.get(Uri.parse(url));
    var dir = await getTemporaryDirectory();
    var filePath = '${dir.path}/downloaded.pdf';
    var file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(folderPath),
      ),
      body: ListView.builder(
        itemCount: contents.length,
        itemBuilder: (context, index) {
          bool isFolder = contents[index].endsWith('/');
          String fileName = contents[index];
          String fileExtension =
          isFolder ? '' : fileName.substring(fileName.lastIndexOf('.') + 1);
          IconData iconData;
          Function()? onTap;

          print(
              'http://192.168.1.36/media/$username/${folderPath}/${contents[index]}');

          if (isFolder) {
            iconData = Icons.folder;
            onTap = () async {
              String nestedFolderPath = '$folderPath/${contents[index]}';
              List<String> nestedContents =
              await getFolderContents(nestedFolderPath);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FolderContentsPage(
                    folderPath: nestedFolderPath,
                    contents: nestedContents,
                    getFolderContents: getFolderContents,
                    username: username,
                  ),
                ),
              );
            };
          } else {
            switch (fileExtension) {
              case 'pdf':
                iconData = Icons.picture_as_pdf;
                onTap = () async {
                  String pdfUrl =
                      'http://192.168.1.36/media/$username/${folderPath}/${contents[index]}';
                  String localFilePath = await downloadPDF(pdfUrl);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PDFViewPage(
                        pdfPath: localFilePath,
                      ),
                    ),
                  );
                };
                break;
              case 'jpeg':
              case 'jpg':
              case 'png':
                iconData = Icons.image;
                onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(title: Text('Image Viewer')),
                        body: PhotoView(
                          imageProvider: NetworkImage(
                            'http://192.168.1.36/media/$username/${folderPath}/${contents[index]}',
                          ),
                        ),
                      ),
                    ),
                  );
                };
                break;
              default:
                iconData = Icons.insert_drive_file;
                onTap = () {
                  // Handle other file types
                };
            }
          }
          return ListTile(
            onTap: onTap,
            leading: Icon(iconData),
            title: Text(contents[index]),
          );
        },
      ),
    );
  }
}

class PDFViewPage extends StatelessWidget {
  final String pdfPath;

  const PDFViewPage({Key? key, required this.pdfPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
      ),
      body: PDFView(
        filePath: pdfPath,
        autoSpacing: true,
        enableSwipe: true,
        pageSnap: true,
        swipeHorizontal: true,
        nightMode: false,
        onError: (e) {
          // Show some error message or UI
          print('Error while loading PDF: $e');
        },
        onPageError: (page, e) {
          // Handle page error
          print('Error while loading page $page: $e');
        },
      ),
    );
  }
}
