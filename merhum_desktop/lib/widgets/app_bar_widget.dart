import 'package:flutter/material.dart';
import '../utils/constants.dart';

class MerhumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const MerhumAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: AppTextStyles.heading2),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textDark,
      elevation: 1,
    );
  }
}
