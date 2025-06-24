import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AttendanceChart extends StatelessWidget {
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final String title;
  final double? height;
  final bool showPercentages;

  const AttendanceChart({
    Key? key,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.title,
    this.height,
    this.showPercentages = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = presentCount + absentCount + lateCount;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.h6,
            ),
            
            SizedBox(height: 16),
            
            if (total == 0)
              _buildEmptyState()
            else
              Column(
                children: [
                  // Donut chart
                  Container(
                    height: height ?? 150,
                    child: Row(
                      children: [
                        // Chart
                        Container(
                          width: height ?? 150,
                          height: height ?? 150,
                          child: CustomPaint(
                            painter: AttendanceDonutPainter(
                              presentCount: presentCount,
                              absentCount: absentCount,
                              lateCount: lateCount,
                              total: total,
                            ),
                          ),
                        ),
                        
                        SizedBox(width: 24),
                        
                        // Legend
                        Expanded(
                          child: _buildLegend(total),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Summary
                  _buildSummary(total),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: height ?? 150,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: AppColors.textHint,
            ),
            SizedBox(height: 8),
            Text(
              'Belum ada data kehadiran',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(int total) {
    final presentPercentage = total > 0 ? (presentCount / total * 100) : 0;
    final absentPercentage = total > 0 ? (absentCount / total * 100) : 0;
    final latePercentage = total > 0 ? (lateCount / total * 100) : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendItem(
          color: AppColors.presentColor,
          label: 'Hadir',
          count: presentCount,
          percentage: presentPercentage.toDouble(),
        ),
        
        SizedBox(height: 12),
        
        _buildLegendItem(
          color: AppColors.lateColor,
          label: 'Terlambat',
          count: lateCount,
          percentage: latePercentage.toDouble(),
        ),
        
        SizedBox(height: 12),
        
        _buildLegendItem(
          color: AppColors.absentColor,
          label: 'Tidak Hadir',
          count: absentCount,
          percentage: absentPercentage.toDouble(),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int count,
    required double percentage,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        
        SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium,
              ),
              if (showPercentages)
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        
        Text(
          '$count',
          style: AppTextStyles.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(int total) {
    final attendanceRate = total > 0 ? ((presentCount + lateCount) / total * 100) : 0;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '$total',
                style: AppTextStyles.h5.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total Sesi',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          
          Container(
            width: 1,
            height: 40,
            color: AppColors.border,
          ),
          
          Column(
            children: [
              Text(
                '${attendanceRate.toStringAsFixed(1)}%',
                style: AppTextStyles.h5.copyWith(
                  color: attendanceRate >= 80 ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Tingkat Kehadiran',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom painter for donut chart
class AttendanceDonutPainter extends CustomPainter {
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int total;

  AttendanceDonutPainter({
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width < size.height ? size.width / 2 : size.height / 2;
    final innerRadius = outerRadius * 0.6;
    
    double startAngle = -90 * (3.14159 / 180); // Start from top

    // Draw present section
    if (presentCount > 0) {
      final sweepAngle = (presentCount / total) * 2 * 3.14159;
      _drawSection(canvas, center, outerRadius, innerRadius, startAngle, sweepAngle, AppColors.presentColor);
      startAngle += sweepAngle;
    }

    // Draw late section
    if (lateCount > 0) {
      final sweepAngle = (lateCount / total) * 2 * 3.14159;
      _drawSection(canvas, center, outerRadius, innerRadius, startAngle, sweepAngle, AppColors.lateColor);
      startAngle += sweepAngle;
    }

    // Draw absent section
    if (absentCount > 0) {
      final sweepAngle = (absentCount / total) * 2 * 3.14159;
      _drawSection(canvas, center, outerRadius, innerRadius, startAngle, sweepAngle, AppColors.absentColor);
    }

    // Draw center circle
    final centerPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, innerRadius, centerPaint);

    // Draw center text
    final attendanceRate = ((presentCount + lateCount) / total * 100);
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${attendanceRate.toStringAsFixed(1)}%\n',
            style: AppTextStyles.h6.copyWith(
              color: attendanceRate >= 80 ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: 'Kehadiran',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawSection(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    double startAngle,
    double sweepAngle,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Outer arc
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      sweepAngle,
      false,
    );
    
    // Inner arc (reverse direction)
    path.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle + sweepAngle,
      -sweepAngle,
      false,
    );
    
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Draw border
    final borderPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Compact attendance chart for cards
class CompactAttendanceChart extends StatelessWidget {
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final double size;

  const CompactAttendanceChart({
    Key? key,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    this.size = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = presentCount + absentCount + lateCount;
    
    if (total == 0) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.border,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.help_outline,
          color: AppColors.textHint,
          size: size * 0.4,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CompactAttendanceDonutPainter(
          presentCount: presentCount,
          absentCount: absentCount,
          lateCount: lateCount,
          total: total,
        ),
      ),
    );
  }
}

// Compact donut painter
class CompactAttendanceDonutPainter extends CustomPainter {
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int total;

  CompactAttendanceDonutPainter({
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2 : size.height / 2;
    final strokeWidth = radius * 0.25;
    
    double startAngle = -90 * (3.14159 / 180);

    // Draw present section
    if (presentCount > 0) {
      final sweepAngle = (presentCount / total) * 2 * 3.14159;
      _drawCompactSection(canvas, center, radius, strokeWidth, startAngle, sweepAngle, AppColors.presentColor);
      startAngle += sweepAngle;
    }

    // Draw late section
    if (lateCount > 0) {
      final sweepAngle = (lateCount / total) * 2 * 3.14159;
      _drawCompactSection(canvas, center, radius, strokeWidth, startAngle, sweepAngle, AppColors.lateColor);
      startAngle += sweepAngle;
    }

    // Draw absent section
    if (absentCount > 0) {
      final sweepAngle = (absentCount / total) * 2 * 3.14159;
      _drawCompactSection(canvas, center, radius, strokeWidth, startAngle, sweepAngle, AppColors.absentColor);
    }

    // Draw center percentage
    final attendanceRate = ((presentCount + lateCount) / total * 100);
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${attendanceRate.toInt()}%',
        style: AppTextStyles.labelSmall.copyWith(
          color: attendanceRate >= 80 ? AppColors.success : AppColors.warning,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawCompactSection(
    Canvas canvas,
    Offset center,
    double radius,
    double strokeWidth,
    double startAngle,
    double sweepAngle,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Linear attendance progress
class AttendanceProgressBar extends StatelessWidget {
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final String? label;
  final double? height;

  const AttendanceProgressBar({
    Key? key,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    this.label,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = presentCount + absentCount + lateCount;
    
    if (total == 0) {
      return Container(
        height: height ?? 24,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Belum ada data',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ),
      );
    }

    final presentPercentage = presentCount / total;
    final latePercentage = lateCount / total;
    final absentPercentage = absentCount / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.bodyMedium,
          ),
          SizedBox(height: 8),
        ],
        
        Container(
          height: height ?? 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                if (presentPercentage > 0)
                  Expanded(
                    flex: (presentPercentage * 100).round(),
                    child: Container(
                      color: AppColors.presentColor,
                      child: Center(
                        child: presentPercentage > 0.1
                            ? Text(
                                '${(presentPercentage * 100).round()}%',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                
                if (latePercentage > 0)
                  Expanded(
                    flex: (latePercentage * 100).round(),
                    child: Container(
                      color: AppColors.lateColor,
                      child: Center(
                        child: latePercentage > 0.1
                            ? Text(
                                '${(latePercentage * 100).round()}%',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                
                if (absentPercentage > 0)
                  Expanded(
                    flex: (absentPercentage * 100).round(),
                    child: Container(
                      color: AppColors.absentColor,
                      child: Center(
                        child: absentPercentage > 0.1
                            ? Text(
                                '${(absentPercentage * 100).round()}%',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 8),
        
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMiniLegendItem(
              color: AppColors.presentColor,
              label: 'Hadir',
              count: presentCount,
            ),
            _buildMiniLegendItem(
              color: AppColors.lateColor,
              label: 'Terlambat',
              count: lateCount,
            ),
            _buildMiniLegendItem(
              color: AppColors.absentColor,
              label: 'Tidak Hadir',
              count: absentCount,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniLegendItem({
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          '$label ($count)',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}