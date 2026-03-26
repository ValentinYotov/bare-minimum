import 'package:flutter/material.dart';
import '../widgets/action_button_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/info_card.dart';
import '../widgets/stat_small_card.dart';
import '../widgets/top_navbar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F5),
      drawer: const AppDrawer(selectedPage: 'dashboard'),
      appBar: const TopNavbar(),
      body: Builder(
        builder:
            (context) => CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Monitor and control your irrigation system',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _todaySummaryCard(),
                      const SizedBox(height: 20),

                      _soilMoistureCard(),
                      const SizedBox(height: 20),

                      _wateringSystemCard(),
                      const SizedBox(height: 20),

                      _fireDetectionCard(),
                      const SizedBox(height: 20),

                      _quickActionsCard(),
                      const SizedBox(height: 20),

                      const StatSmallCard(
                        label: 'System Uptime',
                        value: '99.8%',
                        subtitle: 'Last 30 days',
                        valueColor: Color(0xFF05B63D),
                      ),
                      const SizedBox(height: 16),

                      const StatSmallCard(
                        label: 'Water Saved',
                        value: '1,245L',
                        subtitle: 'This month',
                        valueColor: Color(0xFF2563FF),
                      ),
                      const SizedBox(height: 16),

                      const StatSmallCard(
                        label: 'Active Sensors',
                        value: '8/8',
                        subtitle: 'All operational',
                        valueColor: Color(0xFF9333EA),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _todaySummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF05B63D),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                "Today's Summary",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryItem(label: 'Water Used', value: '245L'),
              _SummaryItem(label: 'Last Watered', value: '2h ago'),
            ],
          ),
          SizedBox(height: 18),
          _SummaryItem(label: 'Fire Status', value: 'No alerts'),
        ],
      ),
    );
  }

  Widget _soilMoistureCard() {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _IconBox(
                icon: Icons.water_drop_outlined,
                bgColor: Color(0xFFDCE8FF),
                iconColor: Color(0xFF2563FF),
              ),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Soil Moisture',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Real-time sensor data',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '68%',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2563FF),
                ),
              ),
              Text(
                '↗ +5% from yesterday',
                style: TextStyle(fontSize: 14, color: Color(0xFF16A34A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.68,
              minHeight: 10,
              backgroundColor: Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(Color(0xFF2563FF)),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Optimal moisture level',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  Widget _wateringSystemCard() {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _IconBox(
                icon: Icons.power_settings_new,
                bgColor: Color(0xFFEAEAEA),
                iconColor: Color(0xFF4B5563),
              ),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Watering System',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Manual control',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status:', style: TextStyle(fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Inactive',
                  style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05B63D),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start Watering',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fireDetectionCard() {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _IconBox(
                icon: Icons.local_fire_department_outlined,
                bgColor: Color(0xFFD7F1DF),
                iconColor: Color(0xFF16A34A),
              ),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fire Detection',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Smoke sensor',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26),
            decoration: BoxDecoration(
              color: const Color(0xFFCFEED6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                Icon(Icons.check, size: 48, color: Color(0xFF16A34A)),
                SizedBox(height: 10),
                Text(
                  'All Clear',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF15803D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No fire or smoke detected. System operating normally.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionsCard() {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 18),
          ActionButtonCard(
            text: 'Schedule Watering',
            textColor: const Color(0xFF15803D),
            borderColor: const Color(0xFFA7F3D0),
            onTap: () {},
          ),
          const SizedBox(height: 14),
          ActionButtonCard(
            text: 'View History',
            textColor: const Color(0xFF1D4ED8),
            borderColor: const Color(0xFFBFDBFE),
            onTap: () {},
          ),
          const SizedBox(height: 14),
          ActionButtonCard(
            text: 'Sensor Calibration',
            textColor: const Color(0xFF9333EA),
            borderColor: const Color(0xFFE9D5FF),
            onTap: () {},
          ),
          const SizedBox(height: 14),
          ActionButtonCard(
            text: 'Download Report',
            textColor: const Color(0xFFEA580C),
            borderColor: const Color(0xFFFED7AA),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _IconBox({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.white)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
