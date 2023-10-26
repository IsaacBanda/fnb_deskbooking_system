import 'package:fnb_deskbooking_system/exports/export.dart';

class BasicNavigationBar extends StatelessWidget {

  BasicNavigationBar({
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
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            },
            child: const CustomTextField(
              text: '',
              fontWeight: FontWeight.w600,
              size: 14,
              color: AppColors.secondaryColor,
            ),
          ),
          const SizedBox(
            width: 20,
          ),
          GestureDetector(
            onTap: () async {

              
            },
            child: const CustomTextField(
              text: '',
              fontWeight: FontWeight.w600,
              size: 14,
              color: AppColors.white,
            ),
          ),
          const SizedBox(
            width: 30,
          )
        ],
      ),
    );
  }
}
