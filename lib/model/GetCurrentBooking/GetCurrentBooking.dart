class CurrentBooking {
  int bookingId;
  DateTime reservedDate;
  String reservedTime;
  String endOfReservation;
  DateTime dateBooked;
  String username;
  String firstName;
  String lastName;
  String title;
  String department;
  String seatNo;
  String seatStatus;
  String buildingName;
  String floorNo;

  CurrentBooking({
    required this.bookingId,
    required this.reservedDate,
    required this.reservedTime,
    required this.endOfReservation,
    required this.dateBooked,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.title,
    required this.department,
    required this.seatNo,
    required this.seatStatus,
    required this.buildingName,
    required this.floorNo,
  });

  // Updated factory named constructor
  factory CurrentBooking.fromMap(Map<String, dynamic> map) {
    return CurrentBooking(
      bookingId: map['booking_id'] as int? ?? 0,
      seatStatus: map['seat_status'] as String? ?? 'DefaultSeatStatus',
      reservedDate: (map['reserved_date'] != null)
          ? DateTime.parse(map['reserved_date'] as String)
          : DateTime.now(),
      reservedTime: map['reserved_time'] as String? ?? 'DefaultTime',
      endOfReservation: map['end_of_reservation'] as String? ?? 'DefaultEndReservationTime',
      dateBooked: (map['date_booked'] != null)
          ? DateTime.parse(map['date_booked'] as String)
          : DateTime.now(),
      username: map['username'] as String? ?? 'DefaultUsername',
      firstName: map['firstName'] as String? ?? 'DefaultFirstName',
      lastName: map['lastName'] as String? ?? 'DefaultLastName',
      title: map['title'] as String? ?? 'DefaultTitle',
      department: map['department'] as String? ?? 'DefaultDepartment',
      seatNo: map['seat_no'] as String? ?? 'DefaultSeatNo',
      buildingName: map['building_name'] as String? ?? 'DefaultBuildingName',
      floorNo: map['floor_no'] as String? ?? 'DefaultFloorNo',
    );
  }
}
