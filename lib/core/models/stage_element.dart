import 'package:flutter/widgets.dart';

import 'prop_catalog.dart';

enum StageElementType {
  ipscStandart(PropCategory.ipscTargets, 'IPSC Standart', 0.45, 0.80, Color(0xFFFFFFFF)),
  ipscMini(PropCategory.ipscTargets, 'IPSC Mini', 0.30, 0.55, Color(0xFFFFFFFF)),
  nsIpsc(PropCategory.ipscTargets, 'NS IPSC', 0.45, 0.80, Color(0xFFD32F2F)),
  nsIpscMini(PropCategory.ipscTargets, 'NS IPSC Mini', 0.30, 0.55, Color(0xFFD32F2F)),
  ipscMikro(PropCategory.ipscTargets, 'IPSC Mikro', 0.15, 0.46, Color(0xFFFFFFFF)),
  popper(PropCategory.steel, 'Поппер', 0.35, 0.56, Color(0xFFFF9800)),
  miniPopper(PropCategory.steel, 'Мини-поппер', 0.175, 0.4, Color(0xFFFF9800)),
  popperNs(PropCategory.steel, 'Поппер NS', 0.35, 0.8, Color(0xFFD32F2F)),
  popperNsMini(PropCategory.steel, 'Мини-поппер NS', 0.175, 0.4, Color(0xFFD32F2F)),
  roundPlate(PropCategory.steel, 'Круглая тарелка', 0.30, 0.36, Color(0xFFCFD8DC)),
  texasStar(PropCategory.steel, 'Техасская звезда', 1.2, 1.2, Color(0xFFB0BEC5)),
  roundPlateNs(PropCategory.steel, 'Круглая тарелка NS', 0.30, 0.36, Color(0xFFD32F2F)),
  squarePlate(PropCategory.steel, 'Квадратная тарелка', 0.30, 0.36, Color(0xFFCFD8DC)),
  squarePlateNs(PropCategory.steel, 'Квадратная тарелка NS', 0.30, 0.36, Color(0xFFD32F2F)),
  activatorPad(PropCategory.movers, 'Активатор', 0.175, 0.125, Color(0xFFD32F2F)),
  moverTarget(PropCategory.movers, 'Качающаяся мишень', 1.0, 1.0, Color(0xFFFFFFFF)),
  upDownTarget(PropCategory.movers, 'Up-Down', 0.90, 1.50, Color(0xFFFFFFFF)),
  vbBarrel(PropCategory.visualBarriers, 'Бочка', 0.60, 0.90, Color(0xFF2E5E96)),
  vbBarrelDouble(PropCategory.visualBarriers, 'Двойная бочка', 0.45, 0.80, Color(0xFF2E5E96)),
  vbBarrelOpen(PropCategory.visualBarriers, 'Бочка открытая сверху', 0.60, 0.90, Color(0xFF2E5E96)),
  vbBarrier05(PropCategory.visualBarriers, 'Визуальный барьер 0,5×2 м', 0.50, 2.0, Color(0xFFD6DCE5)),
  vbBarrierSq05(PropCategory.visualBarriers, 'Визуальный барьер 0,5×0,5 м', 0.50, 0.50, Color(0xFFD6DCE5)),
  vbBarrier1(PropCategory.visualBarriers, 'Визуальный барьер 1×2 м', 1.0, 2.0, Color(0xFFD6DCE5)),
  vbBarrier2(PropCategory.visualBarriers, 'Визуальный барьер 2×2 м', 2.0, 2.0, Color(0xFFD6DCE5)),
  vbBarrier3(PropCategory.visualBarriers, 'Визуальный барьер 3×2 м', 3.0, 2.0, Color(0xFFD6DCE5)),
  wheelLarge(PropCategory.visualBarriers, 'Колесо большое 1', 0.90, 0.35, Color(0xFF23232A)),
  wheelStack5(PropCategory.visualBarriers, '5 колёс', 0.30, 0.47, Color(0xFF23232A)),
  wheelStack8(PropCategory.visualBarriers, '8 колёс', 0.30, 0.73, Color(0xFF23232A)),
  curtainFrame1(PropCategory.visualBarriers, 'Рама для штор 1×2 м', 1.0, 2.0, Color(0xFFE8ECF2)),
  curtainFrame2(PropCategory.visualBarriers, 'Рама для штор 2×2 м', 2.0, 2.0, Color(0xFFE8ECF2)),
  curtainFrame3(PropCategory.visualBarriers, 'Рама для штор 3×2 м', 3.0, 2.0, Color(0xFFE8ECF2)),
  vbPallet(PropCategory.visualBarriers, 'Поддон', 1.20, 1.0, Color(0xFFC9A66B)),
  wall(PropCategory.barricades, 'Стена', 1.8, 2.0, Color(0xFF4A4A4A)),
  barrier(PropCategory.barricades, 'Барьер', 1.8, 1.1, Color(0xFFFF9800)),
  barrel(PropCategory.barricades, 'Бочка', 0.6, 0.9, Color(0xFFD84315)),
  barrelDouble(PropCategory.barricades, 'Двойная бочка', 0.6, 1.8, Color(0xFFD84315)),
  hayBale(PropCategory.barricades, 'Тючок сена', 1.0, 0.8, Color(0xFFC9B458)),
  sandbagWall(PropCategory.barricades, 'Стена из мешков', 1.2, 0.6, Color(0xFFBDB76B)),
  doorWindowSmall(PropCategory.doorsPorts, 'Декорация с окном 24 дюйма', 1.0, 1.6, Color(0xFF252B36)),
  doorWindowLarge(PropCategory.doorsPorts, 'Дверь с большой панелью', 0.90, 2.0, Color(0xFF252B36)),
  windowPanelWide(PropCategory.doorsPorts, 'Окно с панелью', 1.50, 1.0, Color(0xFF252B36)),
  windowPanelTop(PropCategory.doorsPorts, 'Окно с верхней панелью', 1.50, 1.0, Color(0xFF252B36)),
  stairsRight(PropCategory.doorsPorts, 'Ступени вправо', 1.50, 1.0, Color(0xFFD8CBA9)),
  stairsLeft(PropCategory.doorsPorts, 'Ступени влево', 1.50, 1.0, Color(0xFFD8CBA9)),
  lowStep(PropCategory.doorsPorts, 'Низкая ступень', 1.50, 0.15, Color(0xFFD8CBA9)),
  frameSquare(PropCategory.doorsPorts, 'Рама', 1.0, 1.0, Color(0xFF252B36)),
  portMarked(PropCategory.doorsPorts, 'Порт с меткой', 0.90, 2.0, Color(0xFF4A5568)),
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
