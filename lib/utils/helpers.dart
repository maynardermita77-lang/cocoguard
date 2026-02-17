import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'colors.dart';

class Helpers {
  // Format date and time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  // Format date only
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  // Format time only
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  // Show snackbar
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        );
      },
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // Show confirmation dialog
  static Future<bool> showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Format confidence score as percentage
  static String formatConfidence(double confidence) {
    return '${(confidence * 100).toStringAsFixed(0)}%';
  }

  // Get pest emoji
  static String getPestEmoji(String pestType) {
    switch (pestType.toLowerCase()) {
      case 'rhinoceros beetle':
        return '🪲'; // beetle
      case 'apw adult':
        return '🐛'; // bug (adult weevil)
      case 'apw larvae':
        return '🐛'; // bug (larvae)
      case 'brontispa':
        return '🪳'; // cockroach/leaf beetle
      case 'brontispa pupa':
        return '🪳'; // pupa stage
      case 'slug caterpillar':
        return '🐛'; // caterpillar
      case 'white grub':
        return '🪱'; // worm/grub
      case 'out-of-scope pest instance':
        return '❓'; // question mark
      default:
        return '🔍'; // magnifying glass for unknown
    }
  }

  // Get severity color based on confidence
  static Color getSeverityColor(double confidence) {
    if (confidence >= 0.8) {
      return AppColors.error;
    } else if (confidence >= 0.5) {
      return AppColors.warning;
    } else {
      return AppColors.info;
    }
  }

  // Get severity label
  static String getSeverityLabel(double confidence) {
    if (confidence >= 0.8) {
      return 'High Risk';
    } else if (confidence >= 0.5) {
      return 'Medium Risk';
    } else {
      return 'Low Risk';
    }
  }

  // Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  // Get initials from name
  static String getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return '';
    if (nameParts.length == 1) return nameParts[0][0].toUpperCase();
    return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
  }
}
