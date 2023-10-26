// ignore: file_names
class Buildings {
    int buildingId;
    String buildingName;
    String location;

    Buildings({
        required this.buildingId,
        required this.buildingName,
        required this.location,
    });

    factory Buildings.fromJson(Map<String, dynamic> json) {
    return Buildings(
      buildingId: json['building_id'],
      buildingName: json['building_name'],
      location: json['location'],
    );
  }

}
