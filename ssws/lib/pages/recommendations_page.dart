import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../data/crop_repository.dart';
import '../models/crop_model.dart';
import '../widgets/app_drawer.dart';
import '../widgets/top_navbar.dart';

// --- Change these to match your local server addresses ---
const String _kWsUrl = 'ws://localhost:8765';
const String _kApiUrl = 'http://localhost:8002/recommendations';

class _AiCropResult {
  final String cropName;
  final String confidence;
  final String reasoning;
  final CropModel? matchedCrop;

  const _AiCropResult({
    required this.cropName,
    required this.confidence,
    required this.reasoning,
    this.matchedCrop,
  });
}

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  bool _isReading = false;
  bool _hasReadSensor = false;
  String? _errorMessage;
  String _statusText = '';

  double _nitrogen = 0;
  double _phosphorus = 0;
  double _potassium = 0;
  double _ph = 0;
  double _humidity = 0;
  double _ec = 0;

  List<_AiCropResult> _results = [];

  Future<void> _startSensorReading() async {
    setState(() {
      _isReading = true;
      _errorMessage = null;
      _statusText = 'Waiting for sensor data...';
    });

    try {
      // Step 1: read sensor data via WebSocket
      final sensor = await _readSensor();
      if (sensor == null) {
        setState(() {
          _errorMessage =
              'Could not get valid sensor readings. Make sure the sensor server (main.py) is running and the NPK sensor is connected.';
          _isReading = false;
          _statusText = '';
        });
        return;
      }

      setState(() {
        _nitrogen = sensor['N']!;
        _phosphorus = sensor['P']!;
        _potassium = sensor['K']!;
        _ph = sensor['ph']!;
        _humidity = sensor['humidity']!;
        _ec = sensor['ec']!;
        _statusText = 'Fetching AI recommendations...';
      });

      // Step 2: send sensor data to the recommendations API
      final recs = await _fetchRecommendations(sensor);

      setState(() {
        _results = recs;
        _hasReadSensor = true;
        _isReading = false;
        _statusText = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isReading = false;
        _statusText = '';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // WebSocket: connect, wait for one valid reading, return parsed values
  // ---------------------------------------------------------------------------
  Future<Map<String, double>?> _readSensor() async {
    WebSocketChannel? channel;
    StreamSubscription? sub;
    final completer = Completer<Map<String, double>?>();

    try {
      channel = WebSocketChannel.connect(Uri.parse(_kWsUrl));

      // Wait for handshake — timeout separately so we fail fast if server is down
      try {
        await channel.ready.timeout(const Duration(seconds: 10));
      } catch (_) {
        return null;
      }

      sub = channel.stream.listen(
        (raw) {
          if (completer.isCompleted) return;
          try {
            final data = json.decode(raw.toString()) as Map<String, dynamic>;

            final n   = _tryParse(data['Nitrogen (N)']);
            final p   = _tryParse(data['Phosphorus (P)']);
            final k   = _tryParse(data['Potassium (K)']);
            final ph  = _tryParse(data['pH Level']);
            final hum = _tryParse(data['humidity']);
            final ec  = _tryParse(data['Electrical Conductivity (EC)']);

            if (n != null && p != null && k != null &&
                ph != null && hum != null && ec != null) {
              completer.complete(
                  {'N': n, 'P': p, 'K': k, 'ph': ph, 'humidity': hum, 'ec': ec});
            }
            // all Error 0xE2 → keep waiting for the next broadcast cycle
          } catch (_) {}
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(null);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(null);
        },
        cancelOnError: false,
      );

      return await completer.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    } finally {
      // Always clean up — cancel subscription and close channel
      await sub?.cancel();
      try {
        await channel?.sink.close();
      } catch (_) {}
    }
  }

  double? _tryParse(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.contains('Error')) return null;
    return double.tryParse(s);
  }

  // ---------------------------------------------------------------------------
  // HTTP: POST sensor data → get AI crop recommendations
  // ---------------------------------------------------------------------------
  Future<List<_AiCropResult>> _fetchRecommendations(
      Map<String, double> sensor) async {
    final response = await http
        .post(
          Uri.parse(_kApiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'N': sensor['N'],
            'P': sensor['P'],
            'K': sensor['K'],
            'ph': sensor['ph'],
            'humidity': sensor['humidity'],
            'electrical_conductivity': sensor['ec'],
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception(
          'Recommendation API error (${response.statusCode}): ${response.body}');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final recs = body['recommendations'] as List;

    return recs.map((r) {
      final name = r['crop'] as String;
      final matched = CropRepository.crops
          .where((c) => c.name.toLowerCase() == name.toLowerCase());
      return _AiCropResult(
        cropName: name,
        confidence: r['confidence'] as String,
        reasoning: r['reasoning'] as String,
        matchedCrop: matched.isNotEmpty ? matched.first : null,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Detail bottom sheet
  // ---------------------------------------------------------------------------
  void _showCropDetails(_AiCropResult result) {
    final crop = result.matchedCrop;
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
                if (crop != null)
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.cropName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    _ConfidenceBadge(confidence: result.confidence),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Reasoning',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        result.reasoning,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
                if (crop != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    crop.details,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _detailRow('Water Needs', crop.waterNeeds),
                  _detailRow('Growth Time', crop.growthTime),
                  _detailRow('Expected Yield', crop.expectedYield),
                  _detailRow('Best Soil Type', crop.suitableSoil),
                  _detailRow(
                    'Ideal NPK',
                    '${crop.idealNitrogen}-${crop.idealPhosphorus}-${crop.idealPotassium}',
                  ),
                ],
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
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
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),

            // ---- Soil Analysis Card ----
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

                  // Button
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
                            ? (_statusText.isNotEmpty
                                ? _statusText
                                : 'Reading Sensor...')
                            : 'Start Reading from NPK Sensor',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // Loading indicator
                  if (_isReading) ...[
                    const SizedBox(height: 14),
                    const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ],

                  // Error
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  _SoilValueCard(
                    label: 'Nitrogen (N)',
                    value: _hasReadSensor
                        ? '${_nitrogen.toStringAsFixed(0)} mg/kg'
                        : '--',
                  ),
                  const SizedBox(height: 12),
                  _SoilValueCard(
                    label: 'Phosphorus (P)',
                    value: _hasReadSensor
                        ? '${_phosphorus.toStringAsFixed(0)} mg/kg'
                        : '--',
                  ),
                  const SizedBox(height: 12),
                  _SoilValueCard(
                    label: 'Potassium (K)',
                    value: _hasReadSensor
                        ? '${_potassium.toStringAsFixed(0)} mg/kg'
                        : '--',
                  ),
                  const SizedBox(height: 12),
                  _SoilValueCard(
                    label: 'Soil pH',
                    value: _hasReadSensor
                        ? _ph.toStringAsFixed(2)
                        : '--',
                  ),
                  const SizedBox(height: 12),
                  _SoilValueCard(
                    label: 'Humidity',
                    value: _hasReadSensor
                        ? '${_humidity.toStringAsFixed(1)}%'
                        : '--',
                  ),
                  const SizedBox(height: 12),
                  _SoilValueCard(
                    label: 'Electrical Conductivity (EC)',
                    value: _hasReadSensor
                        ? '${_ec.toStringAsFixed(3)} mS/cm'
                        : '--',
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

            // Placeholder
            if (!_hasReadSensor && !_isReading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  'Press "Start Reading from NPK Sensor" to read your soil sensor and generate AI crop recommendations.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    height: 1.6,
                  ),
                ),
              ),

            // Results
            if (_hasReadSensor)
              ..._results.map(
                (result) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _CropResultCard(
                    result: result,
                    onViewDetails: () => _showCropDetails(result),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Widgets
// =============================================================================

class _SoilValueCard extends StatelessWidget {
  final String label;
  final String value;

  const _SoilValueCard({required this.label, required this.value});

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
            style: const TextStyle(fontSize: 15, color: Color(0xFF64748B)),
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

class _ConfidenceBadge extends StatelessWidget {
  final String confidence;

  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (confidence.toLowerCase()) {
      case 'high':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        break;
      case 'medium':
        bg = const Color(0xFFFEF9C3);
        fg = const Color(0xFF854D0E);
        break;
      default:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${confidence[0].toUpperCase()}${confidence.substring(1)}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _CropResultCard extends StatelessWidget {
  final _AiCropResult result;
  final VoidCallback onViewDetails;

  const _CropResultCard({
    required this.result,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final crop = result.matchedCrop;

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
          // Image (if matched in repository)
          if (crop != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
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
                  child: _ConfidenceBadge(confidence: result.confidence),
                ),
              ],
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + badge (if no image)
                if (crop == null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          result.cropName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      _ConfidenceBadge(confidence: result.confidence),
                    ],
                  )
                else
                  Text(
                    result.cropName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                const SizedBox(height: 10),

                // AI reasoning
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    result.reasoning,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),

                // Crop details (if matched)
                if (crop != null) ...[
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
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
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
                ],

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
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 15, color: Color(0xFF111827)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
