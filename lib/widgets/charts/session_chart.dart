import 'package:flutter/material.dart';
import '../../models/statistics_model.dart';
import '../../core/theme.dart';

class SessionChart extends StatelessWidget {
  final List<ChartData> data;
  final Color color;
  final String? title;

  const SessionChart({
    Key? key,
    required this.data,
    required this.color,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data untuk ditampilkan',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTextStyles.h6,
            ),
            SizedBox(height: 16),
          ],
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: data.map((item) {
                final height = maxValue > 0 
                    ? (item.value / maxValue) * 120 
                    : 0.0;
                
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Value label
                        if (item.value > 0)
                          Container(
                            margin: EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${item.value}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          SizedBox(height: 16),
                        
                        // Bar
                        AnimatedContainer(
                          duration: Duration(milliseconds: 800),
                          width: double.infinity,
                          height: height.clamp(4.0, 120.0),
                          decoration: BoxDecoration(
                            color: item.value > 0 ? color : AppColors.border,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 8),
                        
                        // Label
                        Text(
                          item.label,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}