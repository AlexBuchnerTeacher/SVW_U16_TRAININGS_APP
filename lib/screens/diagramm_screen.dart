import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_day.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fl_chart/fl_chart.dart';

class DiagrammScreen extends StatefulWidget {
  const DiagrammScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadData();
  }

  Future<void> loadData() async {
    await loadTrainingData();
    await loadPreferences();
    setState(() => isLoading = false);
  }

  // Trainingsdaten laden
  Future<void> loadTrainingData() async {
    final String response =
        await rootBundle.loadString('assets/data/trainingsplan.json');
    final List<dynamic> data = json.decode(response);
    trainingDays = data.map((json) => TrainingDay.fromJson(json)).toList();
  }

  // Ratings laden
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    feelingRatings = _decodeIntMap(prefs.getString('feelingRatings'));
    effortRatings = _decodeIntMap(prefs.getString('effortRatings'));
  }

  Map<String, int> _decodeIntMap(String? data) {
    return data != null ? Map<String, int>.from(json.decode(data)) : {};
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
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey[300]!, strokeWidth: 1),
            getDrawingVerticalLine: (value) =>
                FlLine(color: Colors.grey[300]!, strokeWidth: 1),
          ),
          titlesData: _buildTitlesData(),
          lineBarsData: [
            LineChartBarData(
              spots: spotsFeeling,
              isCurved: true,
              color: Colors.black,
              barWidth: 3,
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: spotsEffort,
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 3,
              belowBarData: BarAreaData(show: false),
            ),
          ],
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.black12),
          ),
          minX: 0,
          maxX: trainingDays.length.toDouble() - 1,
          minY: 0,
          maxY: 5,
        ),
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
        spotsFahrtspiel
            .add(FlSpot(i.toDouble(), (day.fahrtspielDauer ?? 0).toDouble()));
      } else if (day.laufart == 'Intervalle') {
        spotsIntervalle.add(
            FlSpot(i.toDouble(), (day.intervalleSprints ?? 0).toDouble()));
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey[300]!, strokeWidth: 1),
            getDrawingVerticalLine: (value) =>
                FlLine(color: Colors.grey[300]!, strokeWidth: 1),
          ),
          titlesData: _buildTitlesData(),
          lineBarsData: [
            LineChartBarData(
              spots: spotsGA,
              isCurved: true,
              color: Colors.black,
              barWidth: 3,
              belowBarData: BarAreaData(show: false),
              dotData: FlDotData(show: true),
            ),
            LineChartBarData(
              spots: spotsFahrtspiel,
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 3,
              belowBarData: BarAreaData(show: false),
              dotData: FlDotData(show: true),
            ),
            LineChartBarData(
              spots: spotsIntervalle,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              belowBarData: BarAreaData(show: false),
              dotData: FlDotData(show: true),
            ),
          ],
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.black12),
          ),
          minX: 0,
          maxX: trainingDays.length.toDouble() - 1,
          minY: 0,
          maxY: _getMaxY(),
        ),
      ),
    );
  }

  // Titel (Achsenbeschriftungen)
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
              style: const TextStyle(fontSize: 10),
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
                style: const TextStyle(fontSize: 10),
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

  // MaxY berechnen für Trainingswerte (damit Diagramm nicht abgeschnitten ist)
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
    return maxVal + 5; // etwas Puffer
  }
}
