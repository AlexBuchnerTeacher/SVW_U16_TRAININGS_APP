import 'package:flutter/material.dart';
import '../models/training_topic.dart';

class TopicCard extends StatefulWidget {
  final TrainingTopic topic;
  final bool isSelectable;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;

  const TopicCard({
    super.key,
    required this.topic,
    this.isSelectable = false,
    this.isSelected = false,
    this.onSelected,
  });

  @override
  State<TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<TopicCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titelzeile
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              widget.topic.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              widget.topic.description,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            trailing: widget.isSelectable
                ? Checkbox(
                    value: widget.isSelected,
                    onChanged: (value) {
                      if (widget.onSelected != null) {
                        widget.onSelected!(value ?? false);
                      }
                    },
                  )
                : IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
          ),

          // Aufklappbarer Bereich
          if (_isExpanded) _buildExpandedContent(),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Fehlerbilder', widget.topic.errorPatterns),
          const SizedBox(height: 12),
          _buildSection('Lösungen', widget.topic.solutions),
          const SizedBox(height: 12),
          _buildSection('Trainingseinheiten', widget.topic.trainingDrills),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
