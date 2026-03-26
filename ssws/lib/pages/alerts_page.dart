import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/app_drawer.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class AlertItem {
  final String id;
  final String type; // 'critical' | 'warning' | 'resolved'
  final String title;
  final String message;
  final String zone;
  final DateTime timestamp;

  const AlertItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.zone,
    required this.timestamp,
  });

  factory AlertItem.fromMap(String id, Map<dynamic, dynamic> m) {
    return AlertItem(
      id: id,
      type: m['type'] as String? ?? 'warning',
      title: m['title'] as String? ?? 'Alert',
      message: m['message'] as String? ?? '',
      zone: m['zone'] as String? ?? 'Unknown',
      timestamp: m['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch((m['timestamp'] as int))
          : DateTime.now(),
    );
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _auth = FirebaseAuth.instance;
  late DatabaseReference _alertsRef;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final uid = _auth.currentUser?.uid ?? 'guest';
    _alertsRef = FirebaseDatabase.instance.ref('alerts/$uid/items');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _resolveAlert(String id) async {
    await _alertsRef.child(id).update({'type': 'resolved'});
  }

  Future<void> _deleteAlert(String id) async {
    await _alertsRef.child(id).remove();
  }

  Future<void> _dismissAll(List<AlertItem> alerts) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Resolve all?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Mark all active alerts as resolved?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Resolve all'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      for (final a in alerts) {
        if (a.type != 'resolved') await _resolveAlert(a.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F5),
      drawer: const AppDrawer(selectedPage: 'alerts'),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Alerts',
          style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF16A34A),
          indicatorWeight: 2.5,
          labelColor: const Color(0xFF16A34A),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Critical'),
            Tab(text: 'Warnings'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _alertsRef.onValue,
        builder: (context, snapshot) {
          List<AlertItem> all = [];

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final raw = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
            all = raw.entries
                .map((e) => AlertItem.fromMap(e.key as String, Map<dynamic, dynamic>.from(e.value as Map)))
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          }

          final critical = all.where((a) => a.type == 'critical').toList();
          final warnings = all.where((a) => a.type == 'warning').toList();
          final resolved = all.where((a) => a.type == 'resolved').toList();
          final active = [...critical, ...warnings];

          return Column(
            children: [
              // Summary strip
              _SummaryStrip(
                critical: critical.length,
                warnings: warnings.length,
                resolved: resolved.length,
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── All ──
                    _AlertListView(
                      alerts: all,
                      history: all.take(3).toList(),
                      showHistory: true,
                      onResolve: _resolveAlert,
                      onDelete: _deleteAlert,
                      onDismissAll: active.isNotEmpty ? () => _dismissAll(active) : null,
                    ),
                    // ── Critical ──
                    _AlertListView(
                      alerts: critical,
                      onResolve: _resolveAlert,
                      onDelete: _deleteAlert,
                    ),
                    // ── Warnings ──
                    _AlertListView(
                      alerts: warnings,
                      onResolve: _resolveAlert,
                      onDelete: _deleteAlert,
                    ),
                    // ── Resolved ──
                    _AlertListView(
                      alerts: resolved,
                      onDelete: _deleteAlert,
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
}

// ── Summary strip ─────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final int critical;
  final int warnings;
  final int resolved;

  const _SummaryStrip({
    required this.critical,
    required this.warnings,
    required this.resolved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F8F8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(child: _SummaryChip(label: 'Critical', count: critical, color: const Color(0xFFEF4444), bg: const Color(0xFFFEE2E2))),
          const SizedBox(width: 10),
          Expanded(child: _SummaryChip(label: 'Warnings', count: warnings, color: const Color(0xFFF59E0B), bg: const Color(0xFFFEF9C3))),
          const SizedBox(width: 10),
          Expanded(child: _SummaryChip(label: 'Resolved', count: resolved, color: const Color(0xFF16A34A), bg: const Color(0xFFDCFCE7))),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bg;

  const _SummaryChip({required this.label, required this.count, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ── Alert list view ───────────────────────────────────────────────────────────

class _AlertListView extends StatelessWidget {
  final List<AlertItem> alerts;
  final List<AlertItem> history;
  final bool showHistory;
  final Future<void> Function(String)? onResolve;
  final Future<void> Function(String) onDelete;
  final VoidCallback? onDismissAll;

  const _AlertListView({
    required this.alerts,
    this.history = const [],
    this.showHistory = false,
    this.onResolve,
    required this.onDelete,
    this.onDismissAll,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty && !showHistory) {
      return const _EmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      children: [
        // Dismiss all button
        if (onDismissAll != null) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onDismissAll,
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: const Text('Resolve all'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],

        // Active alerts (non-resolved)
        if (alerts.where((a) => a.type != 'resolved').isNotEmpty) ...[
          _sectionLabel('Active Alerts'),
          const SizedBox(height: 8),
          ...alerts
              .where((a) => a.type != 'resolved')
              .map((a) => _AlertCard(alert: a, onResolve: onResolve, onDelete: onDelete)),
          const SizedBox(height: 16),
        ],

        // Resolved
        if (alerts.where((a) => a.type == 'resolved').isNotEmpty) ...[
          _sectionLabel('Resolved'),
          const SizedBox(height: 8),
          ...alerts
              .where((a) => a.type == 'resolved')
              .map((a) => _AlertCard(alert: a, onDelete: onDelete)),
          const SizedBox(height: 16),
        ],

        // History (last 3) — only on the All tab
        if (showHistory && history.isNotEmpty) ...[
          _sectionLabel('Recent History'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                for (int i = 0; i < history.take(3).length; i++) ...[
                  _HistoryRow(alert: history[i]),
                  if (i < history.take(3).length - 1)
                    const Divider(height: 1, indent: 60, endIndent: 16, color: Color(0xFFF3F4F6)),
                ],
              ],
            ),
          ),
        ],

        if (alerts.isEmpty && showHistory && history.isEmpty)
          const _EmptyState(),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.8),
      );
}

// ── Alert card ────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final AlertItem alert;
  final Future<void> Function(String)? onResolve;
  final Future<void> Function(String) onDelete;

  const _AlertCard({required this.alert, this.onResolve, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cfg = _alertConfig(alert.type);

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        await onDelete(alert.id);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cfg.border, width: 1),
          boxShadow: [BoxShadow(color: cfg.border.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: cfg.iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(cfg.icon, color: cfg.iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          ),
                        ),
                        _TypeBadge(type: alert.type),
                      ],
                    ),
                    if (alert.message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        alert.message,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text(alert.zone, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time_rounded, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text(_timeAgo(alert.timestamp), style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                      ],
                    ),
                    if (onResolve != null && alert.type != 'resolved') ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => onResolve!(alert.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF16A34A),
                            side: const BorderSide(color: Color(0xFF86EFAC)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('Mark as resolved', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── History row ───────────────────────────────────────────────────────────────

class _HistoryRow extends StatelessWidget {
  final AlertItem alert;

  const _HistoryRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    final cfg = _alertConfig(alert.type);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: cfg.iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(cfg.icon, color: cfg.iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                Text(
                  '${alert.zone} · ${_timeAgo(alert.timestamp)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          _TypeBadge(type: alert.type, small: true),
        ],
      ),
    );
  }
}

// ── Type badge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String type;
  final bool small;

  const _TypeBadge({required this.type, this.small = false});

  @override
  Widget build(BuildContext context) {
    final cfg = _alertConfig(type);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 2 : 3),
      decoration: BoxDecoration(color: cfg.iconBg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        type[0].toUpperCase() + type.substring(1),
        style: TextStyle(fontSize: small ? 10 : 11, fontWeight: FontWeight.w700, color: cfg.iconColor),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 36),
            ),
            const SizedBox(height: 16),
            const Text('All clear!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 6),
            Text('No alerts in this category.', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}

// ── Config helper ─────────────────────────────────────────────────────────────

({Color iconBg, Color iconColor, Color border, IconData icon}) _alertConfig(String type) {
  switch (type) {
    case 'critical':
      return (
        iconBg: const Color(0xFFFEE2E2),
        iconColor: const Color(0xFFEF4444),
        border: const Color(0xFFFCA5A5),
        icon: Icons.local_fire_department_rounded,
      );
    case 'warning':
      return (
        iconBg: const Color(0xFFFEF9C3),
        iconColor: const Color(0xFFF59E0B),
        border: const Color(0xFFFDE68A),
        icon: Icons.warning_amber_rounded,
      );
    case 'resolved':
    default:
      return (
        iconBg: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
        border: const Color(0xFFBBF7D0),
        icon: Icons.check_circle_outline_rounded,
      );
  }
}

// ── Time helper ───────────────────────────────────────────────────────────────

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}
