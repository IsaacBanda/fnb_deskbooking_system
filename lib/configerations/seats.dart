class Booking {
  int? bookingId;
  DateTime? reservedDate;
  String? reservedTime;
  String? endOfReservation;
  DateTime? dateBooked;
  int? user;
  String? firstname;
  String? lastname;
  String? seatNo;
  String? seatStatus;
  String? buildingName;
  String? floorNo;

  Booking({
    this.bookingId,
    this.reservedDate,
    this.reservedTime,
    this.endOfReservation,
    this.dateBooked,
    this.user,
    this.firstname,
    this.lastname,
    this.seatNo,
    this.seatStatus,
    this.buildingName,
    this.floorNo,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['booking_id'] as int? ?? 0,
      reservedDate: (json['reserved_date'] != null)
          ? DateTime.tryParse(json['reserved_date'] as String)
          : null,
      reservedTime: json['reserved_time'] as String? ?? '',
      endOfReservation: json['end_of_reservation'] as String? ?? '',
      dateBooked: (json['date_booked'] != null)
          ? DateTime.tryParse(json['date_booked'] as String)
          : null,
      user: json['user'] as int? ?? 0,
      firstname: json['first_name'] as String? ?? '',
      lastname: json['last_name'] as String? ?? '',
      seatNo: json['seat_no'] as String? ?? '',
      seatStatus: json['seat_status'] as String? ?? '',
      buildingName: json['building_name'] as String? ?? '',
      floorNo: json['floor_no'] as String? ?? '',
    );
  }
}
