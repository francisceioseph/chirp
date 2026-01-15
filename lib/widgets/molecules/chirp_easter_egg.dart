import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChirpEasterEgg extends StatelessWidget {
  const ChirpEasterEgg({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Image.asset(
              "assets/images/mystical_eye.png",
              height: 180,
              width: 180,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          "Beware, beware. God sees all.",
          textAlign: TextAlign.center,
          style: GoogleFonts.medievalSharp(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ],
    );
  }
}
