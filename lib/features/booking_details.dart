import 'dart:convert';
import '../configerations/seats.dart';
import '../exports/export.dart';
import '../project_assets/utils/DateFormatter.dart';

class BookingDetailsScreen extends StatefulWidget {
  final AddBookingModel bookingData; // Updated parameter name
  final String token;
  final int floorId;
  final String myRefreshToken;

  const BookingDetailsScreen(
      {Key? key,
      required this.token,
      required this.bookingData,
      required this.floorId,
      required this.myRefreshToken})
      : super(key: key);

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final APIService _apiService =
      APIService(); // Create an instance of APIService

  @override
  void initState() {
    super.initState();
    _extractUserIdFromToken();
    _fetchBookingData();
    print('initState: _fetchBookingData called'); // Add this line
  }

  int? userId; // Store the user ID
  void _extractUserIdFromToken() {
    // Decode the token payload to extract the user ID
    final tokenParts = widget.token.split('.');
    if (tokenParts.length == 3) {
      final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1]))));
      if (payload.containsKey('user_id')) {
        userId = payload['user_id'];
      }
    }
  }

  Booking? _bookingDetails;
  Future<void> _fetchBookingData() async {
    try {
      final bookingId = widget.bookingData.bookingId;
      final response = await _apiService.fetchBookingDetails(
          widget.token, bookingId!); // Call the instance method
      // Check if the response is not null
      if (response != null) {
        final booking =
            response; // Access the first (and only) element of the list
        setState(() {
          _bookingDetails =
              Booking.fromJson(booking); // Parse booking details from the map
        });
      } else {
        // Handle the case where booking details are not found
      }
    } catch (e) {
      print('Error in _fetchBookingData: $e');
    }
  }

  Future<void> _handleCancelBooking(
      String token, int bookingId, BuildContext context) async {
    final result = await _apiService.deleteBooking(token, bookingId);

    if (result != null) {
      // ignore: use_build_context_synchronously
      ViewUtils.showCustomDialog(context, 'Booking Cancelled', result.message,
          () {
        //Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FloorScreen(
              token: widget.token,
              floorId: widget.floorId,
              myRefreshToken: widget.myRefreshToken,

            ),
          ),
        );
      });
    } else {
      // ignore: use_build_context_synchronously
      ViewUtils.showCustomDialog(
        context,
        'Error',
        'Failed to cancel booking. Please try again.',
        () => Navigator.of(context).pop(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedReservedDate = _bookingDetails == null || _bookingDetails!.reservedDate == null 
    ? 'Loading...' 
    : DateFormatter.format(_bookingDetails!.reservedDate!.toIso8601String());

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Column(
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: 600,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(10),
                  ),
                  color: AppColors.neutral,
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CustomTextField(
                      text: 'Current Seat Details',
                      fontWeight: FontWeight.w600,
                      size: 24,
                      color: AppColors.white,
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    const SizedBox(
                      width: 400,
                      child: CustomTextField(
                        text:
                            'A convenient space booking module that will improve the safety and agility of your office.',
                        fontWeight: FontWeight.w400,
                        size: 12,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextOutput(
                          backgroundColor: AppColors.neutral,
                          text: widget.bookingData.bookingId.toString() ?? '',
                          textColor: AppColors.white,
                          width: 200,
                          borderColor: AppColors.white,
                        ),
                        TextOutput(
                          backgroundColor: AppColors.neutral,
                          text:
                              '${_bookingDetails?.firstname ?? 'Loading...'} ${_bookingDetails?.lastname ?? ''}',
                          textColor: AppColors.white,
                          width: 200,
                          borderColor: AppColors.white,
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Container(
                      width: 500,
                      padding: const EdgeInsets.only(right: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                text: 'Seat Number:',
                                fontWeight: FontWeight.w600,
                                size: 12,
                                color: AppColors.white,
                              ),
                              CustomTextField(
                                text: 'Floor:',
                                fontWeight: FontWeight.w600,
                                size: 12,
                                color: AppColors.white,
                              ),
                              CustomTextField(
                                text: 'Building:',
                                fontWeight: FontWeight.w600,
                                size: 12,
                                color: AppColors.white,
                              ),
                              CustomTextField(
                                text: 'Duration:',
                                fontWeight: FontWeight.w600,
                                size: 12,
                                color: AppColors.white,
                              ),
                              CustomTextField(
                                text: 'Date:',
                                fontWeight: FontWeight.w600,
                                size: 12,
                                color: AppColors.white,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                text: _bookingDetails?.seatNo ?? 'Loading...',
                                fontWeight: FontWeight.w400,
                                size: 12,
                                color: AppColors.white,
                              ),
                              CustomTextField(
                                text: _bookingDetails?.floorNo ?? 'Loading...',
                                fontWeight: FontWeight.w400,
                                size: 12,
                                color: AppColors.white,
                              ),
                              CustomTextField(
                                text: _bookingDetails?.buildingName ??
                                    'Loading...',
                                fontWeight: FontWeight.w400,
                                size: 12,
                                color: AppColors.white,
                              ),
                              CustomTextField(
                                text:
                                    '${_bookingDetails?.reservedTime ?? 'Loading...'} - ${_bookingDetails?.endOfReservation ?? ''}',
                                fontWeight: FontWeight.w400,
                                size: 12,
                                color: AppColors.white,
                              ),
                              CustomTextField(
                                text:
                                    '${formattedReservedDate}',
                                fontWeight: FontWeight.w400,
                                size: 12,
                                color: AppColors.white,
                              ),
                            ],
                          ),
                          SvgPicture.asset(_getSvgAssetForSeatStatus(
                              widget.bookingData.seatStatus ?? 'Free'))
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      width: 400,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20.0), // Add some spacing
                          const SizedBox(height: 20.0), // Add some more spacing
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              AppButtons(
                                text: 'Cancel',
                                onPressed: () {
                                  // Fetch the bookingId from the widget's bookingData property
                                  int? bookingId = widget.bookingData.bookingId;

                                  // Ensure bookingId is not null
                                  if (bookingId != null) {
                                    _handleCancelBooking(
                                        widget.token, bookingId, context);
                                  }
                                },
                                textColor: AppColors.primaryColor,
                                backgroundColor: AppColors.white,
                                borderColor: AppColors.white,
                                width: 140,
                                height: 45,
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 600,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(50)),
                child: Image.asset(
                  'assets/images/home.png',
                  fit: BoxFit.cover,
                ),
              ),
            ],
          )
        ],
      ),
    );
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
}
