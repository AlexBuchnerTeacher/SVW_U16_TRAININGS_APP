import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/training_topic.dart';
import '../widgets/topic_card.dart';

class TopicsScreen extends StatefulWidget {
  final String userId; // Spieler-UID vom MainScreen

  const TopicsScreen({super.key, required this.userId});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  List<TrainingTopic> topics = [];
  Set<String> selectedTopics = {};
  bool isLoading = true;

  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadPredefinedTopics();
    await _loadSelectedTopicsFromFirestore();
    setState(() {
      isLoading = false;
    });
  }

  // Themen aus JSON laden
  Future<void> _loadPredefinedTopics() async {
    final String response =
        await rootBundle.loadString('assets/data/training_topics.json');
    final List<dynamic> data = json.decode(response);
    topics = data.map((json) => TrainingTopic.fromJson(json)).toList();
  }

  // Auswahl aus Firestore laden
  Future<void> _loadSelectedTopicsFromFirestore() async {
    final docRef = _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('meta')
        .doc('topics');
    final doc = await docRef.get();
    if (doc.exists) {
      final data = doc.data()!;
      selectedTopics = Set<String>.from(data['selectedTopics'] ?? []);
    }
  }

  Future<void> _saveSelectedTopicsToFirestore() async {
    final docRef = _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('meta')
        .doc('topics');
    await docRef.set({
      'selectedTopics': selectedTopics.toList(),
    });
  }

  void _toggleTopic(String topicId, bool isDone) {
    setState(() {
      if (isDone) {
        selectedTopics.add(topicId);
      } else {
        selectedTopics.remove(topicId);
      }
    });
    _saveSelectedTopicsToFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainingsthemen'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return TopicCard(
                  topic: topic,
                  isDone: selectedTopics.contains(topic.id.toString()),
                  onChanged: (value) {
                    _toggleTopic(topic.id.toString(), value);
                  },
                );
              },
            ),
    );
  }
}
