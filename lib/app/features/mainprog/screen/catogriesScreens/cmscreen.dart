import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:flutter/material.dart';

class Cmscreen extends StatelessWidget {
  const Cmscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Container(
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(20),
          color: const Color.fromARGB(255, 243, 212, 101),
        ),
        child: Center(
          child: Text(
            'تحت الانشاء ',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              fontFamily: Appfontstring.ChangaLight,
            ),
          ),
        ),
      ),
    );
  }
}
