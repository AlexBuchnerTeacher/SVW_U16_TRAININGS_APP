import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/training_day.dart';

class DiagrammScreen extends StatefulWidget {
  final String userId; // Neu: Spieler-UID vom MainScreen

  const DiagrammScreen({super.key, required this.userId});

  @override
  State<DiagrammScreen> createState() => _DiagrammScreenState();
}

class _DiagrammScreenState extends State<DiagrammScreen>
    with SingleTickerProviderStateMixin {
  List<TrainingDay> trainingDays = [];
  Map<String, int> feelingRatings = {};
  Map<String, int> effortRatings = {};
  bool isLoading = true;

  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadData();
  }

  Future<void> loadData() async {
    await loadTrainingData();
    await loadFromFirestore();
    setState(() => isLoading = false);
  }

  Future<void> loadTrainingData() async {
    final String response =
        await rootBundle.loadString('assets/data/trainingsplan.json');
    final List<dynamic> data = json.decode(response);
    trainingDays = data.map((json) => TrainingDay.fromJson(json)).toList();
  }

  Future<void> loadFromFirestore() async {
    final planRef = _firestore.collection('users').doc(widget.userId).collection('plan');
    final snapshot = await planRef.get();

    Map<String, int> feelings = {};
    Map<String, int> efforts = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final datum = doc.id;

      feelings[datum] = (data['feeling'] ?? 0) as int;
      efforts[datum] = (data['effort'] ?? 0) as int;
    }

    setState(() {
      feelingRatings = feelings;
      effortRatings = efforts;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fortschritt'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepPurple,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Bewertungen'),
            Tab(text: 'Training'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBewertungenChart(),
          _buildTrainingChart(),
        ],
      ),
    );
  }

  // --- Diagramm 1: Gefühl & Anstrengung ---
  Widget _buildBewertungenChart() {
    final spotsFeeling = <FlSpot>[];
    final spotsEffort = <FlSpot>[];

    for (var i = 0; i < trainingDays.length; i++) {
      final day = trainingDays[i];
      final feeling = feelingRatings[day.datum] ?? 0;
      final effort = effortRatings[day.datum] ?? 0;

      spotsFeeling.add(FlSpot(i.toDouble(), feeling.toDouble()));
      spotsEffort.add(FlSpot(i.toDouble(), effort.toDouble()));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegend([
            {'color': Colors.black, 'label': 'Gefühl'},
            {'color': Colors.redAccent, 'label': 'Anstrengung'},
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                  getDrawingVerticalLine: (value) =>
                      FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                ),
                titlesData: _buildTitlesData(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spotsFeeling,
                    isCurved: true,
                    color: Colors.black,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: spotsEffort,
                    isCurved: true,
                    color: Colors.redAccent,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.black12),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final label = spot.bar.color == Colors.black
                            ? 'Gefühl'
                            : 'Anstrengung';
                        return LineTooltipItem(
                          '$label\nTag ${spot.x.toInt() + 1}: ${spot.y.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                minX: 0,
                maxX: trainingDays.length.toDouble() - 1,
                minY: 0,
                maxY: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Diagramm 2: Trainingsprogression ---
  Widget _buildTrainingChart() {
    final spotsGA = <FlSpot>[];
    final spotsFahrtspiel = <FlSpot>[];
    final spotsIntervalle = <FlSpot>[];

    for (var i = 0; i < trainingDays.length; i++) {
      final day = trainingDays[i];
      if (day.laufart == 'Grundlagenausdauer') {
        spotsGA.add(FlSpot(i.toDouble(), (day.laufDauer ?? 0).toDouble()));
      } else if (day.laufart == 'Fahrtspiel') {
        spotsFahrtspiel.add(FlSpot(i.toDouble(), (day.fahrtspielDauer ?? 0).toDouble()));
      } else if (day.laufart == 'Intervalle') {
        spotsIntervalle.add(
            FlSpot(i.toDouble(), (day.intervalleSprints ?? 0).toDouble()));
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegend([
            {'color': Colors.black, 'label': 'Grundlagenausdauer'},
            {'color': Colors.blueAccent, 'label': 'Fahrtspiel'},
            {'color': Colors.green, 'label': 'Intervalle'},
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                  getDrawingVerticalLine: (value) =>
                      FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                ),
                titlesData: _buildTitlesData(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spotsGA,
                    isCurved: true,
                    color: Colors.black,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: spotsFahrtspiel,
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: spotsIntervalle,
                    isCurved: true,
                    color: Colors.green[700],
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.black12),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        String label;
                        if (spot.bar.color == Colors.black) {
                          label = 'Grundlagenausdauer';
                        } else if (spot.bar.color == Colors.blueAccent) {
                          label = 'Fahrtspiel';
                        } else {
                          label = 'Intervalle';
                        }
                        return LineTooltipItem(
                          '$label\nTag ${spot.x.toInt() + 1}: ${spot.y.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                minX: 0,
                maxX: trainingDays.length.toDouble() - 1,
                minY: 0,
                maxY: _getMaxY(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Legende
  Widget _buildLegend(List<Map<String, dynamic>> items) {
    return Row(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: item['color'],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                item['label'],
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Achsentitel
  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          interval: 1,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          interval: 1,
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= 0 && value.toInt() < trainingDays.length) {
              return Text(
                trainingDays[value.toInt()].datum,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  double _getMaxY() {
    double maxVal = 0;
    for (var day in trainingDays) {
      if ((day.laufDauer ?? 0) > maxVal) maxVal = day.laufDauer?.toDouble() ?? 0;
      if ((day.fahrtspielDauer ?? 0) > maxVal) {
        maxVal = day.fahrtspielDauer?.toDouble() ?? 0;
      }
      if ((day.intervalleSprints ?? 0) > maxVal) {
        maxVal = day.intervalleSprints?.toDouble() ?? 0;
      }
    }
    return maxVal + 5;
  }
}
