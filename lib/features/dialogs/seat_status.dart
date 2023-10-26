

import '../../exports/export.dart';

String getSvgAssetForSeatStatus(String status) {
  switch (status) {
    case 'Free':
      return AppIcons.green_seat;
    case 'Busy':
      return AppIcons.red_seat;
    case 'Partially':
      return AppIcons.yellow_seat; // Change to green_seat
    case 'Reserved':
      return AppIcons.disabled_seat;
    case 'InUse':
      return AppIcons.blue_seat;
    default:
      return AppIcons.disabled_seat;
  }
}

String get180SvgAssetForSeatStatus(String status) {
  switch (status) {
    case 'Free':
      return AppIcons.green_seat_180;
    case 'Busy':
      return AppIcons.red_seat_180;
    case 'Partially':
      return AppIcons.yellow_seat_180;
    case 'Reserved':
      return AppIcons.disabled_seat_180;
    case 'InUse':
      return AppIcons.blue_seat_180;
    default:
      return AppIcons.disabled_seat_180;
  }
}

