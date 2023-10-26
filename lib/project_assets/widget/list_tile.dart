// ignore: must_be_immutable
import '../../exports/export.dart';

// ignore: must_be_immutable
class CustomListTile extends StatelessWidget {
  final String? svgScr, buildingName, floorNum, seatNo, startTime, endTime, reserveDate, datebooked;
  double? width;
  double? height;
  CustomListTile({
    Key? key,
    this.svgScr,
    this.buildingName,
    this.floorNum,
    this.seatNo,
    this.startTime,
    this.endTime,
    this.reserveDate,
    this.datebooked,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 5.0, right: 5.0),
      child: Container(
        padding:
            const EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: AppColors.primaryColor,
          boxShadow: const [
            AppShadows.boxShadow,
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (svgScr != null) // Check if svgScr is not null
            SvgPicture.asset(
              svgScr!,
              width: 35,
            ),
            CustomTextField(
              text: seatNo?? "N/A",
              fontWeight: FontWeight.w500,
              size: 14,
              color: AppColors.white,
            ),
              CustomTextField(
              text: buildingName?? "N/A",
              fontWeight: FontWeight.w500,
              size: 14,
              color: AppColors.white,
            ),
            CustomTextField(
              text: floorNum?? "N/A",
              fontWeight: FontWeight.w500,
              size: 14,
              color: AppColors.white,
            ),
            CustomTextField(
              text: startTime?? "N/A",
              fontWeight: FontWeight.w500,
              size: 14,
              color: AppColors.white,
            ),
            CustomTextField(
              text: endTime?? "N/A",
              fontWeight: FontWeight.w500,
              size: 14,
              color: AppColors.white,
            ),
            CustomTextField(
              text: reserveDate?? "N/A",
              fontWeight: FontWeight.w500,
              size: 14,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}
