import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> addBooking() async {
  final url = Uri.parse('http://127.0.0.1:8000/api/add-booking/');
  
  final Map<String, dynamic> data = {
    "seat_status": "Reserved",
    "reserved_date": "2023-08-09",
    "reserved_time": "10:25 AM",
    "end_of_reservation": "17:30 PM",
    "date_booked": "2023-08-01T08:39:00+02:00",
    "user": 2,
    "seat": 6
  };

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    print('Booking added successfully');
  } else {
    print('Failed to add booking. Status code: ${response.statusCode}');
    print('Response: ${response.body}');
  }
}

void main() {
  addBooking();
}

