import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeUtils {
  static calculateTimeDifference(TimeOfDay startTime, TimeOfDay endTime) {
    DateTime start = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        startTime.hour,
        startTime.minute); // Replace with your start time
    DateTime end = DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day, endTime.hour, endTime.minute);

    /// Replace with your end time

    var difference = end.difference(start);
    if (difference.abs().inHours.isNegative || difference.abs().inHours > 8) {
      return true;
    }
    return false;
  }

  static convertToTime(String tod) {
    DateTime date2 = DateFormat("HH:mm").parse(tod);
    return TimeOfDay.fromDateTime(date2);
  }

  static bool isTimeWithinRange(
      String startTime, String endTime, String targetTime) {
    DateTime startTimedate = DateFormat("hh:mm").parse(startTime);
    DateTime endTimedate = DateFormat("hh:mm").parse(endTime);
    DateTime time = DateFormat("hh:mm").parse(targetTime);
    debugPrint(startTime);
    debugPrint(endTime);
    debugPrint("start" + startTimedate.toString());
    debugPrint("end" + endTimedate.toString());
    debugPrint("current" + time.toString());
    debugPrint("condition one ${time.isAfter(startTimedate)}");
    debugPrint("condition two ${time.isBefore(endTimedate)}");

    return (time.isAfter(startTimedate) && time.isBefore(endTimedate));
  }

  static calculateRemainingHours(String startTime, String endTime) {
    debugPrint(startTime);
    debugPrint(endTime);
    DateTime apiStart = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        DateFormat('hh:mm').parse(startTime).hour,
        DateFormat('hh:mm')
            .parse(startTime)
            .minute); // Replace with your start time
    DateTime apiEnd = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        DateFormat('hh:mm').parse(endTime).hour,
        DateFormat('hh:mm').parse(endTime).minute);
    var difference = apiEnd.difference(apiStart);
    var actualDiff = 8 - difference.inHours;
    debugPrint("Difference Actual" + actualDiff.toString());
    debugPrint("Difference in API" + difference.toString());
    return actualDiff.toString();
  }

  static String calculateSeatStatus(TimeOfDay startTime, TimeOfDay endTime,
      String apiStartdate, String apiEndDate, seatStatus) {
    debugPrint(apiStartdate.toString());
    debugPrint(apiEndDate.toString());
    debugPrint(startTime.toString());
    debugPrint(endTime.toString());

    if (apiStartdate.isNotEmpty && apiEndDate.isNotEmpty) {
      DateTime start = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          startTime.hour,
          startTime.minute); // Replace with your start time
      DateTime end = DateTime(DateTime.now().year, DateTime.now().month,
          DateTime.now().day, endTime.hour, endTime.minute);
      DateTime apiStart = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          DateFormat('hh:mm').parse(apiStartdate).hour,
          DateFormat('hh:mm')
              .parse(apiStartdate)
              .minute); // Replace with your start time
      DateTime apiEnd = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          DateFormat('hh:mm').parse(apiEndDate).hour,
          DateFormat('hh:mm').parse(apiEndDate).minute);

      var difference = end.difference(start);
      var differenceTwo = apiEnd.difference(apiStart);

      final timeDiff = difference.abs() + differenceTwo.abs();

      debugPrint("Difference ${timeDiff}");
      debugPrint("Difference App ${difference}");
      debugPrint("Difference API ${differenceTwo}");

      if (timeDiff.inHours.isNegative || timeDiff.inHours < 8) {
        return 'Partially';
      } else if (difference.inHours.isNegative || timeDiff.inHours == 8) {
        return 'Busy';
      } else {
        return 'Busy';
      }
    } else {
      DateTime start = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          startTime.hour,
          startTime.minute); // Replace with your start time
      DateTime end = DateTime(DateTime.now().year, DateTime.now().month,
          DateTime.now().day, endTime.hour, endTime.minute);
      var difference = end.difference(start);
      if (difference.inHours >= 8) {
        return 'Busy';
      } else {
        return 'Partially';
      }
    }
  }
}
