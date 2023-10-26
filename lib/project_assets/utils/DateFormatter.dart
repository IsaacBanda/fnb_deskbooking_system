class DateFormatter {
  // List of month names
  static const List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Function to get the ordinal suffix for day numbers
  static String ordinal(int value) {
    if (value >= 11 && value <= 13) {
      return "${value}th";
    }
    switch (value % 10) {
      case 1:  return "${value}st";
      case 2:  return "${value}nd";
      case 3:  return "${value}rd";
      default: return "${value}th";
    }
  }

  // Function to format the date string into the desired readable format
  static String format(String? date) {
    if (date == null) {
      return 'Unknown Date';
    }
    DateTime parsedDate = DateTime.tryParse(date) ?? DateTime.now();
    String formattedDate = "${ordinal(parsedDate.day)} ${months[parsedDate.month - 1]} ${parsedDate.year}";
    return formattedDate;
  }
}
