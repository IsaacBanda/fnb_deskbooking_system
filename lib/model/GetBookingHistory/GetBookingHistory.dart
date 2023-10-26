class BookingHistory {
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

  BookingHistory({
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

  factory BookingHistory.fromMap(Map<String, dynamic> data) {
    return BookingHistory(
      bookingId: data['booking_id'] as int? ?? 0,
      reservedDate: (data['reserved_date'] != null)
          ? DateTime.parse(data['reserved_date'] as String)
          : DateTime.now(),
      reservedTime: data['reserved_time'] as String? ?? 'DefaultTime',
      endOfReservation:
          data['end_of_reservation'] as String? ?? 'DefaultEndReservationTime',
      dateBooked: (data['date_booked'] != null)
          ? DateTime.parse(data['date_booked'] as String)
          : DateTime.now(),
      username: data['username'] as String? ?? 'DefaultUsername',
      firstName: data['first_name'] as String? ?? 'DefaultFirstName',
      lastName: data['last_name'] as String? ?? 'DefaultLastName',
      title: data['title'] as String? ?? 'DefaultTitle',
      department: data['department'] as String? ?? 'DefaultDepartment',
      seatNo: data['seat_no'] as String? ?? 'DefaultSeatNo',
      seatStatus: data['seat_status'] as String? ?? 'DefaultSeatStatus',
      buildingName: data['building_name'] as String? ?? 'DefaultBuildingName',
      floorNo: data['floor_no'] as String? ?? 'DefaultFloorNo',
    );
  }
}
