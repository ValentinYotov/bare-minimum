import 'package:flutter/material.dart';
import '../data/crop_repository.dart';
import '../models/crop_model.dart';
import '../widgets/app_drawer.dart';
import '../widgets/top_navbar.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  bool _isReading = false;
  bool _hasReadSensor = false;

  int nitrogen = 0;
  int phosphorus = 0;
  int potassium = 0;
  double ph = 0;
  String soilType = 'Unknown';

  List<CropModel> recommendedCrops = [];

  Future<void> _startSensorReading() async {
    setState(() {
      _isReading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    nitrogen = 68;
    phosphorus = 47;
    potassium = 79;
    ph = 6.4;
    soilType = 'Loamy';

    final results = CropRepository.crops.map((crop) {
      final score = _calculateSuitability(crop);
      return crop.copyWith(score: score);
    }).toList();

    results.sort((a, b) => b.score.compareTo(a.score));

    setState(() {
      recommendedCrops = results;
      _hasReadSensor = true;
      _isReading = false;
    });
  }

  int _calculateSuitability(CropModel crop) {
    int score = 100;

    score -= (nitrogen - crop.idealNitrogen).abs();
    score -= (phosphorus - crop.idealPhosphorus).abs();
    score -= (potassium - crop.idealPotassium).abs();

    if (ph < crop.idealPhMin) {
      score -= ((crop.idealPhMin - ph) * 10).round();
    } else if (ph > crop.idealPhMax) {
      score -= ((ph - crop.idealPhMax) * 10).round();
    }

    if (soilType != crop.suitableSoil) {
      score -= 8;
    }

    if (score < 45) score = 45;
    if (score > 99) score = 99;

    return score;
  }

  void _showCropDetails(CropModel crop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8F8F8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    crop.imageUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  crop.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  crop.details,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 20),
                _detailRow('Suitability', '${crop.score}%'),
                _detailRow('Water Needs', crop.waterNeeds),
                _detailRow('Growth Time', crop.growthTime),
                _detailRow('Expected Yield', crop.expectedYield),
                _detailRow('Best Soil Type', crop.suitableSoil),
                _detailRow(
                  'Ideal NPK',
                  '${crop.idealNitrogen}-${crop.idealPhosphorus}-${crop.idealPotassium}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Color(0xFF111827)),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F5),
      drawer: const AppDrawer(selectedPage: 'recommendations'),
      appBar: const TopNavbar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crop Recommendations',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'AI-powered suggestions based on your soil data',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF05B63D),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.spa_outlined, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Current Soil Analysis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isReading ? null : _startSensorReading,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0D7E43),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isReading
                            ? 'Reading Sensor...'
                            : 'Start Reading from NPK Sensor',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SoilValueCard(
                    label: 'Nitrogen (N)',
                    value: _hasReadSensor ? '$nitrogen mg/kg' : '--',
                  ),
                  const SizedBox(height: 12),
                  _SoilValueCard(
                    label: 'Phosphorus (P)',
                    value: _hasReadSensor ? '$phosphorus mg/kg' : '--',
                  ),
                  const SizedBox(height: 12),
                  _SoilValueCard(
                    label: 'Potassium (K)',
                    value: _hasReadSensor ? '$potassium mg/kg' : '--',
                  ),
                  const SizedBox(height: 12),
                  _SoilValueCard(
                    label: 'Soil pH / Type',
                    value: _hasReadSensor ? '$ph / $soilType' : '--',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recommended Crops',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 14),
            if (!_hasReadSensor)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  'Press "Start Reading from NPK Sensor" to simulate a sensor scan and generate crop recommendations.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    height: 1.6,
                  ),
                ),
              ),
            if (_hasReadSensor)
              ...recommendedCrops.take(5).map(
                (crop) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _CropCard(
                    crop: crop,
                    onViewDetails: () => _showCropDetails(crop),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SoilValueCard extends StatelessWidget {
  final String label;
  final String value;

  const _SoilValueCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _CropCard extends StatelessWidget {
  final CropModel crop;
  final VoidCallback onViewDetails;

  const _CropCard({
    required this.crop,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: Image.network(
                  crop.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '↗ ${crop.score}%',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crop.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  crop.description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _CropMetaItem(
                        icon: Icons.water_drop_outlined,
                        iconColor: const Color(0xFF2563FF),
                        label: 'Water Needs',
                        value: crop.waterNeeds,
                      ),
                    ),
                    Expanded(
                      child: _CropMetaItem(
                        icon: Icons.timelapse_outlined,
                        iconColor: const Color(0xFFEA580C),
                        label: 'Growth Time',
                        value: crop.growthTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE5E7EB)),
                const SizedBox(height: 12),
                const Text(
                  'Expected Yield',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  crop.expectedYield,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onViewDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF05B63D),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _CropMetaItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _CropMetaItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}