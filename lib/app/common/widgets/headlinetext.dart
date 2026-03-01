import 'package:amiraly/app/util/constant/constants.dart';
import 'package:flutter/material.dart';

class TextLine extends StatelessWidget {
  final String text;
  final Color color;
  final String? fontFamily;
  final FontWeight? fontWeight;
  final double? fontSize;
  const TextLine({
    super.key,
    required this.text,
    required this.color,
    this.fontFamily,
    this.fontWeight,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [Appfontstring.ChangaLight],
        fontWeight: fontWeight,
        fontSize: fontSize,
        color: color,
      ),
    );
  }
}

class TextRichLine extends StatelessWidget {
  final String text1;
  final String text2;
  final String text3;
  final String text4;
  final Color color1;
  final Color color2;
  final Color color3;
  final Color color4;
  final double fontSize1;
  final double fontSize2;
  final double fontSize3;
  final double fontSize4;

  const TextRichLine(
      {super.key,
      required this.text1,
      required this.text2,
      required this.text3,
      required this.text4,
      required this.color1,
      required this.color2,
      required this.color3,
      required this.color4,
      required this.fontSize1,
      required this.fontSize2,
      required this.fontSize3,
      required this.fontSize4});

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(children: [
      TextSpan(
          text: text1,
          style: TextStyle(
            fontFamily: Appfontstring.ChangaLight,
            fontWeight: FF.B,
            fontSize: fontSize1,
            color: color1,
          )),
      TextSpan(
          text: 'owered',
          style: TextStyle(
              fontFamily: Appfontstring.ChangaLight,
              fontWeight: FF.B,
              fontSize: fontSize2,
              color: color2)),
      TextSpan(
          text: text3,
          style: TextStyle(
              fontFamily: Appfontstring.ChangaLight,
              fontWeight: FF.B,
              fontSize: fontSize3,
              color: color3)),
      TextSpan(
          text: text4,
          style: TextStyle(
              fontFamily: Appfontstring.ChangaLight,
              fontWeight: FF.B,
              fontSize: fontSize4,
              color: color4))
    ]));
  }
}

class HeadlineText extends StatelessWidget {
  final VoidCallback? onSeeAllPressed;
  final double screenHeight;
  final double screenWidth;
  final double fontSize;
  final String headlineText;
  final String fontfamily;
  final Color color1;
  final Color color2;
  final String buttomheadlineText;

  final bool isSeeAllVisible;

  const HeadlineText({
    super.key,
    required this.screenHeight,
    required this.screenWidth,
    required this.fontSize,
    required this.headlineText,
    required this.buttomheadlineText,
    required this.isSeeAllVisible,
    this.onSeeAllPressed,
    required this.fontfamily,
    required this.color1,
    required this.color2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isSeeAllVisible)
            Text(
              textAlign: TextAlign.right,
              headlineText,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                fontFamily: fontfamily,
                fontFamilyFallback: const [Appfontstring.ChangaLight],
                color: color1,
              ),
            ),
          TextButton(
            onPressed: onSeeAllPressed,
            child: Container(
              width: screenWidth * 0.1,
              height: screenHeight * 0.08,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey),
              ),
              child: Text(
                textAlign: TextAlign.center,
                buttomheadlineText,
                style: TextStyle(
                  fontSize: fontSize * 0.7,
                  fontFamily: fontfamily,
                  fontFamilyFallback: const [Appfontstring.ChangaLight],
                  color: color2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
