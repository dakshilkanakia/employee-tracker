import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_shell.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orgId = auth.currentUser!.orgId;

    return AppShell(
      navIndex: 1,
      isManager: true,
      title: 'Employees',
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                TabBar(
                  controller: _tab,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: const [
                    Tab(text: 'People'),
                    Tab(text: 'Teams'),
                  ],
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _PeopleTab(orgId: orgId),
                _TeamsTab(orgId: orgId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── People tab ────────────────────────────────────────────────────────────────

class _PeopleTab extends StatelessWidget {
  final String orgId;
  const _PeopleTab({required this.orgId});

  @override
  Widget build(BuildContext context) {
    final userProv = context.read<UserProvider>();
    return Stack(
      children: [
        StreamBuilder<List<UserModel>>(
          stream: userProv.orgEmployeesStream(orgId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final employees = snap.data ?? [];
            if (employees.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppColors.primarySurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_outline,
                            size: 36, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No employees yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Create an account or share your invite code.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.push('/manager/create-employee'),
                        icon: const Icon(Icons.person_add_outlined, size: 16),
                        label: const Text('Create Employee Account'),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () => context.push('/manager/settings'),
                        icon: const Icon(Icons.vpn_key_outlined, size: 16),
                        label: const Text('View Invite Code'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: employees.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _EmployeeCard(emp: employees[i]),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'create_emp_fab',
            onPressed: () => context.push('/manager/create-employee'),
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('Create Account'),
          ),
        ),
      ],
    );
  }
}

// ── Teams tab ─────────────────────────────────────────────────────────────────

class _TeamsTab extends StatelessWidget {
  final String orgId;
  const _TeamsTab({required this.orgId});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.read<TeamProvider>();
    final userProv = context.read<UserProvider>();

    return Stack(
      children: [
        StreamBuilder<List<TeamModel>>(
          stream: teamProv.teamsStream(orgId),
          builder: (context, teamSnap) {
            if (teamSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final teams = teamSnap.data ?? [];

            return StreamBuilder<List<UserModel>>(
              stream: userProv.orgEmployeesStream(orgId),
              builder: (context, empSnap) {
                final employees = empSnap.data ?? [];

                if (teams.isEmpty) {
                  return _TeamsEmptyState(
                    onCreate: () =>
                        _showCreateTeamSheet(context, orgId),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: teams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _TeamCard(
                    team: teams[i],
                    allEmployees: employees,
                    orgId: orgId,
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            heroTag: 'create_team_fab',
            onPressed: () => _showCreateTeamSheet(context, orgId),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  void _showCreateTeamSheet(BuildContext context, String orgId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateTeamSheet(orgId: orgId),
    );
  }
}

// ── Team card ─────────────────────────────────────────────────────────────────

class _TeamCard extends StatelessWidget {
  final TeamModel team;
  final List<UserModel> allEmployees;
  final String orgId;

  const _TeamCard({
    required this.team,
    required this.allEmployees,
    required this.orgId,
  });

  List<UserModel> get _members =>
      allEmployees.where((e) => team.memberUids.contains(e.uid)).toList();

  @override
  Widget build(BuildContext context) {
    final members = _members;
    final shown = members.take(5).toList();
    final extra = members.length - shown.length;

    return GestureDetector(
      onTap: () => _openManage(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: team.displayColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: team.displayColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.group_outlined,
                            size: 18,
                            color: team.displayColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                team.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                members.isEmpty
                                    ? 'No members yet'
                                    : '${members.length} member${members.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // stacked avatars
                        if (shown.isNotEmpty) ...[
                          SizedBox(
                            height: 28,
                            width: (shown.length * 20 + 8).toDouble(),
                            child: Stack(
                              children: [
                                for (int i = 0; i < shown.length; i++)
                                  Positioned(
                                    left: (i * 20).toDouble(),
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.white,
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: team.displayColor
                                            .withValues(alpha: 0.15),
                                        child: Text(
                                          shown[i].name.isNotEmpty
                                              ? shown[i].name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: team.displayColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (extra > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '+$extra',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                        ],
                        const Icon(Icons.chevron_right,
                            size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openManage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManageTeamSheet(
        team: team,
        allEmployees: allEmployees,
        orgId: orgId,
      ),
    );
  }
}

// ── Employee card (People tab) ────────────────────────────────────────────────

class _EmployeeCard extends StatelessWidget {
  final UserModel emp;
  const _EmployeeCard({required this.emp});

  @override
  Widget build(BuildContext context) {
    final initial = emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primarySurface,
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(emp.name),
        subtitle: Text(emp.email),
      ),
    );
  }
}

// ── Create team sheet ─────────────────────────────────────────────────────────

class _CreateTeamSheet extends StatefulWidget {
  final String orgId;
  const _CreateTeamSheet({required this.orgId});

  @override
  State<_CreateTeamSheet> createState() => _CreateTeamSheetState();
}

class _CreateTeamSheetState extends State<_CreateTeamSheet> {
  final _nameCtrl = TextEditingController();
  Color _color = AppColors.taskColors[0];
  bool _creating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _colorHex =>
      '#${_color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _creating = true);
    await context.read<TeamProvider>().createTeam(
          orgId: widget.orgId,
          name: _nameCtrl.text.trim(),
          color: _colorHex,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'New Team',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Team name  (e.g. Field, On-Site, Warehouse)',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: Colors.transparent,
                ),
                onSubmitted: (_) => _create(),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'TEAM COLOR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppColors.taskColors.map((c) {
                final sel = _color.toARGB32() == c.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: c.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                    child: sel
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _creating ? null : _create,
                child: _creating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Create Team'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Manage team sheet ─────────────────────────────────────────────────────────

class _ManageTeamSheet extends StatefulWidget {
  final TeamModel team;
  final List<UserModel> allEmployees;
  final String orgId;

  const _ManageTeamSheet({
    required this.team,
    required this.allEmployees,
    required this.orgId,
  });

  @override
  State<_ManageTeamSheet> createState() => _ManageTeamSheetState();
}

class _ManageTeamSheetState extends State<_ManageTeamSheet> {
  late final TextEditingController _nameCtrl;
  late List<String> _selectedUids;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.team.name);
    _selectedUids = List.from(widget.team.memberUids);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prov = context.read<TeamProvider>();
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty && name != widget.team.name) {
      await prov.renameTeam(widget.orgId, widget.team.id, name);
    }
    await prov.setMembers(widget.orgId, widget.team.id, _selectedUids);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text(
          'Delete "${widget.team.name}"?\nThis won\'t affect existing tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context
          .read<TeamProvider>()
          .deleteTeam(widget.orgId, widget.team.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.team.displayColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _delete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    tooltip: 'Delete team',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Members label
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  const Text(
                    'MEMBERS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_selectedUids.length} of ${widget.allEmployees.length} selected',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.allEmployees.isEmpty
                  ? const Center(
                      child: Text(
                        'No employees in your org yet.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: widget.allEmployees.length,
                      itemBuilder: (_, i) {
                        final emp = widget.allEmployees[i];
                        final isMember = _selectedUids.contains(emp.uid);
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          tileColor: isMember
                              ? widget.team.displayColor
                                  .withValues(alpha: 0.06)
                              : Colors.transparent,
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isMember
                                ? widget.team.displayColor
                                    .withValues(alpha: 0.15)
                                : AppColors.primarySurface,
                            child: Text(
                              emp.name.isNotEmpty
                                  ? emp.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isMember
                                    ? widget.team.displayColor
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            emp.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            emp.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isMember
                                  ? widget.team.displayColor
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isMember
                                    ? widget.team.displayColor
                                    : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: isMember
                                ? const Icon(Icons.check,
                                    size: 12, color: Colors.white)
                                : null,
                          ),
                          onTap: () => setState(() {
                            if (isMember) {
                              _selectedUids.remove(emp.uid);
                            } else {
                              _selectedUids.add(emp.uid);
                            }
                          }),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20 + MediaQuery.of(context).padding.bottom,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Teams empty state ─────────────────────────────────────────────────────────

class _TeamsEmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _TeamsEmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group_work_outlined,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No teams yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create teams to quickly assign tasks to whole groups at once.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create First Team'),
            ),
          ],
        ),
      ),
    );
  }
}
