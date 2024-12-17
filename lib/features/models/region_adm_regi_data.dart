import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> region_admin_post(int stateId, int cityId, List<int> pincodeIds,
    String email, String username, String password, String phone) async {
  final url = 'http://192.168.1.36/region_admin_submit/';
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'state_id': stateId,
        'city_id': cityId,
        'region_ids': pincodeIds,
        'email': email,
        'username': username,
        'password': password,
        'phone': phone,
      }),
    );

    if (response.statusCode == 201) {
      // Handle successful response
      print('Registration successful');
    } else {
      // Handle error response
      print('Registration failed: ${response.body}');
    }
  } catch (error) {
    print('Error during registration: $error');
  }
}
