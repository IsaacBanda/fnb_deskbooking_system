import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fnb_deskbooking_system/exports/export.dart';
import 'package:fnb_deskbooking_system/features/building.dart';
import 'package:fnb_deskbooking_system/features/historty.dart';

class CustomNavigationBarFloor extends StatelessWidget {
  final String token;
  final String refreshToken;
  final Function onLogoutSuccess;

  CustomNavigationBarFloor({
    required this.token,
    required this.refreshToken,
    required this.onLogoutSuccess,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          SizedBox(
            height: 80,
            width: 150,
            child: SvgPicture.asset(AppIcons.fnb_logo),
          ),
          Center(
            child: Text(
              'Lunga > Floor 1', // Your center text here
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.white,
              ),
            ),
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BuildingScreen(
                    token: token,
                    myRefreshToken: refreshToken,
                  ),
                ),
              );
            },
            child: CustomTextField(
              text: 'Home',
              fontWeight: FontWeight.w600,
              size: 14,
              color: AppColors.secondaryColor,
            ),
          ),
          SizedBox(
            width: 20,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistroyScreen(
                    token: token,
                    myRefreshToken: refreshToken,
                  ),
                ),
              );
            },
            child: CustomTextField(
              text: 'My Profile',
              fontWeight: FontWeight.w600,
              size: 14,
              color: AppColors.secondaryColor,
            ),
          ),
          SizedBox(
            width: 20,
          ),
          GestureDetector(
            onTap: () async {
              final response = await APIService().userLogout(token, refreshToken);

              if (response != null) {
                ViewUtils.showCustomDialog(
                  context,
                  "Logout",
                  response.message,
                      () async {
                    await Future.delayed(const Duration(seconds: 1));
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                );
              } else {
                ViewUtils.showInSnackBar("Something went wrong. Try again.", context);
              }
            },
            child: CustomTextField(
              text: 'Logout',
              fontWeight: FontWeight.w600,
              size: 14,
              color: AppColors.white,
            ),
          ),
          SizedBox(
            width: 30,
          ),
          // Add more GestureDetector widgets here...
        ],
      ),
    );
  }
}
