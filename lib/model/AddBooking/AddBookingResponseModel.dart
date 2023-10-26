class AddBookingResponseModel {
  bool? success;
  String? message;
  Errors? errors;

  AddBookingResponseModel({this.success, this.message, this.errors});

  AddBookingResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    errors = json['errors'] != null ? Errors.fromJson(json['errors']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (errors != null) {
      data['errors'] = errors!.toJson();
    }
    return data;
  }
}

class Errors {
  List<String>? user;

  Errors({this.user});

  Errors.fromJson(Map<String, dynamic> json) {
    user = json['user'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user'] = user;
    return data;
  }
}
