// widgets/common/custom_button.dart
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return _buildOutlinedButton();
    } else {
      return _buildElevatedButton();
    }
  }

  Widget _buildElevatedButton() {
    return SizedBox(
      width: width,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? AppColors.textWhite,
          padding: padding ?? EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? AppColors.textWhite,
                  ),
                ),
              )
            : _buildButtonContent(),
      ),
    );
  }

  Widget _buildOutlinedButton() {
    return SizedBox(
      width: width,
      height: height ?? 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? backgroundColor ?? AppColors.primary,
          padding: padding ?? EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          side: BorderSide(
            color: backgroundColor ?? AppColors.primary,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? backgroundColor ?? AppColors.primary,
                  ),
                ),
              )
            : _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.button,
          ),
        ],
      );
    } else {
      return Text(
        text,
        style: AppTextStyles.button,
      );
    }
  }
}

// Specialized button variants
class PrimaryButton extends CustomButton {
  const PrimaryButton({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double? height,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          icon: icon,
          width: width,
          height: height,
        );
}

class SecondaryButton extends CustomButton {
  const SecondaryButton({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double? height,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          isOutlined: true,
          icon: icon,
          width: width,
          height: height,
        );
}

class DangerButton extends CustomButton {
  const DangerButton({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double? height,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          backgroundColor: AppColors.error,
          icon: icon,
          width: width,
          height: height,
        );
}

class SuccessButton extends CustomButton {
  const SuccessButton({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double? height,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          backgroundColor: AppColors.success,
          icon: icon,
          width: width,
          height: height,
        );
}

class WarningButton extends CustomButton {
  const WarningButton({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double? height,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          backgroundColor: AppColors.warning,
          icon: icon,
          width: width,
          height: height,
        );
}