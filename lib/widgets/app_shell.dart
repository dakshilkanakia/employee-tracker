import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

const _kSidebarWidth = 240.0;
const _kBreakpoint = 720.0;

class AppShell extends StatelessWidget {
  final int navIndex;
  final bool isManager;
  final Widget child;
  final String title;
  final List<Widget> actions;

  const AppShell({
    super.key,
    required this.navIndex,
    required this.isManager,
    required this.child,
    this.title = '',
    this.actions = const [],
  });

  List<_NavItem> get _navItems => isManager
      ? const [
          _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Tasks'),
          _NavItem(Icons.people_outlined, Icons.people, 'Employees'),
          _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Performance'),
        ]
      : const [
          _NavItem(Icons.assignment_outlined, Icons.assignment, 'My Tasks'),
          _NavItem(Icons.group_outlined, Icons.group, 'Team Tasks'),
          _NavItem(Icons.person_outlined, Icons.person, 'Profile'),
        ];

  void _onNavTap(BuildContext context, int index) {
    if (index == navIndex) return;
    if (isManager) {
      final routes = ['/manager', '/manager/employees', '/manager/performance'];
      context.go(routes[index]);
    } else {
      final routes = ['/employee', '/employee/all-tasks', '/employee/settings'];
      context.go(routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _kBreakpoint;
        if (isWide) {
          return _WideShell(
            navIndex: navIndex,
            navItems: _navItems,
            isManager: isManager,
            onNavTap: (i) => _onNavTap(context, i),
            child: child,
          );
        }
        return _NarrowShell(
          navIndex: navIndex,
          navItems: _navItems,
          isManager: isManager,
          title: title,
          actions: actions,
          onNavTap: (i) => _onNavTap(context, i),
          child: child,
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData iconActive;
  final String label;
  const _NavItem(this.icon, this.iconActive, this.label);
}

class _WideShell extends StatelessWidget {
  final int navIndex;
  final List<_NavItem> navItems;
  final bool isManager;
  final ValueChanged<int> onNavTap;
  final Widget child;

  const _WideShell({
    required this.navIndex,
    required this.navItems,
    required this.isManager,
    required this.onNavTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _Sidebar(
            navIndex: navIndex,
            navItems: navItems,
            isManager: isManager,
            onNavTap: onNavTap,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NarrowShell extends StatelessWidget {
  final int navIndex;
  final List<_NavItem> navItems;
  final bool isManager;
  final String title;
  final List<Widget> actions;
  final ValueChanged<int> onNavTap;
  final Widget child;

  const _NarrowShell({
    required this.navIndex,
    required this.navItems,
    required this.isManager,
    required this.title,
    required this.actions,
    required this.onNavTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.isNotEmpty
        ? title
        : navItems[navIndex].label;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(displayTitle),
        actions: [
          ...actions,
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => context.push(
              isManager ? '/manager/notifications' : '/employee/notifications',
            ),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: navIndex,
          onTap: onNavTap,
          items: navItems
              .map((item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    activeIcon: Icon(item.iconActive),
                    label: item.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int navIndex;
  final List<_NavItem> navItems;
  final bool isManager;
  final ValueChanged<int> onNavTap;

  const _Sidebar({
    required this.navIndex,
    required this.navItems,
    required this.isManager,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Container(
      width: _kSidebarWidth,
      color: AppColors.sidebarBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.task_alt,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'TaskFlow',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Nav items
            ...navItems.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final active = i == navIndex;
              return _SidebarItem(
                icon: active ? item.iconActive : item.icon,
                label: item.label,
                active: active,
                onTap: () => onNavTap(i),
              );
            }),
            const Spacer(),
            const Divider(color: Color(0xFF312E81), height: 1),
            // Notifications
            _SidebarItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              active: false,
              onTap: () => context.push(
                isManager ? '/manager/notifications' : '/employee/notifications',
              ),
            ),
            // Settings
            _SidebarItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              active: false,
              onTap: () => context.push(
                isManager ? '/manager/settings' : '/employee/settings',
              ),
            ),
            const Divider(color: Color(0xFF312E81), height: 1),
            // User info
            if (user != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isManager ? 'Manager' : 'Employee',
                            style: const TextStyle(
                              color: AppColors.sidebarText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout,
                          color: AppColors.sidebarText, size: 18),
                      tooltip: 'Sign out',
                      onPressed: () async {
                        await context.read<AuthProvider>().signOut();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.sidebarActive : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: active
                  ? AppColors.sidebarTextActive
                  : AppColors.sidebarText,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? AppColors.sidebarTextActive
                    : AppColors.sidebarText,
                fontSize: 14,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
