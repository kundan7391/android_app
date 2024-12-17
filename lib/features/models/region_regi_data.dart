import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> region_post(int stateId, String cityId, String pincode) async {
  final url = 'http:// 192.168.1.36/region_submit/';
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'state_id': stateId,
        'city_id': cityId,
        'pin_code': pincode,
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
