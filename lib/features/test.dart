import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Booking {
  final int bookingId;
  final String reservedDate;
  final String reservedTime;
  final String endOfReservation;
  final DateTime dateBooked;
  final int user;
  final int seatId;
  final String seatStatus;

  Booking({
    required this.bookingId,
    required this.reservedDate,
    required this.reservedTime,
    required this.endOfReservation,
    required this.dateBooked,
    required this.user,
    required this.seatId,
    required this.seatStatus,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['booking_id'],
      reservedDate: json['reserved_date'],
      reservedTime: json['reserved_time'],
      endOfReservation: json['end_of_reservation'],
      dateBooked: DateTime.parse(json['date_booked']),
      user: json['user'],
      seatId: json['seat_id'],
      seatStatus: json['seat_status'],
    );
  }
}

class BookingListPage extends StatefulWidget {
  @override
  _BookingListPageState createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  late List<Booking> bookings = []; // Initialize with an empty list

  @override
  void initState() {
    super.initState();
    fetchBookings("2023-08-10"); // Pass the desired date parameter here
  }

  Future<void> fetchBookings(String date) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/bookings/'), // Replace with your API URL
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'check_date': date}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      setState(() {
        bookings = jsonResponse.map((data) => Booking.fromJson(data)).toList();
      });
    } else {
      throw Exception('Failed to load bookings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking List'),
      ),
      body: bookings != null
          ? ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Booking ID: ${bookings[index].bookingId}'),
                  subtitle: Text('Reserved Date: ${bookings[index].reservedDate}'),
                );
              },
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

void main() => runApp(MaterialApp(home: BookingListPage()));

