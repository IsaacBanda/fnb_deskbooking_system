class AddBookingModel {
  int? seat;
  int? user;
  int? bookingId;
  String? seatStatus;
  String? reservedDate;
  String? reservedTime;
  String? endOfReservation;
  String? dateBooked;
  int? floorId;

  AddBookingModel(
      {this.seat,
      this.user,
      this.bookingId,
      this.seatStatus,
      this.reservedDate,
      this.reservedTime,
      this.endOfReservation,
      this.dateBooked,
      this.floorId});

  AddBookingModel.fromJson(Map<String, dynamic> json) {
    bookingId = json['booking_id'];
    seatStatus = json['seat_status'];
    reservedDate = json['reserved_date'];
    reservedTime = json['reserved_time'];
    endOfReservation = json['end_of_reservation'];
    dateBooked = json['date_booked'];
    user = json['user'];
    seat = json['seat'];
    floorId = json['floor'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['seat'] = seat;
    data['user'] = user;
    data['floor'] = floorId;
    data['seat_status'] = seatStatus;
    data['reserved_date'] = reservedDate;
    data['reserved_time'] = reservedTime;
    data['end_of_reservation'] = endOfReservation;
    data['date_booked'] = dateBooked;
    return data;
  }
}
