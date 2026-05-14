import 'package:flutter/material.dart';
import 'package:lafargeholcim_sales_game/main.dart';
import 'package:lafargeholcim_sales_game/utils/app_emojis.dart';

class MoneyBadge extends StatelessWidget {
  const MoneyBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        kPrimaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${AppEmojis.moneybag} Cash',
        style: TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w600,
          color:      kPrimaryColor,
        ),
      ),
    );
  }
}
