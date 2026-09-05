import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Search box shown above a reference data table.
class ListSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const ListSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 18),
          isDense: true,
          border: const OutlineInputBorder(),
          hintStyle: AppTextStyles.caption,
        ),
      ),
    );
  }
}
