import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/society_regi_data.dart';

class SocietyRegistrationForm extends StatefulWidget {
  @override
  _SocietyRegistrationFormState createState() =>
      _SocietyRegistrationFormState();
}

class _SocietyRegistrationFormState extends State<SocietyRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController society_name = TextEditingController();
  TextEditingController landmark = TextEditingController();
  TextEditingController _numberOfFlatsController = TextEditingController();
  TextEditingController _wingNumberController = TextEditingController();
  TextEditingController _societyRegistrationNumberController =
      TextEditingController();
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> cities = [];
  List<Map<String, dynamic>> pincodes = [];
  String selectedState = '';
  int selectedStateId = 0;
  String selectedCity = '';
  int selectedCityId = 0;
  String selectedPincode = '';
  int selectedPincodeId = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Society Registration'),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      TextFormField(
                        controller: society_name,
                        decoration: InputDecoration(
                          labelText: 'Society Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: landmark,
                        decoration: InputDecoration(
                          labelText: 'Landmark',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _numberOfFlatsController,
                        decoration: InputDecoration(
                          labelText: 'No of flats',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _wingNumberController,
                        decoration: InputDecoration(
                          labelText: 'Wing number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _societyRegistrationNumberController,
                        decoration: InputDecoration(
                          labelText: 'Society registration number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: selectedPincode,
                        onChanged: (newValue) {
                          setState(() {
                            selectedPincode = newValue!;
                            selectedPincodeId = pincodes.firstWhere((pincode) =>
                                pincode['pin_code'] == newValue)['id'];
                          });
                        },
                        items:
                            pincodes.map<DropdownMenuItem<String>>((pincode) {
                          return DropdownMenuItem<String>(
                            value: pincode['pin_code'],
                            child: Text(pincode['pin_code']),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                            labelText: 'Pincode',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(),
                            )),
                      ),
                      SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: selectedCity,
                        onChanged: (newValue) {
                          setState(() {
                            selectedCity = newValue!;
                            selectedCityId = cities.firstWhere(
                                (city) => city['name'] == newValue)['id'];
                          });
                        },
                        items: cities.map<DropdownMenuItem<String>>((city) {
                          return DropdownMenuItem<String>(
                            value: city['name'],
                            child: Text(city['name']),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(),
                            )),
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
                        decoration: InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(),
                            )),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            society_post(
                                selectedStateId,
                                selectedCityId,
                                selectedPincodeId,
                                society_name.text,
                                _numberOfFlatsController.text,
                                _wingNumberController.text,
                                _societyRegistrationNumberController.text,
                                landmark.text);
                          },
                          child: Text('Submit'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            )));
  }
}
