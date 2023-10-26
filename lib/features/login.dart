import 'dart:convert';
import 'dart:io';
import 'package:fnb_deskbooking_system/exports/export.dart';
import 'package:fnb_deskbooking_system/features/building.dart';
import 'package:fnb_deskbooking_system/features/forgotPassword.dart';
import 'package:fnb_deskbooking_system/project_assets/widget/basic_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../configerations/configs.dart';
import '../project_assets/widget/custom_textinput.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isChecked = false;
  final TextEditingController _myPassword = TextEditingController();
  final TextEditingController _myEmail = TextEditingController();
  late SharedPreferences _preferences;
  bool _isLoading = false; // Add this line

  @override
  void initState() {
    super.initState();
    initSharedPreference();
  }

  void initSharedPreference() async {
    _preferences = await SharedPreferences.getInstance();
  }

  void loginUser() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    if (_myEmail.text.isNotEmpty && _myPassword.text.isNotEmpty) {
      var loginBody = {
        "username": _myEmail.text,
        "password": _myPassword.text,
      };

      try {
        var response = await http.post(
          Uri.parse(Endpoints.authenticate),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(loginBody),
        );

        print('Response: ${response.body}');

        if (response.statusCode == 401) {
          var jsonResponse = jsonDecode(response.body);
          var detailMessage = jsonResponse['detail'];
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

        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse != null) {
          var myToken = jsonResponse['access'];
          var myRefreshToken =
              jsonResponse['refresh']; // Extract the refresh token here
          if (myToken != null) {
            // Show the successful login dialog
            // ignore: use_build_context_synchronously
            ViewUtils.showCustomDialog(
                context, "Login successful", "Welcome", () {});

            // Use a delay before navigating to the BuildingScreen
            Future.delayed(const Duration(seconds: 1), () {
              Navigator.of(context).pop(); // Closes the dialog
              _preferences.setString('token', myToken);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => BuildingScreen(
                      token: myToken,
                      myRefreshToken: myRefreshToken), // Pass refresh token here
                ),
              );
            });
          } else {
            // ignore: use_build_context_synchronously
            ViewUtils.showCustomDialog(context, "Error", "Token is null", () {
              Navigator.of(context).pop();
            });
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Column(
        children: [
          BasicNavigationBar(),
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
                      text: 'Login',
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
                        width: 200,
                        textColor: AppColors.white,
                        borderColor: AppColors.white,
                        keyboardType: TextInputType.name,
                        controller: _myEmail,
                        hint: 'Enter your username',
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      CustomTextInput(
                        backgroundColor: AppColors.neutral,
                        width: 200,
                        textColor: AppColors.white,
                        borderColor: AppColors.white,
                        keyboardType: TextInputType.visiblePassword,
                        controller: _myPassword,
                        obscureText: true,
                        hint: 'Enter your password',
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Theme(
                            data: ThemeData(
                              splashColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                            ),
                            child: Checkbox(
                              value: _isChecked,
                              onChanged: (bool? value) {
                                setState(() {
                                  _isChecked = value!;
                                });
                              },
                              activeColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                          Text(
                            'Remember me',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const CustomTextField(
                          text: 'Forgot Password?',
                          fontWeight: FontWeight.w400,
                          size: 12,
                          color: AppColors.white,
                        ),
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
                            loginUser();
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
    );
  }
}
