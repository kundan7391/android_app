import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> State_User(String state) async {
  final url = 'http://192.168.1.36/';
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'state_name': state,
      }),
    );

    print('Sent request with body: $response');

    if (response.statusCode == 201) {
      // Handle successful registration
      final responseData = await response.bodyBytes.toList();
      final decodedResponse = utf8.decode(responseData); // Decode response body
      print('Response: $decodedResponse'); // Print decoded response
      // ... process successful registration
    } else {
      // Handle error
      final responseData = await response.bodyBytes.toList();
      final decodedResponse = utf8.decode(responseData);
      print('Error: $decodedResponse'); // Print error details
      // Handle registration failure and display user-friendly error message
    }
  } catch (error) {
    print('Error during registration: $error');
    // Handle network or other errors and display user-friendly error message
  }
}