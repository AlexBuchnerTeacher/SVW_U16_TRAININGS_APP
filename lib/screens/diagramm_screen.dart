import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/training_day.dart';

class DiagrammScreen extends StatefulWidget {
  final String userId;

  const DiagrammScreen({super.key, required this.userId});

  @override
  State<DiagrammScreen> createState() => _DiagrammScreenState();
}

class _DiagrammScreenState extends State<DiagrammScreen>
    with SingleTickerProviderStateMixin {
  List<TrainingDay> trainingDays = [];
  Map<String, int> feelingRatings = {};
  Map<String, int> effortRatings = {};
  Map<String, Map<String, bool>> subtaskStatus = {};
  bool isLoading = true;

  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    await Future.wait([
      loadTrainingData(),
      loadFromFirestore(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> loadTrainingData() async {
    final String response =
        await rootBundle.loadString('assets/data/trainingsplan.json');
    final List<dynamic> data = json.decode(response);
    trainingDays = data.map((json) => TrainingDay.fromJson(json)).toList();
  }

  Future<void> loadFromFirestore() async {
    final planRef =
        _firestore.collection('users').doc(widget.userId).collection('plan');
    final snapshot = await planRef.get();

    Map<String, int> feelings = {};
    Map<String, int> efforts = {};
    Map<String, Map<String, bool>> subtasks = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final datum = doc.id;

      feelings[datum] = (data['feeling'] ?? 0) as int;
      efforts[datum] = (data['effort'] ?? 0) as int;
      subtasks[datum] = Map<String, bool>.from(data['subtasks'] ?? {
        "laufen": false,
        "mo5es": false,
        "dehnen": false,
      });
    }

    setState(() {
      feelingRatings = feelings;
      effortRatings = efforts;
      subtaskStatus = subtasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fortschritt'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.black,
                    indicatorWeight: 3,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.black54,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    tabs: const [
                      Tab(text: 'Bewertungen'),
                      Tab(text: 'Training'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBewertungenCharts(),
          _buildTrainingCharts(),
        ],
      ),
    );
  }

  // ----------------- TAB 1: Bewertungen -----------------
  Widget _buildBewertungenCharts() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSingleBewertungChart(
            'Gefühl',
            feelingRatings,
            Colors.green,
          ),
          const SizedBox(height: 24),
          _buildSingleBewertungChart(
            'Anstrengung',
            effortRatings,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBewertungChart(
      String titel, Map<String, int> daten, Color color) {
    final spots = <FlSpot>[];

    for (var i = 0; i < trainingDays.length; i++) {
      final day = trainingDays[i];
      final value = daten[day.datum];
      if (value != null && value > 0) {
        spots.add(FlSpot(i.toDouble(), value.toDouble()));
      }
    }

    final maxY = spots.isEmpty
        ? 10.0
        : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                    getDrawingVerticalLine: (value) =>
                        FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                  ),
                  titlesData: _buildTitlesDataForBewertungen(),
                  lineBarsData: [
                    _buildStepLine(spots, color),
                  ],
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black12),
                  ),
                  minX: 0,
                  maxX: trainingDays.length.toDouble() - 1,
                  minY: 0,
                  maxY: maxY,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- TAB 2: Training -----------------
  Widget _buildTrainingCharts() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildLegendCard(),
        const SizedBox(height: 16),
        _buildTrainingCard('Laufen', Colors.blue),
        const SizedBox(height: 16),
        _buildTrainingCard('Mo5es', Colors.green),
        const SizedBox(height: 16),
        _buildTrainingCard('Dehnen', Colors.orange),
      ],
    );
  }

  Widget _buildTrainingCard(String art, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              art,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(height: 120, child: _buildSingleTrainingChart(art, color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleTrainingChart(String art, Color color) {
    final sollSpots = <FlSpot>[];
    final istSpots = <FlSpot>[];

    double sumSoll = 0;
    double sumIst = 0;

    for (var i = 0; i < trainingDays.length; i++) {
      final day = trainingDays[i];
      final status = subtaskStatus[day.datum] ?? {};

      if (art == 'Laufen' && day.laufDauer != null) {
        sumSoll += day.laufDauer!.toDouble();
        if (status['laufen'] == true) sumIst += day.laufDauer!.toDouble();
      } else if (art == 'Mo5es' && day.mo5es) {
        sumSoll += 30;
        if (status['mo5es'] == true) sumIst += 30;
      } else if (art == 'Dehnen') {
        sumSoll += 20;
        if (status['dehnen'] == true) sumIst += 20;
      }

      sollSpots.add(FlSpot(i.toDouble(), sumSoll));
      istSpots.add(FlSpot(i.toDouble(), sumIst));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey[200]!, strokeWidth: 1),
          getDrawingVerticalLine: (value) =>
              FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        titlesData: _buildTitlesDataForTraining(),
        lineBarsData: [
          _buildStepLine(sollSpots, color.withValues(alpha: 0.3)),
          _buildStepLine(istSpots, color),
        ],
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.black12),
        ),
        minX: 0,
        maxX: trainingDays.length.toDouble() - 1,
        minY: 0,
        maxY: _getMaxY([sollSpots, istSpots]),
      ),
    );
  }

  // ----------------- Helper -----------------
  LineChartBarData _buildStepLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: color,
      barWidth: 3,
      dotData: FlDotData(show: false),
    );
  }

  Widget _buildLegendCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _legendDot(Colors.grey.shade300, 'Soll'),
            const SizedBox(width: 24),
            _legendDot(Colors.black54, 'Ist'),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // --------- Titel-Daten für Achsen ---------
  FlTitlesData _buildTitlesDataForBewertungen() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          interval: 1,
          getTitlesWidget: (value, meta) => Text(
            value.toInt().toString(),
            style: const TextStyle(
                fontSize: 10, color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          interval: 1,
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= 0 && value.toInt() < trainingDays.length) {
              return Text(
                trainingDays[value.toInt()].datum,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.w600),
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

  FlTitlesData _buildTitlesDataForTraining() {
    return FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          interval: 1,
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= 0 && value.toInt() < trainingDays.length) {
              return Text(
                trainingDays[value.toInt()].datum,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.w600),
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

  double _getMaxY(List<List<FlSpot>> allSpots) {
    double maxVal = 0;
    for (var list in allSpots) {
      for (var spot in list) {
        if (spot.y > maxVal) maxVal = spot.y;
      }
    }
    return maxVal + 10;
  }
}
