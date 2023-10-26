import 'package:fnb_deskbooking_system/exports/export.dart';

class AppCheckbox extends StatefulWidget {
  final bool isChecked;
  final double size;
  const AppCheckbox({Key? key, required this.isChecked, required this.size})
      : super(key: key);

  @override
  State<AppCheckbox> createState() => _AppCheckboxState();
}

class _AppCheckboxState extends State<AppCheckbox> {
  bool _isSelected = true;

  @override
  void initState() {
    _isSelected = widget.isChecked;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _isSelected = widget.isChecked;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSelected = !_isSelected;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastLinearToSlowEaseIn,
        decoration: BoxDecoration(
          color: _isSelected ? AppColors.secondaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          border: _isSelected
              ? null
              : Border.all(
                  color: AppColors.secondaryColor,
                  width: 2.0,
                ),
        ),
        width: 22,
        height: 22,
        child: _isSelected
            ? const Icon(
                Icons.check,
                color: AppColors.secondaryColor,
                size: 15,
              )
            : null,
      ),
    );
  }
}
