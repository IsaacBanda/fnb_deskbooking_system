class Floors {
  int floorId;
  String floorNo;
  int building;

  Floors({
    required this.floorId,
    required this.floorNo,
    required this.building,
  });

  factory Floors.fromJson(Map<String, dynamic> json) {
    return Floors(
      floorId: json['floor_id'],
      floorNo: json['floor_no'],
      building: json['building'],
    );
  }
}
