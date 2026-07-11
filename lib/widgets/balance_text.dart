import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Shows a balance amount: Red if customer owes money (>0), Green if 0.
class BalanceText extends StatelessWidget {
  final int balance;
  final double fontSize;
  final FontWeight fontWeight;

  const BalanceText({
    super.key,
    required this.balance,
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,
  });

  @override
  Widget build(BuildContext context) {
    final isOwed = balance > 0;
    return Text(
      isOwed ? formatRs(balance) : formatRs(0),
      style: TextStyle(
        color: isOwed ? AppColors.danger : AppColors.safe,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}
