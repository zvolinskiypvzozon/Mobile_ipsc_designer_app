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
