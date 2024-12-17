import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> city_post(int stateId, String city) async {
  final url = 'http://192.168.1.36/city_submit/';
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'state_id': stateId, 'city_name': city}),
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
  }
}
