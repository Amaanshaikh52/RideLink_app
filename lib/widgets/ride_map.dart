import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RideMap extends StatelessWidget {
  final LatLng pickup;
  final LatLng drop;

  const RideMap({
    super.key,
    required this.pickup,
    required this.drop,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: pickup,
        zoom: 10,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.example.ridelink',
        ),

        /// Route line
        PolylineLayer(
          polylines: [
            Polyline(
              points: [pickup, drop],
              strokeWidth: 4,
              color: Colors.green,
            ),
          ],
        ),

        /// Markers
        MarkerLayer(
          markers: [
            Marker(
              point: pickup,
              width: 40,
              height: 40,
              child: const Icon(Icons.location_on,
                  color: Colors.green, size: 36),
            ),
            Marker(
              point: drop,
              width: 40,
              height: 40,
              child: const Icon(Icons.flag,
                  color: Colors.red, size: 30),
            ),
          ],
        ),
      ],
    );
  }
}
