import '../../exports/export.dart'; // Import your custom text field widget

Future<void> showSuccessDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const CustomTextField(
          text: 'Success',
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w700,
          size: 16,
        ),
        content: const CustomTextField(
          text: 'Booking added successfully.',
          fontWeight: FontWeight.w600,
          size: 15,
          color: AppColors.primaryColor,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const CustomTextField(
              text: 'OK',
              color: AppColors.secondaryColor,
              fontWeight: FontWeight.w600,
              size: 14,
            ),
          ),
        ],
      );
    },
  );
}

Future<void> showErrorDialog(BuildContext context, String errorMessage) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const CustomTextField(
          text: 'Sorry!',
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w700,
          size: 16,
        ),
        content: CustomTextField(
          text: errorMessage,
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w500,
          size: 14,
        ), // Display the user-friendly error message
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const CustomTextField(
              text: 'OK',
              color: AppColors.secondaryColor,
              fontWeight: FontWeight.w600,
              size: 14,
            ),
          ),
        ],
      );
    },
  );
}
