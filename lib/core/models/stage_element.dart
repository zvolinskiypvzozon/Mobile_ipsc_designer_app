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
