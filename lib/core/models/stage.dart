import 'package:flutter/widgets.dart';

import 'stage_element.dart';

@immutable
class Stage {
  const Stage({
    required this.id,
    required this.title,
    this.elements = const <StageElement>[],
  });

  final String id;
  final String title;
  final List<StageElement> elements;

  factory Stage.fromRows(
    Map<String, dynamic> stageRow,
    List<Map<String, dynamic>> elementRows,
  ) {
    return Stage(
      id: stageRow['id'] as String,
      title: stageRow['title'] as String,
      elements: elementRows
          .map(_elementFromRowOrNull)
          .whereType<StageElement>()
          .toList(),
    );
  }

  static StageElement? _elementFromRowOrNull(Map<String, dynamic> row) {
    try {
      return StageElement.fromRow(row);
    } on ArgumentError {
      return null;
    }
  }

  Stage copyWith({
    String? id,
    String? title,
    List<StageElement>? elements,
  }) {
    return Stage(
      id: id ?? this.id,
      title: title ?? this.title,
      elements: elements ?? this.elements,
    );
  }
}
