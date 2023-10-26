import 'package:fnb_deskbooking_system/exports/export.dart';

class Endpoints {
  // Digital Ocean API "http://159.65.116.118:8000/" local host API "http://127.0.0.1:8000/"

  static String authenticate = "${APIService.baseUrl}/api/token/";
  static String forgotPassword = "${APIService.baseUrl}/api/forgot-password/";
}
