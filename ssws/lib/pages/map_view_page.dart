import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_drawer.dart';
import '../widgets/info_card.dart';

const String _kHumidityApiUrl = 'http://localhost:8003/minimum-humidity';

// ── Icon registry (constant instances for tree shaking) ──────────────────────

const _kIconMap = <String, IconData>{
  'water_drop': Icons.water_drop_outlined,
  'fire': Icons.local_fire_department_outlined,  
  'sensors_off': Icons.sensors_off_outlined,
  'thermostat': Icons.thermostat_outlined,
  'air': Icons.air,
  'grass': Icons.grass_outlined,
  'science': Icons.science_outlined,
};

String _iconToKey(IconData icon) {
  for (final e in _kIconMap.entries) {
    if (e.value.codePoint == icon.codePoint) return e.key;
  }
  return 'sensors_off';
}

IconData _keyToIcon(String? key) => _kIconMap[key] ?? Icons.sensors_off_outlined;

// ── Zone model ────────────────────────────────────────────────────────────────

class FieldZone {
  final String id;
  final String name;
  final Rect rect; // fractional coords 0.0–1.0 relative to canvas
  final Color borderColor;
  final Color fillColor;
  final bool hasSensor;
  final String sensorName;
  final String sensorType;
  final String status;
  final String currentValue;
  final String lastUpdate;
  final IconData sensorIcon;
  final Color sensorColor;

  const FieldZone({
    required this.id,
    required this.name,
    required this.rect,
    required this.borderColor,
    required this.fillColor,
    required this.hasSensor,
    required this.sensorName,
    required this.sensorType,
    required this.status,
    required this.currentValue,
    required this.lastUpdate,
    required this.sensorIcon,
    required this.sensorColor,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'left': rect.left,
    'top': rect.top,
    'width': rect.width,
    'height': rect.height,
    'borderColor': borderColor.value,
    'fillColor': fillColor.value,
    'hasSensor': hasSensor,
    'sensorName': sensorName,
    'sensorType': sensorType,
    'status': status,
    'currentValue': currentValue,
    'lastUpdate': lastUpdate,
    'sensorIconKey': _iconToKey(sensorIcon),
    'sensorColor': sensorColor.value,
  };

  factory FieldZone.fromMap(String id, Map<String, dynamic> m) {
    return FieldZone(
      id: id,
      name: m['name'] as String? ?? 'Zone',
      rect: Rect.fromLTWH(
        (m['left'] as num?)?.toDouble() ?? 0.1,
        (m['top'] as num?)?.toDouble() ?? 0.1,
        (m['width'] as num?)?.toDouble() ?? 0.3,
        (m['height'] as num?)?.toDouble() ?? 0.25,
      ),
      borderColor: Color(m['borderColor'] as int? ?? 0xFF22C55E),
      fillColor: Color(m['fillColor'] as int? ?? 0xFFBBF7D0),
      hasSensor: m['hasSensor'] as bool? ?? false,
      sensorName: m['sensorName'] as String? ?? 'No sensor assigned',
      sensorType: m['sensorType'] as String? ?? 'Not set',
      status: m['status'] as String? ?? 'Inactive',
      currentValue: m['currentValue'] as String? ?? '--',
      lastUpdate: m['lastUpdate'] as String? ?? 'No data',
      sensorIcon: _keyToIcon(m['sensorIconKey'] as String?),
      sensorColor: Color(m['sensorColor'] as int? ?? 0xFFB8C0CC),
    );
  }

  FieldZone copyWith({
    String? name,
    Rect? rect,
    Color? borderColor,
    Color? fillColor,
    bool? hasSensor,
    String? sensorName,
    String? sensorType,
    String? status,
    String? currentValue,
    String? lastUpdate,
    IconData? sensorIcon,
    Color? sensorColor,
  }) {
    return FieldZone(
      id: id,
      name: name ?? this.name,
      rect: rect ?? this.rect,
      borderColor: borderColor ?? this.borderColor,
      fillColor: fillColor ?? this.fillColor,
      hasSensor: hasSensor ?? this.hasSensor,
      sensorName: sensorName ?? this.sensorName,
      sensorType: sensorType ?? this.sensorType,
      status: status ?? this.status,
      currentValue: currentValue ?? this.currentValue,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      sensorIcon: sensorIcon ?? this.sensorIcon,
      sensorColor: sensorColor ?? this.sensorColor,
    );
  }
}

// Preset color pairs for zone color picker
const _kColorPresets = [
  (border: Color(0xFF22C55E), fill: Color(0xFFBBF7D0)),
  (border: Color(0xFF3B82F6), fill: Color(0xFFBFDBFE)),
  (border: Color(0xFFA855F7), fill: Color(0xFFE9D5FF)),
  (border: Color(0xFFF97316), fill: Color(0xFFFFDDB8)),
  (border: Color(0xFFEC4899), fill: Color(0xFFFCE7F3)),
  (border: Color(0xFF14B8A6), fill: Color(0xFFCCFBF1)),
];

// ── Page ─────────────────────────────────────────────────────────────────────

class MapViewPage extends StatefulWidget {
  const MapViewPage({super.key});

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  // Static cache — tagged with UID so it invalidates on user switch
  final TextEditingController _plantController = TextEditingController();

  String? _humidityResult;
  bool _isLoadingHumidity = false;
  static String? _savedUid;
  static List<FieldZone>? _savedZones;
  static int _savedSelectedIndex = 0;
  static int _savedNextId = 4;

  bool _editMode = false;
  bool _loading = true;
  late int _selectedIndex;
  Size? _canvasSize;
  late int _nextId;
  late List<FieldZone> _zones;
  Timer? _debounce;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  CollectionReference get _zonesCol {
    return FirebaseFirestore.instance.collection('users').doc(_uid).collection('zones');
  }

  @override
  void initState() {
    super.initState();

    // Only use cache if it belongs to the current user
    final cacheValid = _savedZones != null && _savedUid == _uid;

    if (cacheValid) {
      _selectedIndex = _savedSelectedIndex;
      _nextId = _savedNextId;
      _zones = List.from(_savedZones!);
      _loading = false;
    } else {
      // Different user or first load — clear stale cache and load from Firestore
      _savedZones = null;
      _savedUid = null;
      _selectedIndex = 0;
      _nextId = 4;
      _zones = [];
      _loadZones();
    }
  }

  @override
  void dispose() {
    // Flush any pending debounced write
    if (_debounce?.isActive == true) {
      _debounce!.cancel();
      _writeAllToFirestore();
    }
    _savedUid = _uid;
    _savedZones = List.from(_zones);
    _savedSelectedIndex = _selectedIndex;
    _savedNextId = _nextId;
    super.dispose();
  }

  Future<void> _fetchMinimumHumidity() async {
    final plant = _plantController.text.trim();

    if (plant.isEmpty) return;

    setState(() {
      _isLoadingHumidity = true;
      _humidityResult = null;
    });

    try {
      final response = await http.post(
        Uri.parse(_kHumidityApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'plant': plant}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['error'] != null) {
          setState(() {
            _humidityResult = data['error'];
          });
        } else {
          setState(() {
            _humidityResult =
                "Minimum humidity: ${data['minimum_humidity']}%";
          });
        }
      } else {
        setState(() {
          _humidityResult = "Error: ${data.toString()}";
        });
      }
    } catch (e) {
      setState(() {
        _humidityResult = "Connection error: $e";
      });
    } finally {
      setState(() {
        _isLoadingHumidity = false;
      });
    }
}

  // ── Firestore I/O ─────────────────────────────────────────────────────────

  static const _defaultZones = <FieldZone>[
    FieldZone(
      id: '1',
      name: 'Zone A',
      rect: Rect.fromLTWH(0.04, 0.06, 0.42, 0.38),
      borderColor: Color(0xFF22C55E),
      fillColor: Color(0xFFBBF7D0),
      hasSensor: true,
      sensorName: 'Soil Sensor A1',
      sensorType: 'Soil Moisture',
      status: 'Active',
      currentValue: '68%',
      lastUpdate: '2 min ago',
      sensorIcon: Icons.water_drop_outlined,
      sensorColor: Color(0xFF3B82F6),
    ),
    FieldZone(
      id: '2',
      name: 'Zone B',
      rect: Rect.fromLTWH(0.52, 0.06, 0.42, 0.38),
      borderColor: Color(0xFF3B82F6),
      fillColor: Color(0xFFBFDBFE),
      hasSensor: false,
      sensorName: 'No sensor assigned',
      sensorType: 'Not set',
      status: 'Inactive',
      currentValue: '--',
      lastUpdate: 'No data',
      sensorIcon: Icons.sensors_off_outlined,
      sensorColor: Color(0xFFB8C0CC),
    ),
    FieldZone(
      id: '3',
      name: 'Zone C',
      rect: Rect.fromLTWH(0.04, 0.54, 0.90, 0.34),
      borderColor: Color(0xFFA855F7),
      fillColor: Color(0xFFE9D5FF),
      hasSensor: true,
      sensorName: 'Fire Sensor C1',
      sensorType: 'Fire Detector',
      status: 'Active',
      currentValue: 'Normal',
      lastUpdate: '1 min ago',
      sensorIcon: Icons.local_fire_department_outlined,
      sensorColor: Color(0xFF10B981),
    ),
  ];

  Future<void> _loadZones() async {
    try {
      final snap = await _zonesCol.get();
      if (snap.docs.isEmpty) {
        // First time user — seed with defaults and write to Firestore
        _zones = List.from(_defaultZones);
        await _writeAllToFirestore();
      } else {
        _zones = snap.docs
            .map((d) => FieldZone.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList();
        // Derive next ID from existing docs
        int maxId = 3;
        for (final z in _zones) {
          final parsed = int.tryParse(z.id);
          if (parsed != null && parsed > maxId) maxId = parsed;
        }
        _nextId = maxId + 1;
      }
    } catch (_) {
      // Offline fallback — use defaults
      if (_zones.isEmpty) _zones = List.from(_defaultZones);
    }
    if (mounted) {
      setState(() => _loading = false);
      _savedUid = _uid;
      _savedZones = List.from(_zones);
      _savedNextId = _nextId;
    }
  }

  Future<void> _writeAllToFirestore() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      // Remove docs no longer present
      final existing = await _zonesCol.get();
      final currentIds = _zones.map((z) => z.id).toSet();
      for (final doc in existing.docs) {
        if (!currentIds.contains(doc.id)) batch.delete(doc.reference);
      }
      // Upsert current zones
      for (final z in _zones) {
        batch.set(_zonesCol.doc(z.id), z.toMap());
      }
      await batch.commit();
    } catch (_) {
      // Silently fail — data is still in static cache
    }
  }

  // Persist to static cache (tagged with UID) + debounced Firestore write
  void _persistState() {
    _savedUid = _uid;
    _savedZones = List.from(_zones);
    _savedSelectedIndex = _selectedIndex;
    _savedNextId = _nextId;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _writeAllToFirestore();
    });
  }

  // ── Gesture handlers ──────────────────────────────────────────────────────

  void _onZoneDrag(int index, DragUpdateDetails d) {
    if (_canvasSize == null) return;
    final z = _zones[index];
    final dx = d.delta.dx / _canvasSize!.width;
    final dy = d.delta.dy / _canvasSize!.height;
    final newLeft = (z.rect.left + dx).clamp(0.0, 1.0 - z.rect.width);
    final newTop = (z.rect.top + dy).clamp(0.0, 1.0 - z.rect.height);
    setState(() {
      _zones[index] = z.copyWith(
        rect: Rect.fromLTWH(newLeft, newTop, z.rect.width, z.rect.height),
      );
    });
    _persistState();
  }

  void _onResizeTL(int index, DragUpdateDetails d) {
    if (_canvasSize == null) return;
    final z = _zones[index];
    final dx = d.delta.dx / _canvasSize!.width;
    final dy = d.delta.dy / _canvasSize!.height;
    final newLeft = (z.rect.left + dx).clamp(0.0, z.rect.right - 0.12);
    final newTop = (z.rect.top + dy).clamp(0.0, z.rect.bottom - 0.12);
    setState(() {
      _zones[index] = z.copyWith(
        rect: Rect.fromLTRB(newLeft, newTop, z.rect.right, z.rect.bottom),
      );
    });
    _persistState();
  }

  void _onResizeTR(int index, DragUpdateDetails d) {
    if (_canvasSize == null) return;
    final z = _zones[index];
    final dx = d.delta.dx / _canvasSize!.width;
    final dy = d.delta.dy / _canvasSize!.height;
    final newRight = (z.rect.right + dx).clamp(z.rect.left + 0.12, 1.0);
    final newTop = (z.rect.top + dy).clamp(0.0, z.rect.bottom - 0.12);
    setState(() {
      _zones[index] = z.copyWith(
        rect: Rect.fromLTRB(z.rect.left, newTop, newRight, z.rect.bottom),
      );
    });
    _persistState();
  }

  void _onResizeBL(int index, DragUpdateDetails d) {
    if (_canvasSize == null) return;
    final z = _zones[index];
    final dx = d.delta.dx / _canvasSize!.width;
    final dy = d.delta.dy / _canvasSize!.height;
    final newLeft = (z.rect.left + dx).clamp(0.0, z.rect.right - 0.12);
    final newBottom = (z.rect.bottom + dy).clamp(z.rect.top + 0.12, 1.0);
    setState(() {
      _zones[index] = z.copyWith(
        rect: Rect.fromLTRB(newLeft, z.rect.top, z.rect.right, newBottom),
      );
    });
    _persistState();
  }

  void _onResizeBR(int index, DragUpdateDetails d) {
    if (_canvasSize == null) return;
    final z = _zones[index];
    final dx = d.delta.dx / _canvasSize!.width;
    final dy = d.delta.dy / _canvasSize!.height;
    final newRight = (z.rect.right + dx).clamp(z.rect.left + 0.12, 1.0);
    final newBottom = (z.rect.bottom + dy).clamp(z.rect.top + 0.12, 1.0);
    setState(() {
      _zones[index] = z.copyWith(
        rect: Rect.fromLTRB(z.rect.left, z.rect.top, newRight, newBottom),
      );
    });
    _persistState();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _renameZone(int index) async {
    final ctrl = TextEditingController(text: _zones[index].name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rename Zone', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Zone name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
            ),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _zones[index] = _zones[index].copyWith(name: result));
      _persistState();
    }
  }

  void _changeColor(int index) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Zone colour', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_kColorPresets.length, (ci) {
                final preset = _kColorPresets[ci];
                final isSelected = _zones[index].borderColor == preset.border;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _zones[index] = _zones[index].copyWith(
                        borderColor: preset.border,
                        fillColor: preset.fill,
                      );
                    });
                    _persistState();
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: preset.fill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? preset.border : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: preset.border.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(Icons.check_rounded, color: preset.border, size: 22)
                        : null,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteZone(int index) {
    if (_zones.length <= 1) return;
    setState(() {
      _zones.removeAt(index);
      _selectedIndex = (_selectedIndex >= _zones.length)
          ? _zones.length - 1
          : _selectedIndex;
    });
    _persistState();
  }

  void _addZone() {
    final id = '${_nextId++}';
    final offset = (_zones.length % _kColorPresets.length);
    final preset = _kColorPresets[offset];
    setState(() {
      _zones.add(FieldZone(
        id: id,
        name: 'Zone ${String.fromCharCode(64 + _zones.length + 1)}',
        rect: Rect.fromLTWH(0.08 + (_zones.length * 0.04), 0.08 + (_zones.length * 0.04), 0.36, 0.28),
        borderColor: preset.border,
        fillColor: preset.fill,
        hasSensor: false,
        sensorName: 'No sensor assigned',
        sensorType: 'Not set',
        status: 'Inactive',
        currentValue: '--',
        lastUpdate: 'No data',
        sensorIcon: Icons.sensors_off_outlined,
        sensorColor: const Color(0xFFB8C0CC),
      ));
      _selectedIndex = _zones.length - 1;
    });
    _persistState();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(selectedPage: 'map'),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Field Map View',
          style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _editMode
                  ? FilledButton.icon(
                      key: const ValueKey('done'),
                      onPressed: () => setState(() => _editMode = false),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Done'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    )
                  : OutlinedButton.icon(
                      key: const ValueKey('edit'),
                      onPressed: () => setState(() => _editMode = true),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Edit mode hint banner
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              child: _editMode
                  ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9C4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFBBF24)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFB45309)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Drag zones to move • Corner handles to resize • Tap name to rename',
                              style: TextStyle(fontSize: 12, color: Colors.brown[700], height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Canvas
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Field Layout',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      ),
                      const Spacer(),
                      if (_editMode)
                        TextButton.icon(
                          onPressed: _addZone,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Zone'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF16A34A),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // The actual canvas
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 320,
                      width: double.infinity,
                      color: const Color(0xFFD1FAE5),
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                          return Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              // Grid dots for visual reference
                              CustomPaint(
                                size: Size(constraints.maxWidth, constraints.maxHeight),
                                painter: _GridPainter(),
                              ),
                              for (int i = 0; i < _zones.length; i++)
                                _ZoneTile(
                                  zone: _zones[i],
                                  isSelected: i == _selectedIndex,
                                  editMode: _editMode,
                                  canvasSize: _canvasSize!,
                                  onTap: () => setState(() => _selectedIndex = i),
                                  onDrag: (d) => _onZoneDrag(i, d),
                                  onResizeTL: (d) => _onResizeTL(i, d),
                                  onResizeTR: (d) => _onResizeTR(i, d),
                                  onResizeBL: (d) => _onResizeBL(i, d),
                                  onResizeBR: (d) => _onResizeBR(i, d),
                                  onRename: () => _renameZone(i),
                                  onDelete: () => _deleteZone(i),
                                  onChangeColor: () => _changeColor(i),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: _zones.map((z) => _LegendItem(color: z.borderColor, label: z.name)).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

InfoCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "AI Minimum Humidity",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        ),
      ),
      const SizedBox(height: 12),

      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _plantController,
              decoration: InputDecoration(
                hintText: "Enter plant (e.g. tomato)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isLoadingHumidity ? null : _fetchMinimumHumidity,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoadingHumidity
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text("Find"),
          ),
        ],
      ),

      const SizedBox(height: 12),

      if (_humidityResult != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _humidityResult!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    ],
  ),
),

            const SizedBox(height: 16),

            // Zone details / edit panel
            _editMode
                ? _ZoneEditPanel(
                    zone: _zones[_selectedIndex],
                    onRename: () => _renameZone(_selectedIndex),
                    onChangeColor: () => _changeColor(_selectedIndex),
                    onDelete: _zones.length > 1 ? () => _deleteZone(_selectedIndex) : null,
                  )
                : _SensorDetailsCard(zone: _zones[_selectedIndex]),
          ],
        ),
      ),
    );
  }
}

// ── Zone tile ─────────────────────────────────────────────────────────────────

class _ZoneTile extends StatelessWidget {
  final FieldZone zone;
  final bool isSelected;
  final bool editMode;
  final Size canvasSize;
  final VoidCallback onTap;
  final void Function(DragUpdateDetails) onDrag;
  final void Function(DragUpdateDetails) onResizeTL;
  final void Function(DragUpdateDetails) onResizeTR;
  final void Function(DragUpdateDetails) onResizeBL;
  final void Function(DragUpdateDetails) onResizeBR;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onChangeColor;

  const _ZoneTile({
    required this.zone,
    required this.isSelected,
    required this.editMode,
    required this.canvasSize,
    required this.onTap,
    required this.onDrag,
    required this.onResizeTL,
    required this.onResizeTR,
    required this.onResizeBL,
    required this.onResizeBR,
    required this.onRename,
    required this.onDelete,
    required this.onChangeColor,
  });

  @override
  Widget build(BuildContext context) {
    final left = zone.rect.left * canvasSize.width;
    final top = zone.rect.top * canvasSize.height;
    final width = zone.rect.width * canvasSize.width;
    final height = zone.rect.height * canvasSize.height;
    const handleSize = 22.0;
    const handleVisual = 12.0;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Zone body — drag to move
          Positioned.fill(
            child: GestureDetector(
              onTap: onTap,
              onPanUpdate: editMode ? onDrag : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: zone.fillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? (editMode ? const Color(0xFFF59E0B) : const Color(0xFF111827))
                        : zone.borderColor,
                    width: isSelected ? 2 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: zone.borderColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Stack(
                  children: [
                    // Zone name label — tap to rename in edit mode
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: editMode ? onRename : onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: editMode
                                ? Border.all(color: zone.borderColor.withOpacity(0.5), width: 1)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                zone.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              if (editMode) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.edit_rounded, size: 10, color: zone.borderColor),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Sensor dot
                    if (!editMode)
                      Center(child: _SensorDot(zone: zone)),

                    // Edit mode: move cursor icon
                    if (editMode)
                      const Center(
                        child: Icon(Icons.open_with_rounded, color: Colors.black26, size: 22),
                      ),

                    // Color picker button (edit mode)
                    if (editMode)
                      Positioned(
                        bottom: 6,
                        left: 8,
                        child: GestureDetector(
                          onTap: onChangeColor,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: zone.borderColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [BoxShadow(color: zone.borderColor.withOpacity(0.4), blurRadius: 6)],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Resize handles (edit mode only) ──
          if (editMode) ...[
            // Top-left
            Positioned(
              left: -handleSize / 2,
              top: -handleSize / 2,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                onPanUpdate: onResizeTL,
                child: _HandleDot(color: zone.borderColor, size: handleVisual),
              ),
            ),
            // Top-right
            Positioned(
              right: -handleSize / 2,
              top: -handleSize / 2,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                onPanUpdate: onResizeTR,
                child: _HandleDot(color: zone.borderColor, size: handleVisual),
              ),
            ),
            // Bottom-left
            Positioned(
              left: -handleSize / 2,
              bottom: -handleSize / 2,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                onPanUpdate: onResizeBL,
                child: _HandleDot(color: zone.borderColor, size: handleVisual),
              ),
            ),
            // Bottom-right
            Positioned(
              right: -handleSize / 2,
              bottom: -handleSize / 2,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                onPanUpdate: onResizeBR,
                child: _HandleDot(color: zone.borderColor, size: handleVisual),
              ),
            ),

            // Delete button (top-right corner, outside)
            Positioned(
              right: -14,
              top: -14,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HandleDot extends StatelessWidget {
  final Color color;
  final double size;

  const _HandleDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))],
        ),
      ),
    );
  }
}

// ── Grid painter ──────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1A065F46)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ── Zone edit panel ───────────────────────────────────────────────────────────

class _ZoneEditPanel extends StatelessWidget {
  final FieldZone zone;
  final VoidCallback onRename;
  final VoidCallback onChangeColor;
  final VoidCallback? onDelete;

  const _ZoneEditPanel({
    required this.zone,
    required this.onRename,
    required this.onChangeColor,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: zone.borderColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                'Editing: ${zone.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _EditAction(
            icon: Icons.drive_file_rename_outline_rounded,
            label: 'Rename zone',
            subtitle: zone.name,
            onTap: onRename,
          ),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          _EditAction(
            icon: Icons.palette_outlined,
            label: 'Change colour',
            subtitle: 'Tap to pick a new colour',
            onTap: onChangeColor,
            trailing: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: zone.fillColor,
                shape: BoxShape.circle,
                border: Border.all(color: zone.borderColor, width: 2),
              ),
            ),
          ),
          if (onDelete != null) ...[
            const Divider(height: 24, color: Color(0xFFE5E7EB)),
            _EditAction(
              icon: Icons.delete_outline_rounded,
              label: 'Delete zone',
              subtitle: 'This cannot be undone',
              onTap: onDelete!,
              destructive: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _EditAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool destructive;

  const _EditAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFEF4444) : const Color(0xFF374151);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: destructive ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
          ),
          trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 20),
        ],
      ),
    );
  }
}

// ── Sensor details card (view mode) ──────────────────────────────────────────

class _SensorDetailsCard extends StatelessWidget {
  final FieldZone zone;

  const _SensorDetailsCard({required this.zone});

  @override
  Widget build(BuildContext context) {
    final active = zone.hasSensor;
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: active ? zone.sensorColor : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(zone.sensorIcon, color: active ? Colors.white : const Color(0xFF94A3B8), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active ? zone.sensorName : zone.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                    Text(
                      zone.name,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  zone.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _StatBox(label: 'Current Value', value: zone.currentValue)),
              const SizedBox(width: 10),
              Expanded(child: _StatBox(label: 'Type', value: zone.sensorType)),
              const SizedBox(width: 10),
              Expanded(child: _StatBox(label: 'Last Update', value: zone.lastUpdate)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: active ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: active ? const Color(0xFF16A34A) : const Color(0xFFE5E7EB),
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                foregroundColor: active ? Colors.white : const Color(0xFF94A3B8),
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                active ? 'View Sensor History' : 'No Sensor Assigned',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SensorDot extends StatelessWidget {
  final FieldZone zone;

  const _SensorDot({required this.zone});

  @override
  Widget build(BuildContext context) {
    final inactive = !zone.hasSensor;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: inactive ? const Color(0xFFE5E7EB) : zone.sensorColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: inactive ? Colors.black12 : zone.sensorColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        zone.sensorIcon,
        color: inactive ? const Color(0xFF94A3B8) : Colors.white,
        size: 20,
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
      ],
    );
  }
}
