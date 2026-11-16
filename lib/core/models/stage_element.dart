import 'package:flutter/widgets.dart';

import 'prop_catalog.dart';

enum StageElementType {
  paperTarget(PropCategory.paperTargets, 'Paper target', 0.45, 0.75, Color(0xFFFFFFFF)),
  ipscMiniTarget(PropCategory.paperTargets, 'IPSC mini', 0.30, 0.50, Color(0xFFFFFFFF)),
  classicTarget(PropCategory.paperTargets, 'Classic target', 0.45, 0.75, Color(0xFFEFE8DC)),
  classicMiniTarget(PropCategory.paperTargets, 'Classic mini', 0.30, 0.50, Color(0xFFEFE8DC)),
  partialTarget(PropCategory.paperTargets, 'Partial target', 0.45, 0.55, Color(0xFFFFFFFF)),
  noShoot(PropCategory.paperTargets, 'No-shoot', 0.45, 0.75, Color(0xFFF5F5F5)),
  noShootClassic(PropCategory.paperTargets, 'No-shoot classic', 0.45, 0.75, Color(0xFFF5F5F5)),
  noShootMini(PropCategory.paperTargets, 'No-shoot mini', 0.30, 0.50, Color(0xFFF5F5F5)),
  popper(PropCategory.steel, 'Popper', 0.35, 1.0, Color(0xFFFF9800)),
  miniPopper(PropCategory.steel, 'Mini popper', 0.25, 0.75, Color(0xFFFF9800)),
  plate(PropCategory.steel, 'Plate', 0.25, 0.25, Color(0xFFCFD8DC)),
  plateLarge(PropCategory.steel, 'Plate large', 0.40, 0.40, Color(0xFFCFD8DC)),
  plateRack(PropCategory.steel, 'Plate rack', 1.2, 0.9, Color(0xFF90A4AE)),
  texasStar(PropCategory.steel, 'Texas star', 1.2, 1.2, Color(0xFFB0BEC5)),
  spinner(PropCategory.steel, 'Spinner', 0.9, 0.9, Color(0xFFB0BEC5)),
  bowlingPin(PropCategory.steel, 'Bowling pin', 0.19, 0.38, Color(0xFFF5F5F5)),
  knockDownTarget(PropCategory.steel, 'Knock-down target', 0.45, 0.75, Color(0xFFB0BEC5)),
  activatorPad(PropCategory.movers, 'Activator pad', 0.50, 0.35, Color(0xFF9E9E9E)),
  moverTarget(PropCategory.movers, 'Mover target', 0.45, 0.75, Color(0xFFFFFFFF)),
  swingingTarget(PropCategory.movers, 'Swinging target', 0.45, 0.75, Color(0xFFFFFFFF)),
  dropTurner(PropCategory.movers, 'Drop-turner', 0.45, 0.75, Color(0xFFFFFFFF)),
  moverRail(PropCategory.movers, 'Mover rail', 2.0, 0.10, Color(0xFF78909C)),
  hardCoverTarget(PropCategory.hardCoverVision, 'Hard cover', 0.45, 0.75, Color(0xFFFFFFFF)),
  hardCoverPartial(PropCategory.hardCoverVision, 'Hard cover partial', 0.45, 0.55, Color(0xFFFFFFFF)),
  visionBarrier(PropCategory.hardCoverVision, 'Vision barrier', 1.8, 1.1, Color(0xFF90A4AE)),
  visionBarrierNarrow(PropCategory.hardCoverVision, 'Vision barrier narrow', 0.9, 1.1, Color(0xFF90A4AE)),
  wall(PropCategory.barricades, 'Wall', 1.8, 2.0, Color(0xFF4A4A4A)),
  barrier(PropCategory.barricades, 'Barrier', 1.8, 1.1, Color(0xFFFF9800)),
  barrel(PropCategory.barricades, 'Barrel', 0.6, 0.9, Color(0xFFD84315)),
  barrelDouble(PropCategory.barricades, 'Double barrel', 0.6, 1.8, Color(0xFFD84315)),
  hayBale(PropCategory.barricades, 'Hay bale', 1.0, 0.8, Color(0xFFC9B458)),
  sandbagWall(PropCategory.barricades, 'Sandbag wall', 1.2, 0.6, Color(0xFFBDB76B)),
  door(PropCategory.doorsPorts, 'Door', 0.9, 2.0, Color(0xFF795548)),
  doorWithWindow(PropCategory.doorsPorts, 'Door with window', 0.9, 2.0, Color(0xFF795548)),
  widePort(PropCategory.doorsPorts, 'Wide port', 1.5, 1.0, Color(0xFF8D6E63)),
  windowFrame(PropCategory.doorsPorts, 'Window frame', 1.0, 0.6, Color(0xFF8D6E63)),
  portSquare(PropCategory.doorsPorts, 'Square port', 0.6, 0.6, Color(0xFF8D6E63)),
  faultLine(PropCategory.markers, 'Fault line', 3.0, 0.05, Color(0xFFFFEB3B)),
  stopTape(PropCategory.markers, 'Stop tape', 1.5, 0.05, Color(0xFFE53935)),
  dashedLine(PropCategory.markers, 'Dashed line', 1.5, 0.05, Color(0xFFEEEEEE)),
  spMarker(PropCategory.markers, 'SP marker', 0.40, 0.40, Color(0xFF1E88E5)),
  xxMarker(PropCategory.markers, 'XX marker', 0.30, 0.30, Color(0xFFEEEEEE)),
  cone(PropCategory.markers, 'Cone', 0.30, 0.50, Color(0xFFFF7043)),
  redOutline(PropCategory.markers, 'Red outline', 0.45, 0.75, Color(0xFFE53935)),
  shootingPosition(PropCategory.markers, 'Shooting position', 1.0, 1.0, Color(0xFF1E88E5)),
  table(PropCategory.support, 'Table', 1.8, 0.75, Color(0xFF8D6E63)),
  sawhorse(PropCategory.support, 'Sawhorse', 1.2, 0.8, Color(0xFF8D6E63)),
  bench(PropCategory.support, 'Bench', 1.5, 0.45, Color(0xFF8D6E63)),
  pallet(PropCategory.support, 'Pallet', 1.2, 1.0, Color(0xFFA1887F)),
  chair(PropCategory.support, 'Chair', 0.5, 0.9, Color(0xFF6D4C41)),
  stackBoxes(PropCategory.support, 'Boxes', 0.8, 1.0, Color(0xFFA1887F)),
  mannequin(PropCategory.support, 'Mannequin', 0.5, 1.8, Color(0xFF9E9E9E));

  const StageElementType(
    this.category,
    this.label,
    this.width,
    this.height,
    this.color,
  );

  final PropCategory category;
  final String label;
  final double width;
  final double height;
  final Color color;

  Size get defaultSize => Size(width, height);

  PropArchetype get archetype {
    const floorLines = <StageElementType>{
      faultLine,
      stopTape,
      dashedLine,
      moverRail,
    };
    const floorDiscs = <StageElementType>{
      plate,
      plateLarge,
      shootingPosition,
      spMarker,
      xxMarker,
      activatorPad,
    };
    if (floorLines.contains(this)) {
      return PropArchetype.floorLine;
    }
    if (floorDiscs.contains(this)) {
      return PropArchetype.floorDisc;
    }
    return PropArchetype.billboard;
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
