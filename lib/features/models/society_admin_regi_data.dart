import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> society_admin_post(
    int stateId,
    int cityId,
    int pincode,
    String email,
    String username,
    String password,
    String phone,
    String category) async {
  final url = 'http://192.168.1.36/society_admin_submit/';
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'state_id': stateId,
        'city_id': cityId,
        'region_id': pincode,
        'email': email,
        'username': username,
        'password': password,
        'phone': phone,
        'category': category
      }),
    );

    print('Sent request with body: $response');

    if (response.statusCode == 201) {
      final responseData = await response.bodyBytes.toList();
      final decodedResponse = utf8.decode(responseData); // Decode response body
      print('Response: $decodedResponse'); // Print decoded response
    } else {
      final responseData = await response.bodyBytes.toList();
      final decodedResponse = utf8.decode(responseData);
      print('Error: $decodedResponse'); // Print error details
    }
  } catch (error) {
    print('Error during registration: $error');
  }
}
