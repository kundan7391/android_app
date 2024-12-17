import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_regi_data.dart';

class UserRegistrationForm extends StatefulWidget {
  @override
  _UserRegistrationFormState createState() => _UserRegistrationFormState();
}

class _UserRegistrationFormState extends State<UserRegistrationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> cities = [];
  List<Map<String, dynamic>> pincodes = [];
  List<Map<String, dynamic>> societies = [];
  List<Map<String, dynamic>> wings = [];
  List<Map<String, dynamic>> flats = [];
  String selectedState = '';
  int selectedStateId = 0;
  String selectedCity = '';
  int selectedCityId = 0;
  String selectedPincode = '';
  int selectedPincodeId = 0;
  String selectedSociety = '';
  int selectedSocietyId = 0;
  String selectedWing = '';
  int selectedWingId = 0;
  String selectedFlat = '';
  int selectedFlatId = 0;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String selectedAuthority = 'Member';
  List<String> authorities = ['Member', 'Co-member'];
  @override
  void initState() {
    super.initState();
    loadState();
    loadPincodes(); // Load pincodes when the page is initialized
    loadSocieties(); // Load pincodes when the page is initialized
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

  Future<void> loadWings(int societyId) async {
    final response = await http.get(
        Uri.parse('http://192.168.1.36/wing_list/?society_id=$societyId'));
    if (response.statusCode == 200) {
      final List<dynamic> wingData = json.decode(response.body);
      setState(() {
        wings = wingData.map<Map<String, dynamic>>((wing) {
          return {
            'id': wing['id'],
            'wing_name': wing['wing_name'],
          };
        }).toList();
        selectedWing = wings.isNotEmpty ? wings[0]['wing_name'] : '';
        selectedWingId = wings.isNotEmpty ? wings[0]['id'] : 0;
        loadFlats(societyId, selectedWingId);
      });
    } else {
      print('Failed to load wings');
    }
  }

  Future<void> loadFlats(int societyId, int wingId) async {
    final response = await http.get(Uri.parse(
        'http://192.168.1.36/flat_list/?society_id=$societyId&wing_id=$wingId'));
    if (response.statusCode == 200) {
      final List<dynamic> flatData = json.decode(response.body);
      setState(() {
        flats = flatData.map<Map<String, dynamic>>((flat) {
          return {
            'id': flat['id'],
            'flat_number': flat['flat_number'],
          };
        }).toList();
        selectedFlat = flats.isNotEmpty ? flats[0]['flat_number'] : '';
        selectedFlatId = flats.isNotEmpty ? flats[0]['id'] : 0;
      });
    } else {
      print('Failed to load flats');
    }
  }

  Future<void> loadSocieties() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.36/society_list/'));
    if (response.statusCode == 200) {
      final List<dynamic> societyData = json.decode(response.body);
      setState(() {
        societies = societyData.map<Map<String, dynamic>>((society) {
          return {
            'id': society['id'],
            'society_registration_number':
                society['society_registration_number'],
            'city_id': society['city_id'],
            'state_id': society['state_id'],
          };
        }).toList();
        selectedSociety = societies.isNotEmpty
            ? societies[0]['society_registration_number']
            : '';
        selectedSocietyId = societies.isNotEmpty ? societies[0]['id'] : 0;
        // Check if the state ID in the response matches any state in the dropdown
        loadWings(selectedSocietyId);
        final societyStateId =
            societies.isNotEmpty ? societies[0]['state_id'] : 0;
        final selectedStateIndex =
            states.indexWhere((state) => state['id'] == societyStateId);
        if (selectedStateIndex != -1) {
          setState(() {
            selectedState = states[selectedStateIndex]['name'];
            selectedStateId = states[selectedStateIndex]['id'];
          });
          // Use Future.then to load cities after setting the state
          loadCities(selectedStateId).then((_) {
            // Check if the city ID in the response matches any city in the dropdown
            final societyCityId =
                societies.isNotEmpty ? societies[0]['city_id'] : 0;
            final selectedCityIndex =
                cities.indexWhere((city) => city['id'] == societyCityId);
            if (selectedCityIndex != -1) {
              setState(() {
                selectedCity = cities[selectedCityIndex]['name'];
                selectedCityId = cities[selectedCityIndex]['id'];
              });
            }
          });
        }
      });
    } else {
      print('Failed to load societies');
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
        title: Text('Society User Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                ),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedSociety,
                  onChanged: (newValue) async {
                    setState(() {
                      selectedSociety = newValue!;
                      selectedSocietyId = societies.firstWhere((society) =>
                          society['society_registration_number'] ==
                          newValue)['id'];

                      // Update selectedCity and selectedCityId based on the selectedSociety
                      final societyCityId = societies.firstWhere((society) =>
                          society['society_registration_number'] ==
                          newValue)['city_id'];
                      final selectedCityIndex = cities
                          .indexWhere((city) => city['id'] == societyCityId);
                      if (selectedCityIndex != -1) {
                        selectedCity = cities[selectedCityIndex]['name'];
                        selectedCityId = cities[selectedCityIndex]['id'];
                      }

                      // Update selectedState and selectedStateId based on the selectedSociety
                      final societyStateId = societies.firstWhere((society) =>
                          society['society_registration_number'] ==
                          newValue)['state_id'];
                      final selectedStateIndex = states
                          .indexWhere((state) => state['id'] == societyStateId);
                      if (selectedStateIndex != -1) {
                        selectedState = states[selectedStateIndex]['name'];
                        selectedStateId = states[selectedStateIndex]['id'];
                      }
                    });

                    // Load wings after the state has been updated
                    await loadWings(selectedSocietyId);
                  },
                  items: societies.map<DropdownMenuItem<String>>((society) {
                    return DropdownMenuItem<String>(
                      value: society['society_registration_number'],
                      child: Text(society['society_registration_number']),
                    );
                  }).toList(),
                  decoration: InputDecoration(labelText: 'Society'),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedWing,
                  onChanged: (newValue) {
                    setState(() {
                      selectedWing = newValue!;
                      selectedWingId = wings.firstWhere(
                          (wing) => wing['wing_name'] == newValue)['id'];
                      loadFlats(selectedSocietyId, selectedWingId);
                    });
                  },
                  items: wings.map<DropdownMenuItem<String>>((wing) {
                    return DropdownMenuItem<String>(
                      value: wing['wing_name'],
                      child: Text(wing['wing_name']),
                    );
                  }).toList(),
                  decoration: InputDecoration(labelText: 'Wing'),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedFlat,
                  onChanged: (newValue) {
                    setState(() {
                      selectedFlat = newValue!;
                      selectedFlatId = flats.firstWhere(
                          (flat) => flat['flat_number'] == newValue)['id'];
                      loadFlats(selectedSocietyId, selectedFlatId);
                    });
                  },
                  items: flats.map<DropdownMenuItem<String>>((flat) {
                    return DropdownMenuItem<String>(
                      value: flat['flat_number'],
                      child: Text(flat['flat_number']),
                    );
                  }).toList(),
                  decoration: InputDecoration(labelText: 'flat'),
                ),
                SizedBox(height: 16.0),
                DropdownButtonFormField(
                  value: selectedAuthority,
                  items: authorities.map((authority) {
                    return DropdownMenuItem(
                      value: authority,
                      child: Text(authority),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAuthority =
                          value as String; // No need for ? as String
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Authority',
                  ),
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
                    String email = emailController.text;
                    String username = usernameController.text;
                    String password = passwordController.text;
                    String phone = phoneController.text;
                    if (_formKey.currentState!.validate()) {
                      user_post(
                          email,
                          selectedSocietyId,
                          selectedWingId,
                          selectedFlatId,
                          username,
                          password,
                          selectedStateId,
                          selectedCityId,
                          selectedPincodeId,
                          selectedAuthority,
                          phone);
                      // If all data are correct then save data to out variables
                      _formKey.currentState!.save();
                      // Call your function here
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
