import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fnb_deskbooking_system/model/AddBooking/AddBookingResponseModel.dart';
import 'package:fnb_deskbooking_system/model/AddBooking/AddBookingModel.dart';
import 'package:fnb_deskbooking_system/model/GetBookingHistory/GetBookingHistory.dart';
import 'package:fnb_deskbooking_system/model/GetCurrentBooking/GetCurrentBooking.dart';
import 'package:fnb_deskbooking_system/project_assets/utils/ViewUtils.dart';
import 'package:http/http.dart' as http;

import '../model/GetBuilding/GetBuilding.dart';
import '../model/GetBuilding/GetBuildingPercentage.dart';
import '../model/GetResponse/GetResponse.dart';

class APIService {
  static const String baseUrl = "http://142.93.47.163:8000/"; // Digital Ocean API "http://142.93.47.163:8000/" local host API "http://127.0.0.1:8000/"
  var headers = {'Content-Type': 'application/json'};

  Future<dynamic?> addBooking(
    BuildContext context, {
    int? seatNo,
    int? userID,
    int? floorId,
    String? seatStatus,
    String? reservedDate,
    String? reservedTime,
    String? endofReservation,
    String? dateBooked,
    required String token,
  }) async {
    try {
      AddBookingModel addBookingModel = AddBookingModel(
          user: userID,
          dateBooked: dateBooked,
          endOfReservation: endofReservation,
          reservedDate: reservedDate,
          reservedTime: reservedTime,
          seat: seatNo,
          seatStatus: seatStatus,
          floorId: floorId);
      var param = addBookingModel.toJson();
      print('Payload Data: $param');
      debugPrint(param.toString());
      final response = await http.post(
        Uri.parse('$baseUrl/api/add-booking/'),
        headers: {
          ...headers,
          'Authorization': 'Bearer $token'
        }, // Add token to headers
        body: jsonEncode(param),
      );
      debugPrint(response.body.toString());
      if (response.statusCode == 200) {
        return AddBookingModel.fromJson(json.decode(response.body));
      } else {
        return AddBookingResponseModel.fromJson(json.decode(response.body));
      }
    } on SocketException {
      // ignore: use_build_context_synchronously
      ViewUtils.showCustomDialog(
          context, "Network Error", "No Internet connection", () {
        Navigator.of(context).pop();
      });
    } on HttpException {
      // ignore: use_build_context_synchronously
      ViewUtils.showCustomDialog(
          context, "Network Error", "Couldn't find result", () {
        Navigator.of(context).pop();
      });
    } on FormatException {
      // ignore: use_build_context_synchronously
      ViewUtils.showCustomDialog(
          context, "Network Error", "Bad response format", () {
        Navigator.of(context).pop();
      });
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchBookingDetails(
      String token, int bookingId) async {
    try {
      final payload = bookingId;
      print('Payload Data: $payload');

      final response = await http.post(
        Uri.parse('$baseUrl/api/single-booking/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'booking_id': payload}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        print('JSON Response: $responseData');

        if (responseData.isNotEmpty) {
          return responseData[0]; // Return the first booking details object
        } else {
          return null; // Booking not found
        }
      } else {
        throw Exception('Failed to fetch booking details');
      }
    } on SocketException {
      // Handle socket exception
      return null;
    } on HttpException {
      // Handle http exception
      return null;
    } on FormatException {
      // Handle format exception
      return null;
    }
  }

  Future<Responses?> deleteBooking(String token, int bookingId) async {
    try {
      final currentId = bookingId;
      print('Payload Data: $currentId');

      // Encode the data
      final encodedData = jsonEncode({'booking_id': currentId});

      // Print the encoded data
      print('Encoded Payload Data: $encodedData');

      final response = await http.post(
        Uri.parse('$baseUrl/api/delete-booking/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: encodedData,
      );

      if (response.statusCode == 200) {
        final responseData = Responses.fromJson(json.decode(response.body));
        print('JSON Response Message: ${responseData.message}');

        return responseData;
      } else {
        throw Exception('Failed to delete booking');
      }
    } on SocketException {
      // Handle socket exception
      return null;
    } on HttpException {
      // Handle http exception
      return null;
    } on FormatException {
      // Handle format exception
      return null;
    }
  }

  Future<Responses?> userLogout(String token, String myRefreshToken) async {
    try {
      final currentId = myRefreshToken;
      print('Payload Data: $currentId');

      // Encode the data
      final encodedData = jsonEncode({'refresh_token': currentId});

      // Print the encoded data
      print('Encoded Payload Data: $encodedData');

      final response = await http.post(
        Uri.parse('$baseUrl/api/logout/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: encodedData,
      );

      if (response.statusCode == 200) {
        final responseData = Responses.fromJson(json.decode(response.body));
        print('JSON Response Message: ${responseData.message}');

        return responseData;
      } else {
        throw Exception('Failed to Logout');
      }
    } on SocketException {
      // Handle socket exception
      return null;
    } on HttpException {
      // Handle http exception
      return null;
    } on FormatException {
      // Handle format exception
      return null;
    }
  }

  Future<List<Buildings>> fetchBuildings(String token) async {
    try {
      var headersWithToken = {...headers, 'Authorization': 'Bearer $token'};

      final response = await http.get(
        Uri.parse('$baseUrl/api/buildings/'),
        headers: headersWithToken,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => Buildings.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load buildings');
      }
    } on SocketException {
      // Handle socket exception
      return [];
    } on HttpException {
      // Handle http exception
      return [];
    } on FormatException {
      // Handle format exception
      return [];
    }
  }

  Future<BuildingPercentage?> getBuildingPercentage(
    String token,
    String date,
    int currentBuildingId,
  ) async {
    try {
      final currentId = currentBuildingId;
      final currentDate = date;
      print('Payload Data: buildingId: $currentId, date: $currentDate');

      // Encode the data
      final encodedData =
          jsonEncode({'check_date': currentDate, 'building_id': currentId});

      // Print the encoded data
      print('Encoded Payload Data: $encodedData');

      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings-percentage/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: encodedData,
      );

      if (response.statusCode == 200) {
        final responseData =
            BuildingPercentage.fromJson(json.decode(response.body));
        print('JSON Response Message: ${responseData}');

        return responseData;
      } else {
        throw Exception('Failed to get building Percentages');
      }
    } on SocketException {
      // Handle socket exception
      return null;
    } on HttpException {
      // Handle http exception
      return null;
    } on FormatException {
      // Handle format exception
      return null;
    }
  }

  Future<Responses?> resetPassword(
      String _myEmail, String _myOTP, String _myPassword) async {
    try {
      // Encode the data
      final encodedData = jsonEncode(
          {'email': _myEmail, 'otp': _myOTP, 'new_password': _myPassword});

      // Print the encoded data
      print('Encoded Payload Data: $encodedData');

      final response = await http.post(
        Uri.parse('$baseUrl/api/password-reset/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: encodedData,
      );

      if (response.statusCode == 200) {
        final responseData = Responses.fromJson(json.decode(response.body));
        print('JSON Response Message: ${responseData}');

        return responseData;
      } else {
        throw Exception('Failed to get building Percentages');
      }
    } on SocketException {
      // Handle socket exception
      return null;
    } on HttpException {
      // Handle http exception
      return null;
    } on FormatException {
      // Handle format exception
      return null;
    }
  }

  // Get Users Booking History
  Future<List<BookingHistory>?> getUserBookings(
      int userId, String token) async {
    final encodedData = jsonEncode({
      'user_id': userId,
    });

    print('Encoded Payload Data: $encodedData');

    final response = await http.post(
      Uri.parse('$baseUrl/api/user-booking-history/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: encodedData,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      print('Failed to load booking history: ${response.body}');
      return jsonData.map((data) => BookingHistory.fromMap(data)).toList();
    } else {
      print('Failed to load booking history: ${response.body}');
      return null;
    }
  }

  // Get Users Booking History
  Future<List<CurrentBooking>?> getUserCurrentBooking(
      int userId, String token) async {
    print("getUserCurrentBooking called");

    final encodedData = jsonEncode({
      'user_id': userId,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/api/users-next-booking/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: encodedData,
    );

    if (response.statusCode == 200) {
      dynamic jsonData = jsonDecode(response.body);

      if (jsonData is List) {
        return jsonData.map((map) => CurrentBooking.fromMap(map)).toList();
      } else if (jsonData is Map<String, dynamic>) {
        return [CurrentBooking.fromMap(jsonData)];
      } else {
        throw Exception('Unexpected data format from the server');
      }
    } else {
      print('Failed API call with status code: ${response.statusCode}');
      return null;
    }
  }
}
