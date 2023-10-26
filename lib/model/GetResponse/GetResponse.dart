class Responses {
  String message;

  Responses({
    required this.message,
  });

  factory Responses.fromJson(Map<String, dynamic> json) {
    return Responses(
      message: json['message'],
    );
  }
}
