import 'dart:convert';
import 'dart:io';
import 'package:fnb_deskbooking_system/project_assets/widget/navigation_bar_Floor.dart';

import '../model/GetResponse/GetResponse.dart';
import '../project_assets/utils/DateFormatter.dart';
import '/exports/export.dart';
import 'package:intl/intl.dart';
import '../configerations/seats.dart';
import 'package:http/http.dart' as http;
import 'booking_details.dart';

class FloorScreen extends StatefulWidget {
  final String token; // Add this parameter
  final int floorId; // Add this parameter
  final String myRefreshToken; // New parameter
  final String buildingName; // New parameter


  const FloorScreen({
    Key? key,
    required this.token,
    required this.floorId,
    required this.myRefreshToken, required  this.buildingName,
  }) : super(key: key);

  @override
  State<FloorScreen> createState() => _FloorScreenState();
}

class _FloorScreenState extends State<FloorScreen> {
  late List<Booking> bookings = []; // Initialize with an empty list
  Map<String, Booking> seatToBookingMap = {};
  bool isSelected = false;
  int isSelectedIndex = 0;
  String? selectedSeatStatus;
  String? startTime, endTime;
  DateTime? reservedDateFromAPI;
  bool? isLoading;

  int? userId; // Store the user ID

  @override
  void initState() {
    super.initState();
    _extractUserIdFromToken(); // Call this method to extract the user ID
    _fetchBookingsForSelectedDate();
  }

  void _extractUserIdFromToken() {
    // Decode the token payload to extract the user ID
    final tokenParts = widget.token.split('.');
    if (tokenParts.length == 3) {
      final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1]))));
      if (payload.containsKey('user_id')) {
        userId = payload['user_id'];
      }
    }
  }

  Future<void> _fetchBookingsForSelectedDate() async {
    bookings.clear();
    if (_selectedDay != null) {
      try {
        final formattedSelectedDay =
            DateFormat('yyyy-MM-dd').format(_selectedDay!);
        final floorid = widget.floorId;

        final response = await http.post(
          Uri.parse('${APIService.baseUrl}/api/bookings/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: jsonEncode(
              {'check_date': formattedSelectedDay, 'floor_id': floorid}),
        );

        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = jsonDecode(response.body);
          print('JSON Response: $jsonResponse');

          final List<Booking> parsedBookings =
              jsonResponse.map((data) => Booking.fromJson(data)).toList();

          print('Parsed Bookings: $parsedBookings');

          setState(() {
            isSelectedIndex = 0;
            isSelected = false;
            bookings = parsedBookings;
            _mapBookingsToSeats(bookings);
          });
        } else if (response.statusCode == 404) {
          final responseData = Responses.fromJson(json.decode(response.body));
          print('JSON Response Message: ${responseData.message}');
          setState(() {
            isSelectedIndex = 0;
            isSelected = false;
            _mapBookingsToSeats(bookings);
          });
          // ignore: use_build_context_synchronously
          ViewUtils.showCustomDialog(
            context,
            'Sorry',
            responseData.message,
            () => Navigator.of(context).pop(),
          );
        } else {
          final responseData = Responses.fromJson(json.decode(response.body));
          print(
              'Unexpected status code ${response.statusCode}: ${responseData.message}');

          // ignore: use_build_context_synchronously
          ViewUtils.showCustomDialog(
            context,
            'Error',
            'An unexpected error occurred. Please try again later.',
            () => Navigator.of(context).pop(),
          );

          setState(() {
            isSelectedIndex = 0;
            isSelected = false;
            _mapBookingsToSeats(bookings);
          });
        }
      } catch (e) {
        print('Error fetching booked seats: $e');

        if (e is SocketException) {
          // ignore: use_build_context_synchronously
          ViewUtils.showCustomDialog(
            context,
            'Network Error',
            'Please check your internet connection and try again.',
            () => Navigator.of(context).pop(),
          );
        } else if (e is HttpException) {
          // ignore: use_build_context_synchronously
          ViewUtils.showCustomDialog(
            context,
            'Server Error',
            'Failed to connect with the server. Please try again later.',
            () => Navigator.of(context).pop(),
          );
        } else if (e is FormatException) {
          // ignore: use_build_context_synchronously
          ViewUtils.showCustomDialog(
            context,
            'Data Error',
            'Received invalid data from the server. Please try again.',
            () => Navigator.of(context).pop(),
          );
        } else {
          // ignore: use_build_context_synchronously
          ViewUtils.showCustomDialog(
            context,
            'Error',
            'An unexpected error occurred. Please try again later.',
            () => Navigator.of(context).pop(),
          );
        }
      }
    } else {
      print('_selectedDay is null');
    }
  }

  // Update the key type to int

  void _mapBookingsToSeats(List<Booking> bookings) {
    setState(() {
      isLoading = true;
    });

    seatToBookingMap.clear();
    for (var booking in bookings) {
      seatToBookingMap[booking.seatNo.toString()] = booking;
    }
    debugPrint(seatToBookingMap.toString());

    setState(() {
      isLoading = false;
    });
  }

  DateTime today = DateTime.now();
  DateTime focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
    });

    if (_selectedDay != null) {
      try {
        final formattedSelectedDay =
            DateFormat('yyyy-MM-dd').format(_selectedDay!);
        print('Booked Seats for $formattedSelectedDay');

        await _fetchBookingsForSelectedDate(); // Fetch bookings when day selected
      } catch (e) {
        print('Error fetching booked seats: $e');
      }
    }
  }

  void _showPreviousMonth() {
    setState(() {
      focusedDay =
          DateTime(focusedDay.year, focusedDay.month - 1, focusedDay.day);
    });
  }

  void _showNextMonth() {
    setState(() {
      focusedDay =
          DateTime(focusedDay.year, focusedDay.month + 1, focusedDay.day);
    });
  }

  String _getSvgAssetForSeatStatus(String seatStatus) {
    switch (seatStatus) {
      case 'Free':
        return AppIcons.green_seat;
      case 'Busy':
        return AppIcons.red_seat;
      case 'Partially':
        return AppIcons.yellow_seat; // Change to green_seat
      case 'Reserved':
        return AppIcons.disabled_seat;
      case 'InUse':
        return AppIcons.blue_seat;
      default:
        return AppIcons.disabled_seat;
    }
  }

  String _get180SvgAssetForSeatStatus(String seatStatus) {
    switch (seatStatus) {
      case 'Free':
        return AppIcons.green_seat_180;
      case 'Busy':
        return AppIcons.red_seat_180;
      case 'Partially':
        return AppIcons.yellow_seat_180;
      case 'Reserved':
        return AppIcons.disabled_seat_180;
      case 'InUse':
        return AppIcons.blue_seat_180;
      default:
        return AppIcons.disabled_seat_180;
    }
  }

  String _getLeftSvgAssetForSeatStatus(String seatStatus) {
    switch (seatStatus) {
      case 'Free':
        return AppIcons.left_green_seat;
      case 'Busy':
        return AppIcons.left_red_seat;
      case 'Partially':
        return AppIcons.left_yellow_seat; // Change to green_seat
      case 'Reserved':
        return AppIcons.left_disabled_seat;
      case 'InUse':
        return AppIcons.left_blue_seat;
      default:
        return AppIcons.left_disabled_seat;
    }
  }

  String _getRightSvgAssetForSeatStatus(String seatStatus) {
    switch (seatStatus) {
      case 'Free':
        return AppIcons.right_green_seat;
      case 'Busy':
        return AppIcons.right_red_seat;
      case 'Partially':
        return AppIcons.right_yellow_seat;
      case 'Reserved':
        return AppIcons.right_disabled_seat;
      case 'InUse':
        return AppIcons.right_blue_seat;
      default:
        return AppIcons.right_disabled_seat;
    }
  }

  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;
  String? selectedStartTimeAPI;
  String? selectedEndTimeAPI;

  Future<void> _showTimePicker(bool isStartTime) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: (selectedStartTime?.hour != 0 && selectedEndTime?.hour != 0)
          ? (isStartTime)
              ? TimeOfDay(
                  hour: selectedStartTime?.hour ?? 0,
                  minute: selectedStartTime?.minute ?? 0)
              : TimeOfDay(
                  hour: selectedEndTime?.hour ?? 0,
                  minute: selectedEndTime?.minute ?? 0)
          : TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          selectedStartTime = pickedTime;
          print('selectedStartTime ======: $pickedTime');
        } else {
          selectedEndTime = pickedTime;
          print('selectedEndTime ======: $pickedTime');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double sbWidth = MediaQuery.of(context).size.width * 0.7;
    double sbHeight = MediaQuery.of(context).size.height * 0.9;

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            CustomNavigationBarFloor(
              token: widget.token,
              refreshToken: widget.myRefreshToken,
              onLogoutSuccess: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              },
            ),


            Container(
              padding: const EdgeInsets.only(left: 40, right: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: sbWidth,
                    height: sbHeight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SizedBox(
                          width: 1100,
                          height: 1455,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              SvgPicture.asset(
                                AppIcons.map,
                                fit: BoxFit.fill,
                              ),

                              //SEATS FROM 01 - 10

                              Positioned(
                                left: 130,
                                top: 190,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('1')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['1']?.seatStatus !=
                                              "Occupied" &&
                                          seatToBookingMap['1']?.seatStatus !=
                                              "Disabled") {
                                        if (seatToBookingMap['1']?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['1'] ??
                                                  Booking(),
                                              1);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['1'] ??
                                                  Booking(),
                                              1);
                                        }

                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['1'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 1) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 1;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 1
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 1
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('1')
                                            ? seatToBookingMap['1']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free' ?? ''),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 200,
                                top: 190,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('2')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['2']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['2']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['2']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['2']?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['2'] ??
                                                  Booking(),
                                              2);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['2'] ??
                                                  Booking(),
                                              2);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['2'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 2) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 2;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 2
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 2
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('2')
                                            ? seatToBookingMap['2']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 300,
                                top: 190,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('3')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['3']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['3']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['3']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['3']?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['3'] ??
                                                  Booking(),
                                              3);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['3'] ??
                                                  Booking(),
                                              3);
                                        }

                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['3'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 3) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 3;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 3
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 3
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('3')
                                            ? seatToBookingMap['3']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 380,
                                top: 190,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('4')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['4']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['4']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['4']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['4']?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['4'] ??
                                                  Booking(),
                                              4);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['4'] ??
                                                  Booking(),
                                              4);
                                        }

                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['4'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 4) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 4;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 4
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 4
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('4')
                                            ? seatToBookingMap['4']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 450,
                                top: 190,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('5')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['5']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['5']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['5']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['5']?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['5'] ??
                                                  Booking(),
                                              5);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['5'] ??
                                                  Booking(),
                                              5);
                                        }

                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['5'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 5) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 5;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 5
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 5
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('5')
                                            ? seatToBookingMap['5']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 130,
                                top: 325,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('6')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['6']?.seatStatus != "Disabled" &&
                                          seatToBookingMap['6']?.seatStatus !=
                                              "Occupied" &&
                                          seatToBookingMap['6']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['6']?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['6'] ??
                                                  Booking(),
                                              6);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['6'] ??
                                                  Booking(),
                                              6);
                                        }

                                        setState(() {});
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 6) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 6;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 6
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 6
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('6')
                                                ? seatToBookingMap['6']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 200,
                                top: 325,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('7')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['7']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['7']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['7']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['7']?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['7'] ??
                                                  Booking(),
                                              7);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['7'] ??
                                                  Booking(),
                                              7);
                                        }

                                        setState(() {});
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 7) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 7;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 7
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 7
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('7')
                                                ? seatToBookingMap['7']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 300,
                                top: 325,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('8')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['8']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['8']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['8']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['8']?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['8'] ??
                                                  Booking(),
                                              8);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['8'] ??
                                                  Booking(),
                                              8);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['8'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 8) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 8;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 8
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 8
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('8')
                                                ? seatToBookingMap['8']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 300,
                                top: 325,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('8')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['8']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['8']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['8']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['8']?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['8'] ??
                                                  Booking(),
                                              8);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['8'] ??
                                                  Booking(),
                                              8);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['8'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 8) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 8;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 8
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 8
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('8')
                                                ? seatToBookingMap['8']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 380,
                                top: 325,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('9')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['9']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['9']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['9']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['9']?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['9'] ??
                                                  Booking(),
                                              9);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['9'] ??
                                                  Booking(),
                                              9);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['9'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 9) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 9;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 9
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 9
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('9')
                                                ? seatToBookingMap['9']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 450,
                                top: 325,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('10')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['10']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['10']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['10']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['10']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['10'] ??
                                                  Booking(),
                                              10);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['10'] ??
                                                  Booking(),
                                              10);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['10'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 10) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 10;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 10
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 10
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('10')
                                                ? seatToBookingMap['10']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              //SEATS FROM 11 - 18

                              Positioned(
                                left: 390,
                                top: 415,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('11')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['11']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['11']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['11']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['11']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['11'] ??
                                                  Booking(),
                                              11);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['11'] ??
                                                  Booking(),
                                              11);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['11'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 11) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 11;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 11
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 11
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getRightSvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('11')
                                                ? seatToBookingMap['11']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 390,
                                top: 490,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('12')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['12']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['12']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['12']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['12']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['12'] ??
                                                  Booking(),
                                              12);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['12'] ??
                                                  Booking(),
                                              12);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['12'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 12) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 12;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 12
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 12
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getRightSvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('12')
                                                ? seatToBookingMap['12']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 390,
                                top: 580,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('13')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['13']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['13']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['13']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['13']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['13'] ??
                                                  Booking(),
                                              13);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['13'] ??
                                                  Booking(),
                                              13);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['13'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 13) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 13;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 13
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 13
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getRightSvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('13')
                                                ? seatToBookingMap['13']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 390,
                                top: 650,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('14')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['14']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['14']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['14']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['14']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['14'] ??
                                                  Booking(),
                                              14);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['14'] ??
                                                  Booking(),
                                              14);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['14'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 14) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 14;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 14
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 14
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getRightSvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('14')
                                                ? seatToBookingMap['14']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 255,
                                top: 415,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('15')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['15']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['15']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['15']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['15']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['15'] ??
                                                  Booking(),
                                              15);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['15'] ??
                                                  Booking(),
                                              15);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['15'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 15) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 15;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 15
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 15
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getLeftSvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('15')
                                                ? seatToBookingMap['15']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 255,
                                top: 490,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('16')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['16']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['16']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['16']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['16']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['16'] ??
                                                  Booking(),
                                              16);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['16'] ??
                                                  Booking(),
                                              16);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['16'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 16) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 16;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 16
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 16
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getLeftSvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('16')
                                                ? seatToBookingMap['16']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 255,
                                top: 580,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('17')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['17']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['17']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['17']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['17']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['17'] ??
                                                  Booking(),
                                              17);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['17'] ??
                                                  Booking(),
                                              17);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['17'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 17) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 17;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 17
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 17
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getLeftSvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('17')
                                                ? seatToBookingMap['17']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 255,
                                top: 650,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('18')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['18']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['18']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['18']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['18']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['18'] ??
                                                  Booking(),
                                              18);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['18'] ??
                                                  Booking(),
                                              18);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['18'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 18) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 18;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 18
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 18
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getLeftSvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('18')
                                                ? seatToBookingMap['18']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              Positioned(
                                right: 550,
                                top: 570,
                                child: Column(
                                  children: [
                                    if (isLoading ==
                                        true) // This checks that isLoading is not null and true
                                      const Center(
                                        child: SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              //SEATS FROM 19 - 26

                              Positioned(
                                right: 350,
                                top: 370,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('19')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['19']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['19']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['19']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['19']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['19'] ??
                                                  Booking(),
                                              19);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['19'] ??
                                                  Booking(),
                                              19);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['19'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 19) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 19;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 19
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 19
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('19')
                                            ? seatToBookingMap['19']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 280,
                                top: 370,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('20')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['20']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['20']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['20']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['20']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['20'] ??
                                                  Booking(),
                                              20);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['20'] ??
                                                  Booking(),
                                              20);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['20'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 20) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 20;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 20
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 20
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('20')
                                            ? seatToBookingMap['20']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 180,
                                top: 370,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('21')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['21']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['21']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['21']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['21']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['21'] ??
                                                  Booking(),
                                              21);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['21'] ??
                                                  Booking(),
                                              21);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['21'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 21) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 21;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 21
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 21
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('21')
                                            ? seatToBookingMap['21']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 100,
                                top: 370,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('22')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['22']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['22']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['22']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['22']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['22'] ??
                                                  Booking(),
                                              22);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['22'] ??
                                                  Booking(),
                                              22);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['22'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 22) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 22;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 22
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 22
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('22')
                                            ? seatToBookingMap['22']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 350,
                                top: 505,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('23')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['23']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['23']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['23']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['23']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['23'] ??
                                                  Booking(),
                                              23);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['23'] ??
                                                  Booking(),
                                              23);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['23'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 23) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 23;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 23
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 23
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('23')
                                                ? seatToBookingMap['23']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 280,
                                top: 505,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('24')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['24']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['24']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['24']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['24']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['24'] ??
                                                  Booking(),
                                              24);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['24'] ??
                                                  Booking(),
                                              24);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['24'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 24) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 24;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 24
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 24
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('24')
                                                ? seatToBookingMap['24']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 180,
                                top: 505,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('25')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['25']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['25']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['25']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['25']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['25'] ??
                                                  Booking(),
                                              25);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['25'] ??
                                                  Booking(),
                                              25);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['25'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 25) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 25;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 25
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 25
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('25')
                                                ? seatToBookingMap['25']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 100,
                                top: 505,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('26')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['26']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['26']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['26']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['26']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['26'] ??
                                                  Booking(),
                                              26);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['26'] ??
                                                  Booking(),
                                              26);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['26'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 26) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 26;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 26
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 26
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('26')
                                                ? seatToBookingMap['26']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              //SEATS FROM 27 - 34
                              Positioned(
                                right: 350,
                                top: 555,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('27')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['27']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['27']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['27']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['27']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['27'] ??
                                                  Booking(),
                                              27);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['27'] ??
                                                  Booking(),
                                              27);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['27'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 27) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 27;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 27
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 27
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('27')
                                            ? seatToBookingMap['27']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 280,
                                top: 555,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('28')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['28']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['28']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['28']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['28']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['28'] ??
                                                  Booking(),
                                              28);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['28'] ??
                                                  Booking(),
                                              28);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['28'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 28) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 28;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 28
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 28
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('28')
                                            ? seatToBookingMap['28']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 180,
                                top: 555,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('29')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['29']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['29']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['29']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['29']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['29'] ??
                                                  Booking(),
                                              29);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['29'] ??
                                                  Booking(),
                                              29);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['29'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 29) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 29;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 29
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 29
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('29')
                                            ? seatToBookingMap['29']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 100,
                                top: 555,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('30')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['30']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['30']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['30']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['30']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['30'] ??
                                                  Booking(),
                                              30);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['30'] ??
                                                  Booking(),
                                              30);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['30'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 30) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 30;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 30
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 30
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('30')
                                            ? seatToBookingMap['30']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 350,
                                top: 685,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('31')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['31']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['31']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['31']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['31']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['31'] ??
                                                  Booking(),
                                              31);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['31'] ??
                                                  Booking(),
                                              31);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['31'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 31) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 31;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 31
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 31
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('31')
                                                ? seatToBookingMap['31']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 280,
                                top: 685,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('32')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['32']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['32']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['32']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['32']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['32'] ??
                                                  Booking(),
                                              32);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['32'] ??
                                                  Booking(),
                                              32);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['32'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 32) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 32;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 32
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 32
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('32')
                                                ? seatToBookingMap['32']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 180,
                                top: 685,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('33')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['33']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['33']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['33']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['33']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['33'] ??
                                                  Booking(),
                                              33);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['33'] ??
                                                  Booking(),
                                              33);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['33'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 33) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 33;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 33
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 33
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('33')
                                                ? seatToBookingMap['33']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 100,
                                top: 685,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('34')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['34']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['34']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['34']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['34']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['34'] ??
                                                  Booking(),
                                              34);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['34'] ??
                                                  Booking(),
                                              34);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['34'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 34) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 34;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 34
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 34
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('34')
                                                ? seatToBookingMap['34']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              //SEATS FROM 35 - 42
                              Positioned(
                                right: 350,
                                top: 740,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('35')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['35']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['35']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['35']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['35']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['35'] ??
                                                  Booking(),
                                              35);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['35'] ??
                                                  Booking(),
                                              35);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['35'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 35) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 35;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 35
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 35
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('35')
                                            ? seatToBookingMap['35']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 280,
                                top: 740,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('36')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['36']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['36']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['36']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['36']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['36'] ??
                                                  Booking(),
                                              36);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['36'] ??
                                                  Booking(),
                                              36);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['36'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 36) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 36;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 36
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 36
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('36')
                                            ? seatToBookingMap['36']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 180,
                                top: 740,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('37')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['37']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['37']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['37']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['37']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['37'] ??
                                                  Booking(),
                                              37);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['37'] ??
                                                  Booking(),
                                              37);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['37'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 37) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 37;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 37
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 37
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('37')
                                            ? seatToBookingMap['37']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 100,
                                top: 740,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('38')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['38']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['38']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['38']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['38']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['38'] ??
                                                  Booking(),
                                              38);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['38'] ??
                                                  Booking(),
                                              38);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['38'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 38) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 38;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 38
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 38
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('38')
                                            ? seatToBookingMap['38']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 350,
                                top: 865,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('47')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['39']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['39']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['39']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['39']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['39'] ??
                                                  Booking(),
                                              39);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['39'] ??
                                                  Booking(),
                                              39);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['39'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 39) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 39;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 39
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 39
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('39')
                                                ? seatToBookingMap['39']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 280,
                                top: 865,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('40')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['40']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['40']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['40']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['40']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['40'] ??
                                                  Booking(),
                                              40);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['40'] ??
                                                  Booking(),
                                              40);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['40'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 40) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 40;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 40
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 40
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('40')
                                                ? seatToBookingMap['40']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 180,
                                top: 865,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('41')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['41']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['41']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['41']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['41']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['41'] ??
                                                  Booking(),
                                              41);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['41'] ??
                                                  Booking(),
                                              41);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['41'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 41) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 41;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 41
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 41
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('41')
                                                ? seatToBookingMap['41']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 100,
                                top: 865,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('42')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['42']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['42']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['42']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['42']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['42'] ??
                                                  Booking(),
                                              42);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['42'] ??
                                                  Booking(),
                                              42);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['42'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 42) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 42;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 42
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 42
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('42')
                                                ? seatToBookingMap['42']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              //SEATS FROM 43 - 50
                              Positioned(
                                right: 350,
                                bottom: 495,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('43')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['43']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['43']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['43']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['43']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['43'] ??
                                                  Booking(),
                                              43);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['43'] ??
                                                  Booking(),
                                              43);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['43'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 43) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 43;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 43
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 43
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('43')
                                            ? seatToBookingMap['43']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 280,
                                bottom: 495,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('44')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['44']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['44']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['44']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['44']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['44'] ??
                                                  Booking(),
                                              44);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['44'] ??
                                                  Booking(),
                                              44);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['44'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 44) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 44;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 44
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 44
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('44')
                                            ? seatToBookingMap['44']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 180,
                                bottom: 495,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('45')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['45']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['45']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['45']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['45']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['45'] ??
                                                  Booking(),
                                              45);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['45'] ??
                                                  Booking(),
                                              45);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['45'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 45) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 45;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 45
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 45
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('45')
                                            ? seatToBookingMap['45']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 100,
                                bottom: 495,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('46')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['46']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['46']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['46']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['46']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['46'] ??
                                                  Booking(),
                                              46);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['46'] ??
                                                  Booking(),
                                              46);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['46'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 46) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 46;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 46
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 46
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(seatToBookingMap
                                                .containsKey('46')
                                            ? seatToBookingMap['46']!
                                                    .seatStatus ??
                                                'Free' // Use seat ID as a string key
                                            : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 350,
                                bottom: 365,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('47')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['47']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['47']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['47']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['47']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['47'] ??
                                                  Booking(),
                                              47);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['47'] ??
                                                  Booking(),
                                              47);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['47'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 47) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 47;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 47
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 47
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('47')
                                                ? seatToBookingMap['47']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 280,
                                bottom: 365,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('48')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['48']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['48']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['48']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['48']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['48'] ??
                                                  Booking(),
                                              48);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['48'] ??
                                                  Booking(),
                                              48);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['48'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 48) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 48;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 48
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 48
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('48')
                                                ? seatToBookingMap['48']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 180,
                                bottom: 365,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('49')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['49']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['49']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['49']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['49']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['49'] ??
                                                  Booking(),
                                              49);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['49'] ??
                                                  Booking(),
                                              49);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['49'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 49) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 49;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 49
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 49
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('49')
                                                ? seatToBookingMap['49']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 100,
                                bottom: 365,
                                child: GestureDetector(
                                  onTap: () {
                                    if (seatToBookingMap.containsKey('50')) {
                                      // Use seat ID as a string key
                                      if (seatToBookingMap['50']?.seatStatus != "Occupied" &&
                                          seatToBookingMap['50']?.seatStatus !=
                                              "Disabled" &&
                                          seatToBookingMap['50']?.seatStatus !=
                                              "") {
                                        if (seatToBookingMap['50']
                                                ?.seatStatus ==
                                            "Busy") {
                                          showPastBookingDetailsForOverTime(
                                              seatToBookingMap['50'] ??
                                                  Booking(),
                                              50);
                                        } else {
                                          showPastBookingDeatils(
                                              seatToBookingMap['50'] ??
                                                  Booking(),
                                              50);
                                        }
                                        setState(() {});
                                      } else {
                                        Booking booking =
                                            seatToBookingMap['50'] ?? Booking();
                                        String formattedReservedDate =
                                            DateFormatter.format(booking
                                                .reservedDate!
                                                .toIso8601String());
                                        ViewUtils.showCustomDialog(
                                            context,
                                            "Message",
                                            "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate you cannot book this seat as it is Reserved.",
                                            () {
                                          Navigator.pop(context);
                                        });
                                      }
                                    } else {
                                      selectedStartTimeAPI = "";
                                      selectedEndTimeAPI = "";
                                      selectedSeatStatus = "";
                                      if (isSelected && isSelectedIndex == 50) {
                                        isSelected = false;
                                        isSelectedIndex = 0;
                                      } else {
                                        isSelected = true;
                                        isSelectedIndex = 50;
                                      }
                                      setState(() {});
                                      // Handle unbooked seat tap
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelectedIndex == 50
                                          ? Border.all(color: Colors.white)
                                          : const Border.fromBorderSide(
                                              BorderSide.none),
                                    ),
                                    child: Padding(
                                      padding: isSelectedIndex == 50
                                          ? const EdgeInsets.all(5.0)
                                          : EdgeInsets.zero,
                                      child: SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            seatToBookingMap.containsKey('50')
                                                ? seatToBookingMap['50']!
                                                        .seatStatus ??
                                                    'Free' // Use seat ID as a string key
                                                : 'Free'),
                                        width: 45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),


                  /// This part must contain a container for displaying building name and FLoor






                  Container(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: MediaQuery.of(context).size.height * 0.9,
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          width: 350,
                          height: 300,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.neutral,
                          ),
                          child: Column(
                            children: [
                              const CustomTextField(
                                  text: "Booking Duration",
                                  fontWeight: FontWeight.bold,
                                  size: 20,
                                  color: AppColors.white),
                              const SizedBox(
                                height: 20,
                              ),




                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  buildTimePickerRow(
                                      'Start Time', selectedStartTime, true),
                                  const SizedBox(height: 16),
                                  buildTimePickerRow(
                                      'End Time', selectedEndTime, false),
                                ],
                              ),
                              const SizedBox(
                                height: 35,
                              ),
                              const CustomTextField(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                text: 'Availability Key',
                                size: 20,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 15,
                                            height: 15,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: AppColors.green,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          const CustomTextField(
                                              text: "Available",
                                              fontWeight: FontWeight.w300,
                                              size: 14,
                                              color: AppColors.white)
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 15,
                                            height: 15,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: AppColors.secondaryColor,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          const CustomTextField(
                                            text: "Partially",
                                            fontWeight: FontWeight.w300,
                                            size: 14,
                                            color: AppColors.white,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 15,
                                            height: 15,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: AppColors.red,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          const CustomTextField(
                                            text: "Busy",
                                            fontWeight: FontWeight.w300,
                                            size: 14,
                                            color: AppColors.white,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 15,
                                            height: 15,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: AppColors.blue,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          const CustomTextField(
                                            text: "Occupied",
                                            fontWeight: FontWeight.w300,
                                            size: 14,
                                            color: AppColors.white,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 15,
                                            height: 15,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: AppColors.grey,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          const CustomTextField(
                                            text: "Disabled",
                                            fontWeight: FontWeight.w300,
                                            size: 14,
                                            color: AppColors.white,
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 350,
                          height: 340,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.neutral,
                          ),
                          child: Column(
                            children: [
                              TableCalendar(
                                focusedDay: focusedDay,
                                firstDay: DateTime.utc(2022, 01, 01),
                                lastDay: DateTime.utc(2024, 12, 01),
                                rowHeight: 30,
                                selectedDayPredicate: (day) {
                                  return isSameDay(_selectedDay, day);
                                },
                                onDaySelected: _onDaySelected,
                                headerStyle: HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  titleTextStyle: GoogleFonts.poppins(
                                      color: AppColors.white),
                                  formatButtonTextStyle: GoogleFonts.poppins(
                                      color: AppColors.white),
                                  leftChevronIcon: IconButton(
                                    icon: const Icon(
                                      Icons.chevron_left,
                                    ),
                                    // Specify the icon you want to display
                                    onPressed: _showPreviousMonth,
                                    // Assign the function to be executed on press
                                    color: AppColors.white,
                                    // Optionally set the icon color
                                    iconSize:
                                        20, // Optionally set the icon size
                                  ),
                                  rightChevronIcon: IconButton(
                                    icon: const Icon(
                                      Icons.chevron_right,
                                    ),
                                    // Specify the icon you want to display
                                    onPressed: _showNextMonth,
                                    // Assign the function to be executed on press
                                    color: AppColors.white,
                                    // Optionally set the icon color
                                    iconSize:
                                        20, // Optionally set the icon size
                                  ),
                                ),
                                calendarStyle: CalendarStyle(
                                  // Customize the text style for the days of the month
                                  defaultTextStyle: GoogleFonts.poppins(
                                      color: AppColors.white),
                                  markerDecoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.secondaryColor),
                                  rangeEndTextStyle: GoogleFonts.poppins(
                                      color: AppColors.white),
                                  withinRangeTextStyle: GoogleFonts.poppins(
                                      color: AppColors.white),
                                  rangeStartTextStyle: GoogleFonts.poppins(
                                      color: AppColors.white),
                                  // Customize the text style for the selected day
                                  selectedTextStyle: GoogleFonts.poppins(
                                      color: AppColors.white),
                                  weekendTextStyle: GoogleFonts.poppins(
                                      color: AppColors.smoke),
                                  outsideDaysVisible: true,
                                  holidayTextStyle: GoogleFonts.poppins(
                                      color: AppColors.secondaryColor),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              InkWell(
                                onTap: () {
                                  validate();
                                },
                                child: Container(
                                  height: 40,
                                  width: 200,
                                  decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Center(
                                    child: Text(
                                      "Book Now",
                                      style: GoogleFonts.poppins(
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showPastBookingDeatils(Booking booking, index) {
    String hoursAvailable;
    String formattedReservedDate =
        DateFormatter.format(booking.reservedDate!.toIso8601String());
    ViewUtils.showCustomDialog(context, "Message",
        "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate",
        () {
      Navigator.pop(context);
      booking.seatStatus;
      selectedEndTimeAPI = booking.endOfReservation;

      selectedStartTimeAPI = booking.reservedTime;
      if (isSelected && isSelectedIndex == index) {
        isSelected = false;
        isSelectedIndex = 0;
      } else {
        isSelected = true;
        isSelectedIndex = index;
      }
      setState(() {});
    });
  }

  void showPastBookingDetailsForOverTime(Booking booking, index) {
    String hoursAvailable;
    String formattedReservedDate =
        DateFormatter.format(booking.reservedDate!.toIso8601String());

    ViewUtils.showCustomDialog(context, "Message",
        "This seat is booked from ${booking.reservedTime} to ${booking.endOfReservation} by ${booking.firstname} ${booking.lastname} on $formattedReservedDate",
        () {
      Navigator.pop(context);
      booking.seatStatus;
      selectedEndTimeAPI = booking.endOfReservation;
      selectedStartTimeAPI = booking.reservedTime;
      if (isSelected && isSelectedIndex == index) {
        isSelected = false;
        isSelectedIndex = 0;
      } else {
        isSelected = true;
        isSelectedIndex = index;
      }
      setState(() {});
    });
  }

  void validate() {
    if (isSelectedIndex == 0 && isSelected == false) {
      ViewUtils.showCustomDialog(context, "Message", "please select seat", () {
        Navigator.of(context).pop();
      });
      //ViewUtils.showInSnackBar("please select seat", context);
    } else if (selectedStartTime == null && selectedEndTime == null) {
      ViewUtils.showCustomDialog(
          context, "Message", "please select start and end time", () {
        Navigator.of(context).pop();
      });
    } else if ((_selectedDay?.isBefore(DateTime.now()) ?? false) &&
        _selectedDay?.day != DateTime.now().day) {
      ViewUtils.showCustomDialog(context, "Message", "date selected is past",
          () {
        Navigator.of(context).pop();
      });
    } else {
      APIService()
          .addBooking(
        context,
        userID: userId ?? 0,
        dateBooked: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        reservedDate:
            DateFormat('yyyy-MM-dd').format(_selectedDay ?? DateTime.now()),
        reservedTime: DateFormat('HH:mm').format(DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            (selectedStartTime?.hour ?? 0),
            (selectedStartTime?.minute ?? 0))),
        seatStatus: DateTimeUtils.calculateSeatStatus(
            selectedStartTime ?? const TimeOfDay(hour: 1, minute: 1),
            selectedEndTime ?? const TimeOfDay(hour: 1, minute: 1),
            selectedStartTimeAPI ?? '',
            selectedEndTimeAPI ?? '',
            selectedSeatStatus),
        seatNo: isSelectedIndex,
        endofReservation: DateFormat('HH:mm').format(DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            (selectedEndTime?.hour ?? 0),
            (selectedEndTime?.minute ?? 0))),
        token: widget.token,
        floorId: widget.floorId,
      )
          .then((value) {
        if (value is AddBookingResponseModel) {
          AddBookingResponseModel addBookingResponseModel = value;
          if (addBookingResponseModel.success != null &&
              !addBookingResponseModel.success!) {
            String errorMessage =
                addBookingResponseModel.message ?? 'An error occurred.';
            ViewUtils.showCustomDialog(context, "Error", errorMessage, () {
              Navigator.of(context).pop();
            });
          } else {
            ViewUtils.showCustomDialog(
                context, "Error", addBookingResponseModel.message ?? '', () {
              Navigator.of(context).pop();
            });
          }
        } else {
          AddBookingModel addBookingModel = value;
          print('Payload on floor: $addBookingModel');
          // Format the reservedDate using DateFormatter
          String formattedReservedDate =
              DateFormatter.format(addBookingModel.reservedDate);

          ViewUtils.showCustomDialog(context, "Success",
              "Reservation confirmed on $formattedReservedDate", () {
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailsScreen(
                  token: widget.token,
                  floorId: widget.floorId,
                  bookingData: addBookingModel,
                  myRefreshToken: widget.myRefreshToken,
                ),
              ),
            );
          });
          _fetchBookingsForSelectedDate();
        }
      });
    }
  }

  // Corrected _showPopupDialog function
  void _showPopupDialog(BuildContext context, Booking seat) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const CustomTextField(
              text: "Current Status",
              fontWeight: FontWeight.w700,
              size: 25,
              color: AppColors.primaryColor),
          content: SizedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/images/profile_pic.png'),
                ),
                CustomTextField(
                    text: seat.seatNo.toString(), // Use seatId as needed
                    fontWeight: FontWeight.w600,
                    size: 14,
                    color: AppColors.primaryColor),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const CustomTextField(
                text: 'OK',
                color: AppColors.secondaryColor,
                size: 14,
                fontWeight: FontWeight.bold,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Row buildTimePickerRow(
      String label, TimeOfDay? selectedTime, bool isStartTime) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppButtons(
          text: selectedTime != null
              ? '$label: ${selectedTime.format(context)}'
              : '$label',
          onPressed: () => _showTimePicker(isStartTime),
          textColor: AppColors.white,
          backgroundColor: AppColors.neutral,
          borderColor: AppColors.white,
          width: MediaQuery.of(context).size.width * 0.07,
          height: 45,
        ),
      ],
    );
  }
}
