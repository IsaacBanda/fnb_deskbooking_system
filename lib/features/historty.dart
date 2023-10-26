import 'dart:convert';
import '../exports/export.dart';
import '../project_assets/utils/DateFormatter.dart';

class HistroyScreen extends StatefulWidget {
  final String token;
  final String myRefreshToken;

  const HistroyScreen(
      {Key? key, required this.token, required this.myRefreshToken})
      : super(key: key);

  @override
  State<HistroyScreen> createState() => _HistroyScreenState();
}

class _HistroyScreenState extends State<HistroyScreen> {
  int? userId;
  var isLoaded = false;
  bool dataFetched = false; // New flag
  List<BookingHistory>? bookingHistory;
  List<CurrentBooking>? currentbooking;

  @override
  void initState() {
    super.initState();
    _extractUserIdFromToken();
  }

  void _extractUserIdFromToken() {
    final tokenParts = widget.token.split('.');
    if (tokenParts.length == 3) {
      final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1]))));
      if (payload.containsKey('user_id')) {
        userId = payload['user_id'];
      }
    }
  }

  Future<void> getbookingHistory() async {
    if (userId != null) {
      List<BookingHistory>? fetchedBookings =
          await APIService().getUserBookings(userId!, widget.token);
      if (fetchedBookings != null) {
        setState(() {
          bookingHistory = fetchedBookings;
        });
      }
    }
  }

  Future<void> getCurrentBooking() async {
    if (userId != null) {
      List<CurrentBooking>? fetchedCurrentBookings =
          await APIService().getUserCurrentBooking(userId!, widget.token);
      if (fetchedCurrentBookings != null) {
        setState(() {
          currentbooking = fetchedCurrentBookings;
        });
      }
    }
  }

  Future<void> fetchAllData() async {
    await Future.wait([
      getCurrentBooking(),
      getbookingHistory(),
    ]);
    setState(() {
      dataFetched = true;
    });
  }

  String _getSvgAssetForSeatStatus(String seatStatus) {
    switch (seatStatus) {
      case 'Free':
        return AppIcons.green_seat;
      case 'Busy':
        return AppIcons.red_seat;
      case 'Partially':
        return AppIcons.yellow_seat;
      case 'Reserved':
        return AppIcons.disabled_seat;
      case 'InUse':
        return AppIcons.blue_seat;
      default:
        return AppIcons.disabled_seat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: FutureBuilder(
        future: dataFetched ? Future.value() : fetchAllData(),
        builder: (context, snapshot) {
          if (!dataFetched) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            String firstName =
                (bookingHistory != null && bookingHistory!.isNotEmpty)
                    ? bookingHistory![0].firstName
                    : 'Loading...';
            String lastName =
                (bookingHistory != null && bookingHistory!.isNotEmpty)
                    ? bookingHistory![0].lastName
                    : '';
            String reservedDateHist =
                (bookingHistory != null && bookingHistory!.isNotEmpty)
                    ? DateFormatter.format(
                        bookingHistory![0].reservedDate.toIso8601String())
                    : 'Loading...';
            String department =
                (bookingHistory != null && bookingHistory!.isNotEmpty)
                    ? bookingHistory![0].department
                    : 'Loading...';
            String seatNo =
                (currentbooking != null && currentbooking!.isNotEmpty)
                    ? currentbooking![0].seatNo
                    : 'Loading...';
            String floorNo =
                (currentbooking != null && currentbooking!.isNotEmpty)
                    ? currentbooking![0].floorNo
                    : 'Loading...';
            String buildingName =
                (currentbooking != null && currentbooking!.isNotEmpty)
                    ? currentbooking![0].buildingName
                    : 'Loading...';
            String reservedTime =
                (currentbooking != null && currentbooking!.isNotEmpty)
                    ? currentbooking![0].reservedTime
                    : 'Loading...';
            String endOfReservation =
                (currentbooking != null && currentbooking!.isNotEmpty)
                    ? currentbooking![0].endOfReservation
                    : 'Loading...';
            String reservedDate =
                (currentbooking != null && currentbooking!.isNotEmpty)
                    ? DateFormatter.format(
                        currentbooking![0].reservedDate.toIso8601String())
                    : 'Loading...';

            String seatStatus =
                (currentbooking != null && currentbooking!.isNotEmpty)
                    ? currentbooking![0].seatStatus
                    : 'DefaultStatus';
            String svgAssetPath = _getSvgAssetForSeatStatus(seatStatus);

            return SingleChildScrollView(
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          width: 350,
                          height: 220,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.neutral,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 40,
                                    backgroundImage: AssetImage(
                                        'assets/images/profile_pic.png'),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  CustomTextField(
                                    text: '$firstName $lastName',
                                    fontWeight: FontWeight.w700,
                                    size: 16,
                                    color: AppColors.white,
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Row(
                                children: [
                                  const Column(
                                    children: [
                                      CustomTextField(
                                        text: 'Employee ID:',
                                        fontWeight: FontWeight.w600,
                                        size: 14,
                                        color: AppColors.white,
                                      ),
                                      SizedBox(
                                        height: 20,
                                      ),
                                      CustomTextField(
                                        text: 'Department:',
                                        fontWeight: FontWeight.w600,
                                        size: 14,
                                        color: AppColors.white,
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 10),
                                  Column(
                                    children: [
                                      CustomTextField(
                                        text: 'Employee ID:',
                                        fontWeight: FontWeight.w600,
                                        size: 14,
                                        color: AppColors.white,
                                      ),
                                      SizedBox(
                                        height: 20,
                                      ),
                                      CustomTextField(
                                        text: department,
                                        fontWeight: FontWeight.w600,
                                        size: 14,
                                        color: AppColors.white,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 450,
                          height: 220,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.neutral,
                          ),
                          child: Column(
                            children: [
                              const Center(
                                child: CustomTextField(
                                  text:
                                      'Current Reservation', // Display floor number
                                  fontWeight: FontWeight.w600,
                                  size: 25,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomTextField(
                                        text: 'Seat number: $seatNo',
                                        fontWeight: FontWeight.w600,
                                        size: 14,
                                        color: AppColors.white,
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      CustomTextField(
                                        text: 'Floor: $floorNo',
                                        fontWeight: FontWeight.w600,
                                        size: 14,
                                        color: AppColors.white,
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      CustomTextField(
                                        text: 'Building: $buildingName',
                                        fontWeight: FontWeight.w600,
                                        size: 14,
                                        color: AppColors.white,
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      CustomTextField(
                                        text:
                                            'Duration: $reservedTime - $endOfReservation',
                                        fontWeight: FontWeight.w600,
                                        size: 14,
                                        color: AppColors.white,
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      CustomTextField(
                                        text: 'Date: $reservedDate',
                                        fontWeight: FontWeight.w600,
                                        size: 14,
                                        color: AppColors.white,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(svgAssetPath),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      AppButtons(
                                        text: 'Cancel',
                                        onPressed: () {},
                                        textColor: AppColors.white,
                                        backgroundColor: AppColors.primaryColor,
                                        borderColor: AppColors.white,
                                        width: 120,
                                        height: 40,
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    width: 1130,
                    padding: const EdgeInsets.only(
                        left: 100, right: 150, bottom: 15, top: 15),
                    decoration: const BoxDecoration(
                      color: AppColors.neutral,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomTextField(
                          text: 'Seat Status',
                          fontWeight: FontWeight.w600,
                          size: 14,
                          color: AppColors.white,
                        ),
                        CustomTextField(
                          text: 'Seat Number',
                          fontWeight: FontWeight.w600,
                          size: 14,
                          color: AppColors.white,
                        ),
                        CustomTextField(
                          text: 'Building',
                          fontWeight: FontWeight.w600,
                          size: 14,
                          color: AppColors.white,
                        ),
                        CustomTextField(
                          text: 'Floor',
                          fontWeight: FontWeight.w600,
                          size: 14,
                          color: AppColors.white,
                        ),
                        CustomTextField(
                          text: 'Start Time',
                          fontWeight: FontWeight.w600,
                          size: 14,
                          color: AppColors.white,
                        ),
                        CustomTextField(
                          text: 'End Time',
                          fontWeight: FontWeight.w600,
                          size: 14,
                          color: AppColors.white,
                        ),
                        CustomTextField(
                          text: 'Booked For',
                          fontWeight: FontWeight.w600,
                          size: 14,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 1130,
                    height: 400,
                    child: Expanded(
                      child: Container(
                        width: 1130,
                        padding: const EdgeInsetsDirectional.all(20),
                        decoration: const BoxDecoration(
                          color: AppColors.neutral,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: ListView.custom(
                          childrenDelegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              String svgAssetPath = _getSvgAssetForSeatStatus(
                                  bookingHistory![index].seatStatus);
                              // Format reservedDate using DateFormatter
                              String formattedReservedDate =
                                  DateFormatter.format(bookingHistory![index]
                                      .reservedDate
                                      .toString());
                              return CustomListTile(
                                svgScr: svgAssetPath,
                                buildingName:
                                    bookingHistory![index].buildingName,
                                floorNum: bookingHistory![index].floorNo,
                                reserveDate: formattedReservedDate,
                                startTime: bookingHistory![index].reservedTime,
                                endTime:
                                    bookingHistory![index].endOfReservation,
                                height: 80,
                                width: 750,
                                seatNo: bookingHistory![index].seatNo,
                              );
                            },
                            childCount: bookingHistory?.length ?? 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButtons(
                    text: 'Back',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    textColor: AppColors.white,
                    backgroundColor: AppColors.primaryColor,
                    borderColor: AppColors.white,
                    width: 150,
                    height: 50,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
