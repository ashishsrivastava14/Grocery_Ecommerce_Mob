import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class AdminStatusBadge extends StatelessWidget {
  final String status;
  final Map<String, _BadgeStyle>? customStyles;

  const AdminStatusBadge({super.key, required this.status, this.customStyles});

  @override
  Widget build(BuildContext context) {
    final style = _getStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.border),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _BadgeStyle _getStyle(String status) {
    if (customStyles != null && customStyles!.containsKey(status)) {
      return customStyles![status]!;
    }
    final s = status.toLowerCase();
    switch (s) {
      case 'approved':
      case 'active':
      case 'delivered':
      case 'completed':
      case 'paid':
      case 'success':
        return _BadgeStyle(
          label: _formatLabel(status),
          bg: AppColors.success.withAlpha(25),
          text: AppColors.success,
          border: AppColors.success.withAlpha(50),
        );
      case 'pending':
      case 'under_review':
      case 'processing':
        return _BadgeStyle(
          label: _formatLabel(status),
          bg: AppColors.warning.withAlpha(25),
          text: const Color(0xFFB8860B),
          border: AppColors.warning.withAlpha(50),
        );
      case 'rejected':
      case 'suspended':
      case 'cancelled':
      case 'failed':
      case 'refunded':
        return _BadgeStyle(
          label: _formatLabel(status),
          bg: AppColors.error.withAlpha(25),
          text: AppColors.error,
          border: AppColors.error.withAlpha(50),
        );
      case 'confirmed':
      case 'preparing':
      case 'ready_for_pickup':
      case 'out_for_delivery':
        return _BadgeStyle(
          label: _formatLabel(status),
          bg: AppColors.info.withAlpha(25),
          text: AppColors.info,
          border: AppColors.info.withAlpha(50),
        );
      case 'draft':
      case 'out_of_stock':
      case 'discontinued':
      case 'inactive':
        return _BadgeStyle(
          label: _formatLabel(status),
          bg: Colors.grey.withAlpha(25),
          text: Colors.grey.shade700,
          border: Colors.grey.withAlpha(50),
        );
      default:
        return _BadgeStyle(
          label: _formatLabel(status),
          bg: AppColors.info.withAlpha(25),
          text: AppColors.info,
          border: AppColors.info.withAlpha(50),
        );
    }
  }

  String _formatLabel(String s) =>
      s.replaceAll('_', ' ').split(' ').map((w) =>
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
}

class _BadgeStyle {
  final String label;
  final Color bg;
  final Color text;
  final Color border;
  const _BadgeStyle({
    required this.label,
    required this.bg,
    required this.text,
    required this.border,
  });
}
