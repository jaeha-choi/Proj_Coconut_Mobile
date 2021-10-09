import 'package:flutter/material.dart';

class BoarderBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double width, height;

  const BoarderBox(
      {Key? key,
      required this.padding,
      required this.width,
      required this.height,
      required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
          color: Colors.teal,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withAlpha(40), width: 2)),
      child: Center(child: child),
    );
  }
}
