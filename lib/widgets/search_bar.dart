import 'package:flutter/material.dart';

class HomeSearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  const HomeSearchBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: onTap != null,
      onTap: onTap,
      style: const TextStyle(
        color: Color(0xFFF7DFA5),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: const Color(0xFFF7DFA5),
      decoration: InputDecoration(
        hintText: 'Search eco-friendly trips',
        hintStyle: const TextStyle(
          color: Color(0xFFF7DFA5),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        prefixIcon: const Icon(Icons.search, color: Color(0xFFF7DFA5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.14),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
