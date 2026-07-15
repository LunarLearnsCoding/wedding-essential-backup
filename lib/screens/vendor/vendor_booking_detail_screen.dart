import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class VendorBookingDetailScreen extends StatefulWidget {
  const VendorBookingDetailScreen({super.key});

  @override
  State<VendorBookingDetailScreen> createState() =>
      _VendorBookingDetailScreenState();
}

class _VendorBookingDetailScreenState extends State<VendorBookingDetailScreen> {
  String _status = 'Pending';

  void _changeStatus(String status) {
    setState(() {
      _status = status;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Booking marked as $status')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _BookingDetailHeader(status: _status),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BookingInfoCard(),

                  const SizedBox(height: 24),

                  const _SectionHeader(title: 'Update Status'),

                  const SizedBox(height: 14),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatusButton(
                        label: 'Pending',
                        icon: Icons.schedule_outlined,
                        color: Colors.orange,
                        isSelected: _status == 'Pending',
                        onTap: () {
                          _changeStatus('Pending');
                        },
                      ),
                      _StatusButton(
                        label: 'Confirmed',
                        icon: Icons.check_circle_outline,
                        color: AppColors.primary,
                        isSelected: _status == 'Confirmed',
                        onTap: () {
                          _changeStatus('Confirmed');
                        },
                      ),
                      _StatusButton(
                        label: 'Completed',
                        icon: Icons.done_all_outlined,
                        color: Colors.green,
                        isSelected: _status == 'Completed',
                        onTap: () {
                          _changeStatus('Completed');
                        },
                      ),
                      _StatusButton(
                        label: 'Cancelled',
                        icon: Icons.cancel_outlined,
                        color: Colors.red,
                        isSelected: _status == 'Cancelled',
                        onTap: () {
                          _changeStatus('Cancelled');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const _SectionHeader(title: 'Suggested Next Steps'),

                  const SizedBox(height: 14),

                  const _NextStepsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingDetailHeader extends StatelessWidget {
  final String status;

  const _BookingDetailHeader({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 52, 22, 22),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking ID: BK001',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Booking Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          _StatusBadge(status: status),
        ],
      ),
    );
  }
}

class _BookingInfoCard extends StatelessWidget {
  const _BookingInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 27,
                backgroundColor: AppColors.selectedSurface,
                child: Text(
                  'A',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aarati Sharma',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Booked on 02 July 2026',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          const _DetailRow(
            icon: Icons.business_center_outlined,
            label: 'Service',
            value: 'Royal Photography',
          ),

          const _DetailRow(
            icon: Icons.card_giftcard_outlined,
            label: 'Package',
            value: 'Premium Package',
          ),

          const _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Event Date',
            value: '15 Jan 2026',
          ),

          const _DetailRow(
            icon: Icons.payments_outlined,
            label: 'Amount',
            value: 'Rs. 50,000',
          ),

          const SizedBox(height: 10),

          const Text(
            'Notes',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Customer requested full wedding day coverage with couple photoshoot and family portraits.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppColors.selectedSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 21,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.14) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          _TodoRow(text: 'Confirm final guest count and event timing.'),
          _TodoRow(text: 'Share vendor checklist with the customer.'),
          _TodoRow(text: 'Prepare quotation or payment confirmation.'),
        ],
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  final String text;

  const _TodoRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (status == 'Pending') {
      backgroundColor = Colors.orange.withValues(alpha: 0.20);
      textColor = Colors.white;
    } else if (status == 'Confirmed') {
      backgroundColor = Colors.white.withValues(alpha: 0.18);
      textColor = Colors.white;
    } else if (status == 'Completed') {
      backgroundColor = Colors.green.withValues(alpha: 0.20);
      textColor = Colors.white;
    } else {
      backgroundColor = Colors.red.withValues(alpha: 0.20);
      textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
