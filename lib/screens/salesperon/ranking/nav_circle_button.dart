import 'package:flutter/material.dart';

// ── Circular nav button ──────────────────────────────────────────────────────

class NavCircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const NavCircleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Container(
            width:  64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color:       color.withValues(alpha: 0.45),
                  blurRadius:  10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),

          const SizedBox(height: 6),

          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),

        ],
      ),
    );
  }
}
