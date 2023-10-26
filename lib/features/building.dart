import 'dart:io';
import 'package:fnb_deskbooking_system/model/GetBuilding/GetBuilding.dart';
import 'package:fnb_deskbooking_system/features/select_floor.dart';
import '../model/GetBuilding/GetBuildingPercentage.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import '../exports/export.dart';

class BuildingScreen extends StatefulWidget {
  final String token;
  final String myRefreshToken; // New parameter

  const BuildingScreen({required this.token, required this.myRefreshToken});

  @override
  State<BuildingScreen> createState() => _BuildingScreenState();
}

class _BuildingScreenState extends State<BuildingScreen> {
  late Future<List<Buildings>> futureBuildings;
  BuildingPercentage? buildingPercentageData;
  int _currentIndex = 0;
  final bool _isLoading = false;

  String getCurrentDate() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(now);
  }

  @override
  void initState() {
    super.initState();
    futureBuildings = APIService().fetchBuildings(widget.token);

    // Fetch the building percentage data for the initial building.
    _fetchBuildingPercentage();
  }

  void _fetchBuildingPercentage() async {
    final currentBuildingId = (await futureBuildings)[_currentIndex].buildingId;
    final percentageData = await APIService().getBuildingPercentage(
        widget.token, getCurrentDate(), currentBuildingId);

    setState(() {
      buildingPercentageData = percentageData;
    });
  }

  void _onPageChanged(int index, CarouselPageChangedReason reason) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: FutureBuilder<List<Buildings>>(
        future: futureBuildings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final buildings = snapshot.data!;
            final building = buildings[_currentIndex];
            DateTime currentDate = DateTime.now();

            // Format the date as a text string
            String formattedDate = "${currentDate.year}-${currentDate.month}-${currentDate.day}";


            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomNavigationBar(
                    token: widget.token,
                    refreshToken: widget.myRefreshToken,
                    onLogoutSuccess: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                  ),
                  const CustomTextField(
                    text: 'Select Building',
                    size: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                  const SizedBox(height: 30),
                  const CustomTextField(
                    text:
                        'Select a building of you choice by swiping and pressing the continue building',
                    size: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                  const SizedBox(height: 50),
                  CarouselSlider(
                    items: buildings.map((building) {
                      return Image.asset(
                        'assets/images/buildings/${building.buildingId}.png', // Assuming image naming follows a pattern like "1.png", "2.png", ...
                        fit: BoxFit.cover,
                      );
                    }).toList(),
                    options: CarouselOptions(
                      height: 300,
                      viewportFraction: 1.0,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      initialPage: _currentIndex,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    text: building.buildingName,
                    size: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                  const SizedBox(height: 20),
                  if (buildingPercentageData != null)

                    CustomTextField(
                      text:
                                '$formattedDate', // Replace with appropriate value from buildingPercentageData
                      size: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  const SizedBox(height: 20),

                  CustomTextField(
                      text:
                          '${buildingPercentageData?.capacity ?? 'Loading...'}%', // Replace with appropriate value from buildingPercentageData
                      size: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  const SizedBox(height: 50),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppButtons(
                        text: 'Back',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        textColor: AppColors.white,
                        backgroundColor: AppColors.primaryColor,
                        borderColor: AppColors.white,
                        width: 150,
                        height: 50,
                      ),
                      const SizedBox(width: 20),
                      _isLoading
                          ? const SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                              ),
                            )
                          : AppButtons(
                              text: 'Continue',
                              onPressed: () {
                                final buildings = snapshot.data!;
                                final selectedBuildingId =
                                    buildings[_currentIndex].buildingId;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SelectFloorScreen(
                                      token: widget.token,
                                      buildingId: selectedBuildingId,
                                      myRefreshToken: widget.myRefreshToken,
                                      buildingName: building.buildingName,
                                    ),
                                  ),
                                );
                              },
                              textColor: AppColors.primaryColor,
                              backgroundColor: AppColors.white,
                              borderColor: AppColors.white,
                              width: 150,
                              height: 50,
                            ),
                    ],
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}
