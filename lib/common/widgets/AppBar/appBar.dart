
import 'package:agri_direct/common/widgets/logo/icon.dart';

import '../../../utils/constants/colors.dart';
import 'package:flutter/material.dart';

class appBar extends StatelessWidget implements PreferredSizeWidget {
  const appBar({
    super.key,
    required this.isDark,
  });

  final bool isDark;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: isDark ? UColors.cardDark : UColors.white,
      elevation: 0,
      title: Row(
        children: [
          logo(isDark, 32, 32),
          const SizedBox(width: 8),
          Text(
            'AgriDirect',
            style: TextStyle(
              color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [

        IconButton(
          icon: Icon(Icons.notifications_outlined,
              color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight),
          onPressed: () {},
        ),
      ],
    );
  }
}