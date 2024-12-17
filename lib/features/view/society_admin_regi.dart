import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/society_admin_regi_data.dart';

class SocietyAdminRegistrationForm extends StatefulWidget {
  @override
  _SocietyAdminRegistrationFormState createState() =>
      _SocietyAdminRegistrationFormState();
}

class _SocietyAdminRegistrationFormState
    extends State<SocietyAdminRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> cities = [];
  List<Map<String, dynamic>> pincodes = [];
  String selectedState = '';
  int selectedStateId = 0;
  String selectedCity = '';
  int selectedCityId = 0;
  String selectedPincode = '';
  int selectedPincodeId = 0;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String selectedcategory = 'committee member';
  List<String> authorities = [
    'chairman',
    'Cashier',
    'secretary',
    'committee member'
  ];

  @override
  void initState() {
    super.initState();
    loadState();
    loadPincodes(); // Load pincodes when the page is initialized
  }

  Future<void> loadState() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.36/state_list/'));

    if (response.statusCode == 200) {
      final List<dynamic> stateData = json.decode(response.body);

      setState(() {
        states = stateData.map<Map<String, dynamic>>((state) {
          return {
            'id': state['id'],
            'name': state['state_name'],
          };
        }).toList();
        selectedState = states.isNotEmpty ? states[0]['name'] : '';
        selectedStateId = states.isNotEmpty ? states[0]['id'] : 0;
      });

      // Load cities for the default selected state
      await loadCities(selectedStateId);
    } else {
      print('Failed to load data');
    }
  }

  Future<void> loadCities(int stateId) async {
    final response =
        await http.get(Uri.parse('http://192.168.1.36/city_list/'));

    if (response.statusCode == 200) {
      final List<dynamic> cityData = json.decode(response.body);

      setState(() {
        cities = cityData.map<Map<String, dynamic>>((city) {
          return {
            'id': city['id'],
            'name': city['city_name'],
          };
        }).toList();
        selectedCity = cities.isNotEmpty ? cities[0]['name'] : '';
        selectedCityId = cities.isNotEmpty ? cities[0]['id'] : 0;
      });
    } else {
      print('Failed to load cities');
    }
  }

  Future<void> loadPincodes() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.36/region_list/'));
    if (response.statusCode == 200) {
      final List<dynamic> pincodeData = json.decode(response.body);
      setState(() {
        pincodes = pincodeData.map<Map<String, dynamic>>((pincode) {
          return {
            'id': pincode['id'],
            'pin_code': pincode['pin_code'],
          };
        }).toList();
        selectedPincode = pincodes.isNotEmpty ? pincodes[0]['pin_code'] : '';
        selectedPincodeId = pincodes.isNotEmpty ? pincodes[0]['id'] : 0;
      });
    } else {
      print('Failed to load pincodes');
    }
  }

  String? validateEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      // Check if the entered email is valid
      String emailPattern =
          r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'; // Email regex pattern
      RegExp regex = RegExp(emailPattern);
      if (!regex.hasMatch(value)) {
        return 'Enter a valid email address';
      }
    }
    return null;
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (value.length != 10 || !value.contains(RegExp(r'^[0-9]+$'))) {
      return 'Phone number must be a 10-digit number with no special characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Society Admin Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Phone'),
                  validator: validatePhoneNumber,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: validateEmail,
                ),
                TextFormField(
                  controller: usernameController,
                  decoration: InputDecoration(labelText: 'Username'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    // Add additional validation as needed
                    return null;
                  },
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    // Add additional validation as needed
                    return null;
                  },
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedcategory,
                  onChanged: (newValue) {
                    setState(() {
                      selectedcategory = newValue!;
                    });
                  },
                  items: authorities.map((authority) {
                    return DropdownMenuItem(
                      value: authority,
                      child: Text(authority),
                    );
                  }).toList(),
                  decoration: InputDecoration(labelText: 'Category'),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedPincode,
                  onChanged: (newValue) {
                    setState(() {
                      selectedPincode = newValue!;
                      selectedPincodeId = pincodes.firstWhere(
                          (pincode) => pincode['pin_code'] == newValue)['id'];
                    });
                  },
                  items: pincodes.map<DropdownMenuItem<String>>((pincode) {
                    return DropdownMenuItem<String>(
                      value: pincode['pin_code'],
                      child: Text(pincode['pin_code']),
                    );
                  }).toList(),
                  decoration: InputDecoration(labelText: 'Pincode'),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedCity,
                  onChanged: (newValue) {
                    setState(() {
                      selectedCity = newValue!;
                      selectedCityId = cities
                          .firstWhere((city) => city['name'] == newValue)['id'];
                    });
                  },
                  items: cities.map<DropdownMenuItem<String>>((city) {
                    return DropdownMenuItem<String>(
                      value: city['name'],
                      child: Text(city['name']),
                    );
                  }).toList(),
                  decoration: InputDecoration(labelText: 'City'),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedState,
                  onChanged: (newValue) async {
                    setState(() {
                      selectedState = newValue!;
                      selectedStateId = states.firstWhere(
                          (state) => state['name'] == newValue)['id'];
                    });
                    // Load cities for the selected state
                    await loadCities(selectedStateId);
                  },
                  items: states.map<DropdownMenuItem<String>>((state) {
                    return DropdownMenuItem<String>(
                      value: state['name'],
                      child: Text(state['name']),
                    );
                  }).toList(),
                  decoration: InputDecoration(labelText: 'State'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Process registration
                      // For now, just print the form values
                      print('Email: ${emailController.text}');
                      print('Username: ${usernameController.text}');
                      print('Password: ${passwordController.text}');
                      print('phone: ${phoneController.text}');
                      society_admin_post(
                        selectedStateId,
                        selectedCityId,
                        selectedPincodeId,
                        emailController.text,
                        usernameController.text,
                        passwordController.text,
                        phoneController.text,
                        selectedcategory,
                      );
                    }
                  },
                  child: Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
