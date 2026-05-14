import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RewardFieldsInput extends StatelessWidget {
  const RewardFieldsInput({
    super.key,
    required this.rankLabel,
    required this.rankColor,
    required this.amountCtrl,
  });

  final String                rankLabel;
  final Color                 rankColor;
  final TextEditingController amountCtrl;

  Color get _labelColor {
    if (rankColor == const Color(0xFFFFD700)) return const Color(0xFFB8860B);
    if (rankColor == const Color(0xFFC0C0C0)) return Colors.blueGrey;
    return const Color(0xFF8B5E3C);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        rankColor.withValues(alpha: 0.07),
        border:       Border.all(color: rankColor.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rankLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize:   13,
              color:      _labelColor,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller:   amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText:   'Prize amount (MAD) *',
              hintText:    'e.g. 50',
              isDense:     true,
              border:      OutlineInputBorder(),
              prefixIcon:  Icon(Icons.attach_money_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
