import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField(
      {super.key,
      required this.controller,
      this.isPassword = false,
      this.focusNode,
      this.readOnly,
      this.inputFormatters,
      this.inputType,
      this.validator,
      this.onTap,
      this.hintText});
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final bool? readOnly;
  final bool isPassword;
  final Function()? onTap;
  final TextInputType? inputType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late bool obsecureText;
  @override
  void initState() {
    super.initState();
    obsecureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      height: screenWidth > 450 ? 70 : 50,
      width: screenWidth,
      child: TextFormField(
        onTap: widget.onTap,
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: obsecureText,
        readOnly: widget.readOnly ?? false,
        validator: widget.validator,
        keyboardType: widget.inputType,
        inputFormatters: widget.inputFormatters,
        style: screenWidth > 450
            ? TextStyle(fontSize: BibleInfo.fontSizeScale * 24)
            : TextStyle(),
        decoration: InputDecoration(
          filled: true,
          fillColor: CommanColor.lightDarkPrimary200(context).withOpacity(0.4),
          suffixIcon: widget.isPassword
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      obsecureText = !obsecureText;
                    });
                  },
                  child: Icon(
                    !obsecureText ? Icons.visibility : Icons.visibility_off,
                    size: screenWidth > 450 ? 40 : null,
                  ))
              : null,
          contentPadding: EdgeInsets.symmetric(
              horizontal: screenWidth > 450 ? 17 : 12,
              vertical: screenWidth > 450 ? 20 : 1),
          hintText: widget.hintText,
          hintStyle: const TextStyle(fontWeight: FontWeight.w300),
          focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  width: 1.5,
                  color: Get.theme.inputDecorationTheme.errorBorder?.borderSide
                          .color ??
                      Colors.red)),
          errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  width: 1.5,
                  color: Get.theme.inputDecorationTheme.errorBorder?.borderSide
                          .color ??
                      Colors.red)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  width: 0, color: Colors.transparent.withOpacity(0.5))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  width: 0, color: Colors.transparent.withOpacity(0.5))),
        ),
      ),
    );
  }
}
