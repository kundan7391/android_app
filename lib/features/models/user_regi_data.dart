import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> user_post(
    String email,
    int society_id,
    int wing_id,
    int flat_id,
    String username,
    String password,
    int stateId,
    int cityId,
    int pincode,
    String authority,
    String phone) async {
  final url = 'http://192.168.1.36/society_user_info_submit/';
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'society_id': society_id,
        'wing_id': wing_id,
        'flat_id': flat_id,
        'username': username,
        'password': password,
        'state_id': stateId,
        'region_id': pincode,
        'authority': authority,
        'city_id': cityId,
        'phone': phone,
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
