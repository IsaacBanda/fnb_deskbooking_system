import 'package:fnb_deskbooking_system/exports/export.dart';

class CustomTextInput extends StatefulWidget {
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final double width;
  final TextInputType keyboardType;
  final String hint;
  final Widget? prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? prefixText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function()? onSubmitted;

  const CustomTextInput({
    Key? key,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    this.borderRadius = 5,
    required this.width,
    required this.keyboardType,
    required this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixText,
    this.maxLength,
    this.inputFormatters,
    this.controller,
    this.validator,
    this.onSubmitted,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CustomTextInputState createState() => _CustomTextInputState();
}

class _CustomTextInputState extends State<CustomTextInput> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(right: 20, left: 20, top: 0, bottom: 0),
      width: widget.width,
      height: 50,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: widget.borderColor),
        boxShadow: const [AppShadows.boxShadow],
      ),
      child: TextFormField(
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          color: widget.textColor,
          fontSize: 13.0,
        ),
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        controller: widget.controller,
        validator: widget.validator,
        onFieldSubmitted: (_) {
          _focusNode.unfocus();
          if (widget.onSubmitted != null) {
            widget.onSubmitted!();
          }
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          prefixText: widget.prefixText,
          contentPadding: const EdgeInsetsDirectional.only(top: 0),
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: widget.textColor,
            fontWeight: FontWeight.w400,
          ),
          hintText: widget.hint,
        ),
      ),
    );
  }
}
