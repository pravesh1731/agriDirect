
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/device_helper.dart';

class UElevatedButton extends StatelessWidget {
  const UElevatedButton({
    super.key, 
    required this.onPressed, 
    required this.child,
    this.backgroundColor,
    this.gradient,
  });

  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Gradient? gradient;
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: UDeviceHelper.getScreenWidth(context),
        child: gradient != null
          ? Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: UColors.transparent,
                  shadowColor: UColors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: child,
              ),
            )
          : ElevatedButton(
              onPressed: onPressed, 
              style: backgroundColor != null 
                ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
                : null,
              child: child,
            ));
  }
}