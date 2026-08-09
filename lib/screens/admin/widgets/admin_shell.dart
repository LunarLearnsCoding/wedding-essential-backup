import 'package:flutter/material.dart';

import '../../../core/constants/admin_app_colors.dart';

/// Groups the data and behavior required by the admin panel page component.
class AdminPanelPage {
  const AdminPanelPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
}

/// Renders the reusable admin shell UI component.
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.pages,
    required this.selectedIndex,
    required this.onSelected,
    required this.onLogout,
  });

  final List<AdminPanelPage> pages;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final page = pages[selectedIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 980;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AdminAppColors.background,
            body: Row(
              children: [
                _Sidebar(
                  pages: pages,
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                  onLogout: onLogout,
                ),
                Expanded(child: _PageFrame(page: page)),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AdminAppColors.background,
          appBar: AppBar(
            title: Text(page.title),
            backgroundColor: AdminAppColors.surface,
            foregroundColor: AdminAppColors.textPrimary,
            elevation: 0,
          ),
          drawer: Drawer(
            child: SafeArea(
              child: _MobileDrawer(
                pages: pages,
                selectedIndex: selectedIndex,
                onSelected: (index) {
                  Navigator.pop(context);
                  onSelected(index);
                },
                onLogout: () {
                  Navigator.pop(context);
                  onLogout();
                },
              ),
            ),
          ),
          body: _PageFrame(page: page, showHeader: false),
        );
      },
    );
  }
}

/// Renders the reusable page frame UI component.
class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.page, this.showHeader = true});

  final AdminPanelPage page;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          page.title,
                          style: const TextStyle(
                            color: AdminAppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          page.subtitle,
                          style: const TextStyle(
                            color: AdminAppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AdminAppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AdminAppColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Admin',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                showHeader ? 28 : 16,
                showHeader ? 12 : 16,
                showHeader ? 28 : 16,
                20,
              ),
              child: page.child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the reusable sidebar UI component.
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.pages,
    required this.selectedIndex,
    required this.onSelected,
    required this.onLogout,
  });

  final List<AdminPanelPage> pages;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: AdminAppColors.surface,
        border: Border(right: BorderSide(color: AdminAppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AdminAppColors.heroGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.favorite, color: AdminAppColors.secondary),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wedding Essentials',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Admin Panel',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'MANAGEMENT',
            style: TextStyle(
              color: AdminAppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: pages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final page = pages[index];
                final selected = index == selectedIndex;
                return _NavTile(
                  title: page.title,
                  icon: page.icon,
                  selected: selected,
                  onTap: () => onSelected(index),
                );
              },
            ),
          ),
          const Divider(height: 18),
          _NavTile(
            title: 'Log out',
            icon: Icons.logout_rounded,
            selected: false,
            color: AdminAppColors.danger,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

/// Renders the reusable mobile drawer UI component.
class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({
    required this.pages,
    required this.selectedIndex,
    required this.onSelected,
    required this.onLogout,
  });

  final List<AdminPanelPage> pages;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: pages.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(8, 10, 8, 20),
            child: Text(
              'Wedding Essentials Admin',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          );
        }
        if (index == pages.length + 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _NavTile(
              title: 'Log out',
              icon: Icons.logout_rounded,
              selected: false,
              color: AdminAppColors.danger,
              onTap: onLogout,
            ),
          );
        }
        final pageIndex = index - 1;
        final page = pages[pageIndex];
        return _NavTile(
          title: page.title,
          icon: page.icon,
          selected: pageIndex == selectedIndex,
          onTap: () => onSelected(pageIndex),
        );
      },
    );
  }
}

/// Renders the reusable nav tile UI component.
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AdminAppColors.primary.withAlpha(22)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    color ??
                    (selected
                        ? AdminAppColors.primary
                        : AdminAppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color:
                        color ??
                        (selected
                            ? AdminAppColors.primary
                            : AdminAppColors.textPrimary),
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
