import 'package:flutter/widgets.dart';

enum StageElementType {
  paperTarget,
  popper,
  plate,
  noShoot,
  wall,
  barrier,
  faultLine,
  shootingPosition,
}

extension StageElementTypeLabel on StageElementType {
  String get label {
    switch (this) {
      case StageElementType.paperTarget:
        return 'Paper target';
      case StageElementType.popper:
        return 'Popper';
      case StageElementType.plate:
        return 'Plate';
      case StageElementType.noShoot:
        return 'No-shoot';
      case StageElementType.wall:
        return 'Wall';
      case StageElementType.barrier:
        return 'Barrier';
      case StageElementType.faultLine:
        return 'Fault line';
      case StageElementType.shootingPosition:
        return 'Shooting position';
    }
  }

  Size get defaultSize {
    switch (this) {
      case StageElementType.paperTarget:
        return const Size(0.45, 0.75);
      case StageElementType.popper:
        return const Size(0.35, 1.0);
      case StageElementType.plate:
        return const Size(0.25, 0.25);
      case StageElementType.noShoot:
        return const Size(0.45, 0.75);
      case StageElementType.wall:
        return const Size(2.4, 2.2);
      case StageElementType.barrier:
        return const Size(2.4, 2.0);
      case StageElementType.faultLine:
        return const Size(3.0, 0.05);
      case StageElementType.shootingPosition:
        return const Size(1.0, 1.0);
    }
  }
}

@immutable
class StageElement {
  const StageElement({
    required this.id,
    required this.type,
    required this.position,
    this.rotation = 0,
    this.width = 1,
    this.height = 1,
  });

  final String id;
  final StageElementType type;
  final Offset position;
  final double rotation;
  final double width;
  final double height;

  factory StageElement.fromRow(Map<String, dynamic> row) {
    return StageElement(
      id: row['id'] as String,
      type: StageElementType.values.byName(row['type'] as String),
      position: Offset(
        (row['position_x'] as num).toDouble(),
        (row['position_y'] as num).toDouble(),
      ),
      rotation: (row['rotation'] as num?)?.toDouble() ?? 0,
      width: (row['width'] as num?)?.toDouble() ?? 1,
      height: (row['height'] as num?)?.toDouble() ?? 1,
    );
  }

  Map<String, dynamic> toRow({
    required String stageId,
    required int sortOrder,
  }) {
    return <String, dynamic>{
      'id': id,
      'stage_id': stageId,
      'type': type.name,
      'position_x': position.dx,
      'position_y': position.dy,
      'rotation': rotation,
      'width': width,
      'height': height,
      'sort_order': sortOrder,
    };
  }

  Rect get bounds => Rect.fromCenter(
        center: position,
        width: width,
        height: height,
      );

  StageElement copyWith({
    String? id,
    StageElementType? type,
    Offset? position,
    double? rotation,
    double? width,
    double? height,
  }) {
    return StageElement(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
