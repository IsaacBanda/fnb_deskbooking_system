import 'dart:convert';
import 'dart:io';
import 'package:fnb_deskbooking_system/exports/export.dart';
import 'package:fnb_deskbooking_system/project_assets/widget/basic_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../configerations/configs.dart';
import '../project_assets/widget/custom_textinput.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool _isChecked = false;
  final TextEditingController _myPassword = TextEditingController();
  final TextEditingController _myEmail = TextEditingController();
  final TextEditingController _myOTP = TextEditingController();
  bool _isLoading = false; // Add this line
  bool _isSuccess = false; // Add this line
  final APIService _apiService = APIService();

  @override
  void initState() {
    super.initState();
  }

  void _forgotPassword() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    if (_myEmail.text.isNotEmpty) {
      var loginBody = {
        "email": _myEmail.text,
      };

      try {
        var response = await http.post(
          Uri.parse(Endpoints.forgotPassword),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(loginBody),
        );
        print('Response: ${response.body}');

        if (response.statusCode == 400) {
          var jsonResponse = jsonDecode(response.body);
          var detailMessage = jsonResponse['message'];
          // ignore: use_build_context_synchronously
          ViewUtils.showCustomDialog(context, "Access Denied", detailMessage,
              () {
            Navigator.of(context).pop();
          });
          setState(() {
            _isLoading = false; // Stop loading
          });
          return;
        }

        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          var myToken = jsonResponse['message'];

          // ignore: use_build_context_synchronously
          ViewUtils.showCustomDialog(
            context,
            "Login successful",
            myToken,
            () {},
          );

          setState(() {
            _isSuccess = true; // Add this line
          });
          // Use a delay before navigating to the BuildingScreen
          Future.delayed(Duration(seconds: 1), () {
            Navigator.of(context).pop(); // Closes the dialog
          });
        } else {
          // ignore: use_build_context_synchronously
          ViewUtils.showCustomDialog(context, "Error", "Something went wrong",
              () {
            Navigator.of(context).pop();
          });
        }
      } on SocketException {
        // ignore: use_build_context_synchronously
        ViewUtils.showCustomDialog(
            context, "Network Error", "No Internet connection", () {
          Navigator.of(context).pop();
        });
      } on HttpException {
        // ignore: use_build_context_synchronously
        ViewUtils.showCustomDialog(
            context, "Network Error", "Couldn't find result", () {
          Navigator.of(context).pop();
        });
      } on FormatException {
        // ignore: use_build_context_synchronously
        ViewUtils.showCustomDialog(
            context, "Network Error", "Bad response format", () {
          Navigator.of(context).pop();
        });
      } catch (e) {
        print('Error: $e');
        // ignore: use_build_context_synchronously
        ViewUtils.showInSnackBar('An error occurred', context);
      }
      setState(() {
        _isLoading = false; // Stop loading
      });
    } else {
      ViewUtils.showCustomDialog(context, "Sorry!", "Please fill in all fields",
          () {
        Navigator.of(context).pop();
      });
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  Future<void> _RestPassword() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final response = await _apiService.resetPassword(
          _myEmail.text, // fetch the text from the TextEditingController
          _myOTP.text,
          _myPassword.text);

      if (response != null) {
        // Handle successful response (perhaps show a success message to the user)
        // ignore: use_build_context_synchronously
        ViewUtils.showCustomDialog(
            context, "Success", "Password reset successful", () {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(), // Pass refresh token here
            ),
          );
        });
      } else {
        // Handle the case where resetPassword failed
        // ignore: use_build_context_synchronously
        ViewUtils.showCustomDialog(
            context, "Error", "Failed to reset the password", () {
          Navigator.of(context).pop();
        });
      }
    } catch (e) {
      print('Error in _RestPassword: $e');
      // Handle other errors (you may choose to show another error dialog here)
      // ignore: use_build_context_synchronously
      ViewUtils.showCustomDialog(context, "Error", "Something went wrong", () {
        Navigator.of(context).pop();
      });
    }

    setState(() {
      _isLoading = false; // Stop loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            BasicNavigationBar(),
            if (!_isSuccess)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: Container(
                  width: 600,
                  padding: const EdgeInsets.all(40),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                    color: AppColors.neutral,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        AppIcons.fnb_logo,
                        height: 50,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const CustomTextField(
                          text: 'Forgot Password',
                          fontWeight: FontWeight.w600,
                          size: 20,
                          color: AppColors.white),
                      const SizedBox(
                        height: 10,
                      ),
                      const CustomTextField(
                          text:
                              "Please Provide the Email address linked your account. Once you have submited your email we'll send you an OTP",
                          fontWeight: FontWeight.w400,
                          size: 12,
                          textAlign: TextAlign.center,
                          color: AppColors.white),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CustomTextInput(
                            backgroundColor: AppColors.neutral,
                            width: 250,
                            textColor: AppColors.white,
                            borderColor: AppColors.white,
                            keyboardType: TextInputType.emailAddress,
                            controller: _myEmail,
                            hint: 'Enter your email address',
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 35,
                      ),
                      _isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.white)
                          : AppButtons(
                              textColor: AppColors.white,
                              backgroundColor: AppColors.primaryColor,
                              borderColor: AppColors.white,
                              text: 'Submit',
                              width: 237,
                              height: 50,
                              onPressed: () {
                                _forgotPassword();
                              },
                            ),
                      const SizedBox(
                        height: 25,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 30, right: 30),
                        child: const Text(
                          '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w300,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isSuccess) // Show this if _isSuccess is true
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: Container(
                  width: 600,
                  padding: const EdgeInsets.all(40),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                    color: AppColors.neutral,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        AppIcons.fnb_logo,
                        height: 50,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const CustomTextField(
                          text: 'Forgot Password',
                          fontWeight: FontWeight.w600,
                          size: 20,
                          color: AppColors.white),
                      const SizedBox(
                        height: 10,
                      ),
                      const CustomTextField(
                          text:
                              'Take a moment to fill out this form & we will help you get your desk',
                          fontWeight: FontWeight.w400,
                          size: 12,
                          textAlign: TextAlign.center,
                          color: AppColors.white),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextInput(
                            backgroundColor: AppColors.neutral,
                            width: 210,
                            textColor: AppColors.white,
                            borderColor: AppColors.white,
                            keyboardType: TextInputType.text,
                            controller: _myOTP,
                            hint: 'Enter your OPT',
                          ),
                          CustomTextInput(
                            backgroundColor: AppColors.neutral,
                            width: 210,
                            textColor: AppColors.white,
                            borderColor: AppColors.white,
                            keyboardType: TextInputType.visiblePassword,
                            controller: _myPassword,
                            obscureText: true,
                            hint: 'Enter your new password',
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 35,
                      ),
                      _isLoading
                          ? CircularProgressIndicator(color: AppColors.white)
                          : AppButtons(
                              textColor: AppColors.white,
                              backgroundColor: AppColors.primaryColor,
                              borderColor: AppColors.white,
                              text: 'Next',
                              width: 237,
                              height: 50,
                              onPressed: () {
                                _RestPassword();
                              },
                            ),
                      const SizedBox(
                        height: 25,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 30, right: 30),
                        child: const Text(
                          'In order to continue you should agree to our T&Cs. By continuing you confirm that you accept our T&C, and that you have read and accepted our privacy policy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w300,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
