import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ridelink_lst/screens/location/location_search_screen.dart';
import 'package:latlong2/latlong.dart';

class PublishRideScreen extends StatefulWidget {
  const PublishRideScreen({super.key});

  @override
  State<PublishRideScreen> createState() => _PublishRideScreenState();
}

class _PublishRideScreenState extends State<PublishRideScreen> {
  String fromText = "Pickup location";
  String toText = "Destination";

  LatLng? fromLatLng;
  LatLng? toLatLng;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final priceController = TextEditingController();
  final seatsController = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF4FAF4);
    const primaryGreen = Color(0xFF2BB673);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        title: const Text(
          "Offer a Ride",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _locationField(
                    icon: Icons.location_on_outlined,
                    text: fromText,
                    onTap: () => _pickLocation(isFrom: true),
                  ),
                  const SizedBox(height: 12),
                  _locationField(
                    icon: Icons.flag_outlined,
                    text: toText,
                    onTap: () => _pickLocation(isFrom: false),
                  ),
                  const SizedBox(height: 12),

                  /// DATE
                  _pickerTile(
                    icon: Icons.calendar_today,
                    text: selectedDate == null
                        ? "Select date"
                        : DateFormat("dd MMM yyyy").format(selectedDate!),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 12),

                  /// TIME
                  _pickerTile(
                    icon: Icons.access_time,
                    text: selectedTime == null
                        ? "Select time"
                        : selectedTime!.format(context),
                    onTap: _pickTime,
                  ),
                  const SizedBox(height: 12),

                  /// PRICE
                  _textField(
                    controller: priceController,
                    hint: "Price (₹)",
                    keyboard: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  /// SEATS
                  _textField(
                    controller: seatsController,
                    hint: "Available seats",
                    keyboard: TextInputType.number,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// PUBLISH BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: loading ? null : _publishRide,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Publish Ride",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- LOGIC ----------------

  Future<void> _pickLocation({required bool isFrom}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) =>  LocationSearchScreen()),
    );

    if (result != null) {
      setState(() {
        if (isFrom) {
          fromText = result['name'];
          fromLatLng = LatLng(result['lat'], result['lng']);
        } else {
          toText = result['name'];
          toLatLng = LatLng(result['lat'], result['lng']);
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      initialDate: now,
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> _publishRide() async {

  if (fromLatLng == null ||
      toLatLng == null ||
      selectedDate == null ||
      selectedTime == null ||
      priceController.text.isEmpty ||
      seatsController.text.isEmpty) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill all details")),
    );
    return;
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  setState(() => loading = true);

  /// Combine date and time into single DateTime
  final rideDateTime = DateTime(
    selectedDate!.year,
    selectedDate!.month,
    selectedDate!.day,
    selectedTime!.hour,
    selectedTime!.minute,
  );

  await FirebaseFirestore.instance.collection('rides').add({

    "from": fromText,
    "to": toText,

    "fromLat": fromLatLng!.latitude,
    "fromLng": fromLatLng!.longitude,
    "toLat": toLatLng!.latitude,
    "toLng": toLatLng!.longitude,

    /// Keep for display
    "date": DateFormat("dd MMM yyyy").format(selectedDate!),
    "time": selectedTime!.format(context),

    /// ADD THIS (CRITICAL FIX)
    "rideDate": Timestamp.fromDate(rideDateTime),

    "price": int.parse(priceController.text),
    "seats": int.parse(seatsController.text),

    "createdBy": user.uid,
    "driverPhone": user.phoneNumber,
    "driverEmail": user.email,

    "createdAt": FieldValue.serverTimestamp(),
  });

  setState(() => loading = false);

  Navigator.pop(context);
}
}

/// ---------------- UI HELPERS ----------------

Widget _card({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

Widget _locationField({
  required IconData icon,
  required String text,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _pickerTile({
  required IconData icon,
  required String text,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    ),
  );
}

Widget _textField({
  required TextEditingController controller,
  required String hint,
  required TextInputType keyboard,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboard,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F9F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
