import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> society_post(
    int stateId,
    int cityId,
    int pincode,
    String society_name,
    String numberOfFlats,
    String wingNumber,
    String societyRegistrationNumber,
    String landmark) async {
  final url = 'http://192.168.1.36/society_submit/';
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'state_id': stateId,
        'city_id': cityId,
        'region_id': pincode,
        'society_name': society_name,
        'number_flats': numberOfFlats,
        'wing_number': wingNumber,
        'society_registration_number': societyRegistrationNumber,
        'landmark': landmark,
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
