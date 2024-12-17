import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/region_regi_data.dart';

class RegionRegiPage extends StatefulWidget {
  @override
  _RegionRegiPageState createState() => _RegionRegiPageState();
}

class _RegionRegiPageState extends State<RegionRegiPage> {
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> cities = [];
  String selectedState = '';
  int selectedStateId = 0;
  String selectedCity = '';
  int selectedCityId = 0;
  final TextEditingController cityController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: pincodeController,
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
                  // Update selectedStateId when state name changes
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
                String city = cityController.text;
                String pincode = pincodeController.text;
                // Pass selectedStateId, selectedCityId, and pincode to your registration function
                region_post(
                    selectedStateId, selectedCityId.toString(), pincode);
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
