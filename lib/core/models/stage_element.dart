import 'package:flutter/widgets.dart';

import 'prop_catalog.dart';

enum StageElementType {
  ipscStandart(PropCategory.ipscTargets, 'IPSC Standart', 0.45, 0.80, Color(0xFFFFFFFF)),
  ipscMini(PropCategory.ipscTargets, 'IPSC Mini', 0.30, 0.55, Color(0xFFFFFFFF)),
  nsIpsc(PropCategory.ipscTargets, 'NS IPSC', 0.45, 0.80, Color(0xFFD32F2F)),
  nsIpscMini(PropCategory.ipscTargets, 'NS IPSC Mini', 0.30, 0.55, Color(0xFFD32F2F)),
  ipscMikro(PropCategory.ipscTargets, 'IPSC Mikro', 0.15, 0.275, Color(0xFFFFFFFF)),
  popper(PropCategory.steel, 'Поппер', 0.35, 0.8, Color(0xFFFF9800)),
  miniPopper(PropCategory.steel, 'Мини-поппер', 0.175, 0.4, Color(0xFFFF9800)),
  popperNs(PropCategory.steel, 'Поппер NS', 0.35, 0.8, Color(0xFFD32F2F)),
  popperNsMini(PropCategory.steel, 'Мини-поппер NS', 0.175, 0.4, Color(0xFFD32F2F)),
  roundPlate(PropCategory.steel, 'Круглая тарелка', 0.30, 0.36, Color(0xFFCFD8DC)),
  texasStar(PropCategory.steel, 'Техасская звезда', 1.2, 1.2, Color(0xFFB0BEC5)),
  roundPlateNs(PropCategory.steel, 'Круглая тарелка NS', 0.30, 0.36, Color(0xFFD32F2F)),
  squarePlate(PropCategory.steel, 'Квадратная тарелка', 0.30, 0.36, Color(0xFFCFD8DC)),
  squarePlateNs(PropCategory.steel, 'Квадратная тарелка NS', 0.30, 0.36, Color(0xFFD32F2F)),
  activatorPad(PropCategory.movers, 'Активатор', 0.35, 0.25, Color(0xFFD32F2F)),
  moverTarget(PropCategory.movers, 'Движущаяся мишень', 1.0, 1.0, Color(0xFFFFFFFF)),
  upDownTarget(PropCategory.movers, 'Up-Down', 0.45, 0.75, Color(0xFFFFFFFF)),
  hardCoverTarget(PropCategory.hardCoverVision, 'Хард-кавер', 0.45, 0.75, Color(0xFFFFFFFF)),
  hardCoverPartial(PropCategory.hardCoverVision, 'Хард-кавер частичный', 0.45, 0.55, Color(0xFFFFFFFF)),
  visionBarrier(PropCategory.hardCoverVision, 'Визион-барьер', 1.8, 1.1, Color(0xFF90A4AE)),
  visionBarrierNarrow(PropCategory.hardCoverVision, 'Узкий визион-барьер', 0.9, 1.1, Color(0xFF90A4AE)),
  wall(PropCategory.barricades, 'Стена', 1.8, 2.0, Color(0xFF4A4A4A)),
  barrier(PropCategory.barricades, 'Барьер', 1.8, 1.1, Color(0xFFFF9800)),
  barrel(PropCategory.barricades, 'Бочка', 0.6, 0.9, Color(0xFFD84315)),
  barrelDouble(PropCategory.barricades, 'Двойная бочка', 0.6, 1.8, Color(0xFFD84315)),
  hayBale(PropCategory.barricades, 'Тючок сена', 1.0, 0.8, Color(0xFFC9B458)),
  sandbagWall(PropCategory.barricades, 'Стена из мешков', 1.2, 0.6, Color(0xFFBDB76B)),
  door(PropCategory.doorsPorts, 'Дверь', 0.9, 2.0, Color(0xFF795548)),
  doorWithWindow(PropCategory.doorsPorts, 'Дверь с окном', 0.9, 2.0, Color(0xFF795548)),
  widePort(PropCategory.doorsPorts, 'Широкий порт', 1.5, 1.0, Color(0xFF8D6E63)),
  windowFrame(PropCategory.doorsPorts, 'Оконная рама', 1.0, 0.6, Color(0xFF8D6E63)),
  portSquare(PropCategory.doorsPorts, 'Квадратный порт', 0.6, 0.6, Color(0xFF8D6E63)),
  faultLine(PropCategory.markers, 'Линия штрафных', 3.0, 0.05, Color(0xFFFFEB3B)),
  stopTape(PropCategory.markers, 'Стоп-лента', 1.5, 0.05, Color(0xFFE53935)),
  dashedLine(PropCategory.markers, 'Пунктирная линия', 1.5, 0.05, Color(0xFFEEEEEE)),
  spMarker(PropCategory.markers, 'Маркер SP', 0.40, 0.40, Color(0xFF1E88E5)),
  xxMarker(PropCategory.markers, 'Маркер XX', 0.30, 0.30, Color(0xFFEEEEEE)),
  cone(PropCategory.markers, 'Конус', 0.30, 0.50, Color(0xFFFF7043)),
  redOutline(PropCategory.markers, 'Красный контур', 0.45, 0.75, Color(0xFFE53935)),
  shootingPosition(PropCategory.markers, 'Огневой рубеж', 1.0, 1.0, Color(0xFF1E88E5)),
  table(PropCategory.support, 'Стол', 1.8, 0.75, Color(0xFF8D6E63)),
  sawhorse(PropCategory.support, 'Козлы', 1.2, 0.8, Color(0xFF8D6E63)),
  bench(PropCategory.support, 'Скамья', 1.5, 0.45, Color(0xFF8D6E63)),
  pallet(PropCategory.support, 'Паллета', 1.2, 1.0, Color(0xFFA1887F)),
  chair(PropCategory.support, 'Стул', 0.5, 0.9, Color(0xFF6D4C41)),
  stackBoxes(PropCategory.support, 'Коробки', 0.8, 1.0, Color(0xFFA1887F)),
  mannequin(PropCategory.support, 'Манекен', 0.5, 1.8, Color(0xFF9E9E9E));

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
    };
    const floorDiscs = <StageElementType>{
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
