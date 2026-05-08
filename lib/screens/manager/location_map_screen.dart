import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_shell.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({super.key});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  final _mapController = MapController();
  UserModel? _focusedEmployee;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _focusOn(UserModel emp) {
    if (!emp.hasLocation) return;
    setState(() => _focusedEmployee = emp);
    _mapController.move(
      LatLng(emp.lastLat!, emp.lastLng!),
      15.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProv = context.read<UserProvider>();
    final orgId = auth.currentUser!.orgId;

    return AppShell(
      navIndex: 3,
      isManager: true,
      title: 'Live Map',
      child: StreamBuilder<List<UserModel>>(
        stream: userProv.orgEmployeesStream(orgId),
        builder: (context, snap) {
          final employees = snap.data ?? [];
          final located =
              employees.where((e) => e.hasLocation).toList();

          return Column(
            children: [
              // Employee list bar
              if (employees.isNotEmpty)
                Container(
                  color: AppColors.surface,
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    itemCount: employees.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final emp = employees[i];
                      final active = _focusedEmployee?.uid == emp.uid;
                      return GestureDetector(
                        onTap: () => _focusOn(emp),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : emp.hasLocation
                                    ? AppColors.primarySurface
                                    : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                emp.hasLocation
                                    ? Icons.location_on
                                    : Icons.location_off_outlined,
                                size: 13,
                                color: active
                                    ? Colors.white
                                    : emp.hasLocation
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                emp.name.split(' ').first,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: active
                                      ? Colors.white
                                      : emp.hasLocation
                                          ? AppColors.textPrimary
                                          : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const Divider(height: 1),
              // Map
              Expanded(
                child: located.isEmpty
                    ? _NoLocationState(
                        hasEmployees: employees.isNotEmpty)
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _initialCenter(located),
                          initialZoom: 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.internal.employee_tracker',
                          ),
                          MarkerLayer(
                            markers: located.map((emp) {
                              final focused =
                                  _focusedEmployee?.uid == emp.uid;
                              return Marker(
                                point: LatLng(
                                    emp.lastLat!, emp.lastLng!),
                                width: focused ? 160 : 120,
                                height: focused ? 64 : 52,
                                alignment: Alignment.topCenter,
                                child: _EmployeeMarker(
                                  emp: emp,
                                  focused: focused,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  LatLng _initialCenter(List<UserModel> located) {
    if (located.length == 1) {
      return LatLng(located[0].lastLat!, located[0].lastLng!);
    }
    final avgLat =
        located.map((e) => e.lastLat!).reduce((a, b) => a + b) /
            located.length;
    final avgLng =
        located.map((e) => e.lastLng!).reduce((a, b) => a + b) /
            located.length;
    return LatLng(avgLat, avgLng);
  }
}

class _EmployeeMarker extends StatelessWidget {
  final UserModel emp;
  final bool focused;

  const _EmployeeMarker({required this.emp, required this.focused});

  @override
  Widget build(BuildContext context) {
    final initial =
        emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?';
    final timeFmt = DateFormat('h:mm a');
    final timeStr = emp.locationUpdatedAt != null
        ? timeFmt.format(emp.locationUpdatedAt!.toLocal())
        : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: focused ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: focused
                  ? AppColors.primaryDark
                  : AppColors.border,
              width: focused ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: focused ? 0.2 : 0.1),
                blurRadius: focused ? 10 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: focused
                    ? Colors.white.withValues(alpha: 0.3)
                    : AppColors.primarySurface,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color:
                        focused ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp.name.split(' ').first,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: focused
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (timeStr.isNotEmpty)
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 9,
                        color: focused
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Pin tail
        CustomPaint(
          size: const Size(12, 6),
          painter: _PinTail(
            color: focused ? AppColors.primary : AppColors.surface,
          ),
        ),
      ],
    );
  }
}

class _PinTail extends CustomPainter {
  final Color color;
  const _PinTail({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTail old) => old.color != color;
}

class _NoLocationState extends StatelessWidget {
  final bool hasEmployees;
  const _NoLocationState({required this.hasEmployees});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_off_outlined,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            hasEmployees
                ? 'No location data yet'
                : 'No employees yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasEmployees
                ? 'Location updates when employees open the app.'
                : 'Add employees with the invite code.',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
