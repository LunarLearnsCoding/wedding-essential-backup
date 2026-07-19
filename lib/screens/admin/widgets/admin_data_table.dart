import 'package:flutter/material.dart';

import '../../../core/constants/admin_app_colors.dart';

class AdminDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double minWidth;

  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 980,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminAppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AdminAppColors.border),
        boxShadow: [AdminAppColors.cardShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth > minWidth
                      ? constraints.maxWidth
                      : minWidth,
                ),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: const WidgetStatePropertyAll(
                      AdminAppColors.surfaceSoft,
                    ),
                    headingTextStyle: const TextStyle(
                      color: AdminAppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                    dataTextStyle: const TextStyle(
                      color: AdminAppColors.textPrimary,
                      fontSize: 13,
                    ),
                    dividerThickness: 1,
                    horizontalMargin: 18,
                    columnSpacing: 24,
                    columns: columns,
                    rows: rows,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AdminTableActions extends StatelessWidget {
  final List<Widget> children;

  const AdminTableActions({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          children[index],
        ],
      ],
    );
  }
}

class AdminTableAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const AdminTableAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: color ?? AdminAppColors.primary,
      style: IconButton.styleFrom(
        backgroundColor: (color ?? AdminAppColors.primary).withAlpha(18),
        side: BorderSide(
          color: (color ?? AdminAppColors.primary).withAlpha(45),
        ),
      ),
      icon: Icon(icon, size: 19),
    );
  }
}
