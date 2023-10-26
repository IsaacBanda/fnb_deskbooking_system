import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:fnb_deskbooking_system/exports/export.dart';
import 'package:fnb_deskbooking_system/features/building.dart';
import 'package:fnb_deskbooking_system/model/GetFloor/GetFloor.dart';
import 'package:fnb_deskbooking_system/model/GetBuilding/GetBuilding.dart';

class SelectFloorScreen extends StatefulWidget {
  final int buildingId;
  final String token;
  final String myRefreshToken;
  final String buildingName;

  const SelectFloorScreen({
    required this.buildingId,
    Key? key,
    required this.token,
    required this.myRefreshToken,
    required this.buildingName,
  }) : super(key: key);

  @override
  State<SelectFloorScreen> createState() => _SelectFloorScreenState();
}

class _SelectFloorScreenState extends State<SelectFloorScreen> {
  late List<Floors> floors = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBuildingFloors();
  }

  Future<void> _fetchBuildingFloors() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse('${APIService.baseUrl}/api/floors/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'building_id': widget.buildingId}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        setState(() {
          floors = jsonResponse.map((data) => Floors.fromJson(data)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load floors');
      }
    } catch (e) {
      print('Error fetching floor seats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
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
            CustomTextField(
              text: 'Select a Floor on ${widget.buildingName}',
              size: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 1000,
                height: 580,
                padding: const EdgeInsets.symmetric(
                  horizontal: 100,
                  vertical: 10,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                  ),
                )
                    : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: floors.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final floor = floors[index];
                    return GestureDetector(
                      onTap: () async {
                        setState(() {
                          _isLoading = true;
                        });

                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FloorScreen(
                              token: widget.token,
                              floorId: floor.floorId,
                              myRefreshToken: widget.myRefreshToken,
                             // buildingNamef: widget.buildingName
                            ),
                          ),
                        );

                        setState(() {
                          _isLoading = false;
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        padding: const EdgeInsets.all(40),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: AppColors.neutral,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SvgPicture.asset(AppIcons.floor),
                              CustomTextField(
                                text: 'Floor: ${floor.floorNo}',
                                fontWeight: FontWeight.w600,
                                size: 25,
                                color: AppColors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButtons(
                  text: 'Back',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  textColor: AppColors.white,
                  backgroundColor: AppColors.neutral,
                  borderColor: AppColors.white,
                  width: 140,
                  height: 45,
                ),
                const SizedBox(width: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
