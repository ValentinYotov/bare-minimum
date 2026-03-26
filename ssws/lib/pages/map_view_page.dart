import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/info_card.dart';
import '../widgets/action_button_card.dart';

class MapViewPage extends StatefulWidget {
  const MapViewPage({super.key});

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class FieldZone {
  final String name;
  final String description;
  final Rect rect;
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
    required this.name,
    required this.description,
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

  FieldZone copyWith({
    String? name,
    String? description,
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
      name: name ?? this.name,
      description: description ?? this.description,
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

class _MapViewPageState extends State<MapViewPage> {
  late List<FieldZone> zones;
  int selectedZoneIndex = 0;

  @override
  void initState() {
    super.initState();

    zones = [
      FieldZone(
        name: 'Zone A',
        description: 'Top-left field area',
        rect: const Rect.fromLTWH(0.06, 0.10, 0.40, 0.33),
        borderColor: const Color(0xFF5AC56A),
        fillColor: const Color(0xFFAEE8B8),
        hasSensor: true,
        sensorName: 'Soil Sensor A1',
        sensorType: 'Soil Moisture',
        status: 'Active',
        currentValue: '68%',
        lastUpdate: '2 min ago',
        sensorIcon: Icons.water_drop_outlined,
        sensorColor: const Color(0xFF3B82F6),
      ),
      FieldZone(
        name: 'Zone B',
        description: 'Top-right field area',
        rect: const Rect.fromLTWH(0.50, 0.10, 0.40, 0.33),
        borderColor: const Color(0xFF60A5FA),
        fillColor: const Color(0xFFAECFE0),
        hasSensor: false,
        sensorName: 'No sensor assigned',
        sensorType: 'Not set',
        status: 'Inactive',
        currentValue: '--',
        lastUpdate: 'No data',
        sensorIcon: Icons.sensors_off_outlined,
        sensorColor: const Color(0xFFB8C0CC),
      ),
      FieldZone(
        name: 'Zone C',
        description: 'Bottom field area',
        rect: const Rect.fromLTWH(0.06, 0.50, 0.84, 0.30),
        borderColor: const Color(0xFFB48AE8),
        fillColor: const Color(0xFFB8CED3),
        hasSensor: true,
        sensorName: 'Fire Sensor C1',
        sensorType: 'Fire Detector',
        status: 'Active',
        currentValue: 'Normal',
        lastUpdate: '1 min ago',
        sensorIcon: Icons.local_fire_department_outlined,
        sensorColor: const Color(0xFF08C24E),
      ),
    ];
  }

  void _addZone() {
    if (zones.length >= 5) return;

    final nextIndex = zones.length;
    final letter = String.fromCharCode(65 + nextIndex);

    setState(() {
      zones.add(
        FieldZone(
          name: 'Zone $letter',
          description: 'New split area',
          rect: Rect.fromLTWH(
            0.12 + (nextIndex * 0.06),
            0.16 + (nextIndex * 0.06),
            0.34,
            0.24,
          ),
          borderColor: const Color(0xFF8B5CF6),
          fillColor: const Color(0xFFD8CFF3),
          hasSensor: false,
          sensorName: 'No sensor assigned',
          sensorType: 'Not set',
          status: 'Inactive',
          currentValue: '--',
          lastUpdate: 'No data',
          sensorIcon: Icons.sensors_off_outlined,
          sensorColor: const Color(0xFFB8C0CC),
        ),
      );
      selectedZoneIndex = zones.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedZone = zones[selectedZoneIndex];
    final now = TimeOfDay.now();
    final hourLabel =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      drawer: const AppDrawer(selectedPage: 'map'),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Field Map View',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-time sensor locations and field zones',
              style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            _WeatherCard(currentHour: hourLabel),

            const SizedBox(height: 22),

            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Field Layout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Container(
                    height: 220,
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8EFD0),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            for (int i = 0; i < zones.length; i++)
                              _buildZone(
                                zone: zones[i],
                                isSelected: i == selectedZoneIndex,
                                parentWidth: constraints.maxWidth,
                                parentHeight: constraints.maxHeight,
                                onTap: () {
                                  setState(() {
                                    selectedZoneIndex = i;
                                  });
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Wrap(
                    spacing: 18,
                    runSpacing: 10,
                    children: [
                      _LegendItem(
                        color: Color(0xFF3B82F6),
                        label: 'Soil Moisture',
                      ),
                      _LegendItem(
                        color: Color(0xFF08C24E),
                        label: 'Fire Detector',
                      ),
                      _LegendItem(color: Color(0xFFB8C0CC), label: 'No Sensor'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            ActionButtonCard(
              text: 'Add / Split Zone',
              textColor: const Color(0xFF08C24E),
              borderColor: const Color(0xFF08C24E),
              onTap: _addZone,
            ),

            const SizedBox(height: 20),

            _SensorDetailsCard(zone: selectedZone),
          ],
        ),
      ),
    );
  }

  Widget _buildZone({
    required FieldZone zone,
    required bool isSelected,
    required double parentWidth,
    required double parentHeight,
    required VoidCallback onTap,
  }) {
    final left = zone.rect.left * parentWidth;
    final top = zone.rect.top * parentHeight;
    final width = zone.rect.width * parentWidth;
    final height = zone.rect.height * parentHeight;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: zone.fillColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF111827) : zone.borderColor,
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow:
                isSelected
                    ? const [
                      BoxShadow(
                        color: Color(0x16000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    zone.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
              Align(alignment: Alignment.center, child: _SensorDot(zone: zone)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final String currentHour;

  const _WeatherCard({required this.currentHour});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Weather • $currentHour',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '24°C',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Partly Cloudy',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeatherStat(
                icon: Icons.thermostat_outlined,
                label: 'Humidity',
                value: '65%',
              ),
              _WeatherStat(icon: Icons.air, label: 'Wind', value: '12 km/h'),
              _WeatherStat(
                icon: Icons.water_drop_outlined,
                label: 'Rain',
                value: '0%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: Color(0xFF374151)),
        ),
      ],
    );
  }
}

class _SensorDot extends StatelessWidget {
  final FieldZone zone;

  const _SensorDot({required this.zone});

  @override
  Widget build(BuildContext context) {
    final isInactive = !zone.hasSensor;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isInactive ? const Color(0xFFE5E7EB) : zone.sensorColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:
                (isInactive
                    ? Colors.black12
                    : zone.sensorColor.withOpacity(0.26)),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        zone.sensorIcon,
        color: isInactive ? const Color(0xFF94A3B8) : Colors.white,
        size: 22,
      ),
    );
  }
}

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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: active ? zone.sensorColor : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  zone.sensorIcon,
                  color: active ? Colors.white : const Color(0xFF94A3B8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active ? zone.sensorName : zone.name,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      zone.name,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          _detailRow(
            title: 'Status',
            value: zone.status,
            valueColor:
                active ? const Color(0xFF08A63E) : const Color(0xFF94A3B8),
            statusChip: true,
          ),
          _divider(),
          _detailRow(title: 'Current Value', value: zone.currentValue),
          _divider(),
          _detailRow(title: 'Type', value: zone.sensorType),
          _divider(),
          _detailRow(title: 'Last Update', value: zone.lastUpdate),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: active ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    active ? const Color(0xFF08B33F) : const Color(0xFFE5E7EB),
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                foregroundColor:
                    active ? Colors.white : const Color(0xFF94A3B8),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                active ? 'View History' : 'No Sensor Added',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
    );
  }

  Widget _detailRow({
    required String title,
    required String value,
    Color valueColor = const Color(0xFF111827),
    bool statusChip = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (statusChip)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: valueColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
      ],
    );
  }
}
