class BuildingPercentage {
    int buildingId;
    String buildingName;
    double limit;
    int totalSeats;
    int bookedSeats;
    double capacity;
    List<dynamic> departments;

    BuildingPercentage({
        required this.buildingId,
        required this.buildingName,
        required this.limit,
        required this.totalSeats,
        required this.bookedSeats,
        required this.capacity,
        required this.departments,
    });

    factory BuildingPercentage.fromJson(Map<String, dynamic> json) {
      return BuildingPercentage(
        buildingId: json['building_id'],
        buildingName: json['building_name'],
        limit: json['limit(%)'],
        totalSeats: json['total_seats'],
        bookedSeats: json['booked_seats'],
        capacity: json['capacity(%)'],
        departments: json['departments'],
      );
    }
}
