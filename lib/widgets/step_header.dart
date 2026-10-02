// پرستار من — تکه ۹: نوار پیشرفت «گام X از ۵» — مطابق وایرفریم‌های U2-U6

import 'package:flutter/material.dart';
import '../theme.dart';

class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.step});
  final int step; // 1..5

  static const _labels = ['خدمت', 'آدرس', 'بیمار', 'زمان', 'تایید'];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: List.generate(5, (i) {
        final on = i < step;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i == 4 ? 0 : 4),
            decoration: BoxDecoration(
              color: on ? AppColors.teal : AppColors.lineLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      })),
      const SizedBox(height: 8),
      Text('گام $step از ۵ — ${_labels[step - 1]}',
          style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}