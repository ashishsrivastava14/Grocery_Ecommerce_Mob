import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import 'widgets/admin_common.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  double _commissionRate = 10.0;
  double _deliveryFeeBase = 30.0;
  double _freeDeliveryThreshold = 500.0;
  double _minOrderAmount = 99.0;
  bool _maintenanceMode = false;
  bool _newRegistrations = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Platform Settings',
            subtitle: 'Configure platform-wide settings and preferences',
          ),
          const SizedBox(height: 24),

          // Commission Settings
          _buildSection(
            'Commission & Fees',
            Icons.percent_rounded,
            [
              _buildSliderSetting(
                'Platform Commission Rate',
                'Commission percentage charged on each order',
                _commissionRate,
                0,
                30,
                '%',
                (v) => setState(() => _commissionRate = v),
              ),
              const Divider(height: 32),
              _buildSliderSetting(
                'Base Delivery Fee',
                'Default delivery charge per order',
                _deliveryFeeBase,
                0,
                100,
                '₹',
                (v) => setState(() => _deliveryFeeBase = v),
              ),
              const Divider(height: 32),
              _buildSliderSetting(
                'Free Delivery Threshold',
                'Minimum order value for free delivery',
                _freeDeliveryThreshold,
                0,
                2000,
                '₹',
                (v) => setState(() => _freeDeliveryThreshold = v),
              ),
              const Divider(height: 32),
              _buildSliderSetting(
                'Minimum Order Amount',
                'Minimum value required to place an order',
                _minOrderAmount,
                0,
                500,
                '₹',
                (v) => setState(() => _minOrderAmount = v),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // System Settings
          _buildSection(
            'System',
            Icons.settings_rounded,
            [
              _buildToggleSetting(
                'Maintenance Mode',
                'When enabled, only admins can access the platform',
                _maintenanceMode,
                (v) => setState(() => _maintenanceMode = v),
                activeColor: AppColors.error,
              ),
              const Divider(height: 32),
              _buildToggleSetting(
                'New Vendor Registrations',
                'Allow new vendors to register on the platform',
                _newRegistrations,
                (v) => setState(() => _newRegistrations = v),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Notification Settings
          _buildSection(
            'Notifications',
            Icons.notifications_rounded,
            [
              _buildToggleSetting(
                'Email Notifications',
                'Send email notifications for orders and payouts',
                _emailNotifications,
                (v) => setState(() => _emailNotifications = v),
              ),
              const Divider(height: 32),
              _buildToggleSetting(
                'Push Notifications',
                'Send push notifications to mobile devices',
                _pushNotifications,
                (v) => setState(() => _pushNotifications = v),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Save button
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save Settings'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(
      String title, IconData icon, List<Widget> children) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSliderSetting(String title, String description, double value,
      double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                unit == '₹'
                    ? '₹${value.round()}'
                    : '${value.round()}$unit',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withAlpha(30),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withAlpha(30),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / (unit == '%' ? 0.5 : 10)).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSetting(String title, String description, bool value,
      ValueChanged<bool> onChanged,
      {Color? activeColor}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text(description,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor ?? AppColors.primary,
        ),
      ],
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Settings saved successfully'),
      backgroundColor: AppColors.success,
    ));
  }
}
