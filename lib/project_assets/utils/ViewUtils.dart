import 'package:flutter/material.dart';
import 'package:fnb_deskbooking_system/project_assets/styles/colors.dart';
import 'package:fnb_deskbooking_system/project_assets/widget/text_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewUtils {
  static void showInSnackBar(String value, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  static void showCustomDialog(BuildContext context, String title,
      String content, VoidCallback onPressed) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: CustomTextField(
              text: title,
              fontWeight: FontWeight.w700,
              size: 25,
              color: AppColors.primaryColor),
          content: Container(
            width: 90,
            child: Text(content,
                style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
          ),
          actions: [
            TextButton(
              onPressed: onPressed,  // This will now close the dialog
              child: const CustomTextField(
                text: 'OK',
                color: AppColors.secondaryColor,
                size: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }
}

