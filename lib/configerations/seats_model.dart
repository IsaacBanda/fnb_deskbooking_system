import 'dart:convert';
import 'package:http/http.dart' as http;

class Seats {
  int seatId;
  String seatNo;
  String seatStatus;
  int tableId;

  Seats({
    required this.seatId,
    required this.seatNo,
    required this.seatStatus,
    required this.tableId,
  });

  factory Seats.fromJson(Map<String, dynamic> json) {
    return Seats(
      seatId: json['seat_id'] ?? 0,         // Provide a default value or handle null
      seatNo: json['seat_no'] ?? '',        // Provide a default value or handle null
      seatStatus: json['seat_status'] ?? '', // Provide a default value or handle null
      tableId: json['table_id'] ?? 0,       // Provide a default value or handle null
    );
  }
}



// Function to fetch seat data from the API
Future<List<Seats>> fetchSeats() async {
  final response =
      await http.get(Uri.parse('http://127.0.0.1:8000/api/seats/1/'));

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = json.decode(response.body);
    return jsonData.map((seatJson) => Seats.fromJson(seatJson)).toList();
  } else {
    throw Exception('Failed to load seat data');
  }
}




/*Positioned(
                              left: 76,
                              top: 10,
                              child: GestureDetector(
                                onTap: () {
                                  _showPopupDialog(context, bookings['1']!);
                                },
                                child: bookings.containsKey('1')
                                    ? SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(
                                            bookings['1']!.seatStatus))
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            Positioned(
                              left: 230,
                              top: 10,
                              child: GestureDetector(
                                onTap: () {
                                  if (bookings.containsKey(1)) {
                                    _showPopupDialog(context, bookings[1]!);
                                  }
                                },
                                child: bookings.containsKey(1)
                                    ? SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(
                                            bookings[1]!.seatStatus))
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            Positioned(
                              right: 230,
                              top: 10,
                              child: GestureDetector(
                                onTap: () {
                                  // Show popup dialog
                                  _showPopupDialog(context, bookings['3']!);
                                },
                                child: bookings.containsKey('3')
                                    ? SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(
                                            bookings['3']!.seatStatus))
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            Positioned(
                              right: 80,
                              top: 10,
                              child: GestureDetector(
                                onTap: () {
                                  // Show popup dialog
                                },
                                child: bookings.containsKey('4')
                                    ? SvgPicture.asset(
                                        _getSvgAssetForSeatStatus(
                                            bookings['4']!.seatStatus))
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            Positioned(
                              left: 46,
                              bottom: 10,
                              child: GestureDetector(
                                onTap: () {
                                  // Show popup dialog
                                },
                                child: bookings.containsKey('5')
                                    ? SvgPicture.asset(
                                        _get180SvgAssetForSeatStatus(
                                            bookings['5']!.seatStatus))
                                    : const SizedBox.shrink(),
                              ),
                            ),*/
