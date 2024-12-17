import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Region_Admin_Regi_Page extends StatefulWidget {
  @override
  _Region_Admin_Regi_PageState createState() => _Region_Admin_Regi_PageState();
}

class _Region_Admin_Regi_PageState extends State<Region_Admin_Regi_Page> {
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> cities = [];
  List<Map<String, dynamic>> pincodes = [];
  List<String> selectedPincodes = [];
  String selectedCity = '';
  int selectedCityId = 0;
  String selectedState = '';
  int selectedStateId = 0;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPincodes();
    loadState();
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
      });
    } else {
      print('Failed to load pincodes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Region Admin Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              SizedBox(height: 20),
              Text('Select Pincodes:'),
              Container(
                height: 200,
                child: ListView.builder(
                  itemCount: pincodes.length,
                  itemBuilder: (context, index) {
                    return CheckboxListTile(
                      title: Text(pincodes[index]['pin_code'].toString()),
                      value: selectedPincodes
                          .contains(pincodes[index]['pin_code']),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedPincodes.add(pincodes[index]['pin_code']);
                          } else {
                            selectedPincodes
                                .remove(pincodes[index]['pin_code']);
                          }
                        });
                      },
                    );
                  },
                ),
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
                    selectedStateId = states
                        .firstWhere((state) => state['name'] == newValue)['id'];
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
                  String email = emailController.text;
                  String username = usernameController.text;
                  String password = passwordController.text;
                  String phone = phoneController.text;

                  // Call the registration function with the selected data
                  region_admin_post(
                    selectedStateId,
                    selectedCityId,
                    selectedPincodes,
                    email,
                    username,
                    password,
                    phone,
                  );
                },
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void region_admin_post(int stateId, int cityId, List<String> selectedPincodes,
    String email, String username, String password, String phone) {
  // Implement your registration logic here
  print('Selected pincodes: $selectedPincodes');
  print('Email: $email');
  print('Username: $username');
  print('Password: $password');
  print('Phone: $phone');
  print('state_id: $stateId');
  print('city_id: $cityId');
}
