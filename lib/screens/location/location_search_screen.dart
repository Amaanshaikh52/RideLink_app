import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() =>
      _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final controller = TextEditingController();
  List results = [];
  bool loading = false;

Future<void> searchLocation(String query) async {
  if (query.length < 3) return;

  setState(() => loading = true);

  final url = Uri.parse(
    'https://nominatim.openstreetmap.org/search'
    '?q=$query'
    '&format=json'
    '&addressdetails=1'
    '&countrycodes=in' // 🇮🇳 India only
    '&viewbox=68.1,37.6,97.4,6.7' // India bounding box
    '&bounded=1'
    '&limit=10',
  );

  final response = await http.get(
    url,
    headers: {
      'User-Agent': 'RideLink (India MVP)',
    },
  );

  if (response.statusCode == 200) {
    setState(() {
      results = jsonDecode(response.body);
      loading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search location")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Enter city / area",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: searchLocation,
            ),
          ),

          if (loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final place = results[index];
                return ListTile(
                  title: Text(place['display_name']),
                  onTap: () {
                    Navigator.pop(context, {
                      'name': place['display_name'],
                      'lat': double.parse(place['lat']),
                      'lng': double.parse(place['lon']),
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
