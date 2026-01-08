import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:flutter/material.dart';

class LogBackGroung extends StatelessWidget {
  const LogBackGroung({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppimageString.image55),
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}

class CustomTextFormFieldlogin extends StatefulWidget {
  final String hinttext;
  final IconData icon;
  final bool? obscureText;
  final String labelText;
  final TextEditingController? mycontroller;
  final String? Function(String?)? valid;
  final TextInputType keyboardType;

  const CustomTextFormFieldlogin({
    super.key,
    required this.hinttext,
    required this.icon,
    required this.labelText,
    required this.mycontroller,
    this.valid,
    required this.keyboardType,
    this.obscureText,
  });

  @override
  CustomTextFormFieldloginState createState() =>
      CustomTextFormFieldloginState();
}

class CustomTextFormFieldloginState extends State<CustomTextFormFieldlogin> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText ?? false;
  }

  void toggleObscureText() {
    if (mounted) {
      setState(() {
        _obscureText = !_obscureText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.mycontroller,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      validator: widget.valid,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        // FIXED: Bug #2 - Conditional suffixIcon for obscureText only
        suffixIcon: widget.obscureText == true
            ? InkWell(
                onTap: toggleObscureText,
                child: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
              )
            : null,
        alignLabelWithHint: false,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        floatingLabelAlignment: FloatingLabelAlignment.start,
        hintText: widget.hinttext,
        hintStyle: const TextStyle(
          color: Color.fromARGB(103, 194, 184, 184),
          fontSize: 15,
        ),
        labelText: widget.labelText,
        labelStyle: const TextStyle(color: Colors.white),
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(30),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({
    super.key,
    required this.buttonHeight,
    required this.isLoading,
    required this.buttonwidth,
    this.onPressed,
  });

  final double buttonHeight;
  final double buttonwidth;
  final bool isLoading;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: buttonwidth,
      height: buttonHeight,
      decoration: BoxDecoration(
        boxShadow: const [BoxShadow(color: Colors.white, blurRadius: 3)],
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Colors.cyanAccent,
            Color.fromARGB(255, 59, 136, 62),
          ],
        ),
      ),
      child: ElevatedButton(
        // FIXED: Bug #3 - Disable onPressed during loading to prevent multi-taps
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'تسجيل',
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: Appfontstring.ChangaLight,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}
