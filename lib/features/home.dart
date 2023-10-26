import 'package:fnb_deskbooking_system/project_assets/widget/basic_nav.dart';

import '../exports/export.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    double containerWidth = MediaQuery.of(context).size.width * 0.6;
    double containerHeight = MediaQuery.of(context).size.height * 0.5;

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Column(
        children: [
          BasicNavigationBar(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: containerWidth,
                height: containerHeight,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomTextField(
                      text: 'DESK BOOKING SYSTEM',
                      fontWeight: FontWeight.w700,
                      size: 42,
                      color: AppColors.white,
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    const SizedBox(
                      width: 500,
                      child: CustomTextField(
                        text: 'A convenient space booking module that will improve the safety and agility of your office.Create an activity-based workplace that does not confine employees to their desks',
                        fontWeight: FontWeight.w400,
                        size: 14,
                        color: AppColors.white,
                      ),
                    ),
                    const Spacer(),
                    AppButtons(
                      text: 'Get Started',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      textColor: AppColors.primaryColor,
                      backgroundColor: AppColors.white,
                      borderColor: AppColors.white,
                      width: 140,
                      height: 45,
                    )
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Image.asset('assets/images/home.png'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
