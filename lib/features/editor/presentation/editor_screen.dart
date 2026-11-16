import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/prop_catalog.dart';
import '../../../core/models/stage.dart';
import '../../../core/models/stage_element.dart';
import '../../stage_library/providers/stages_provider.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  static const _uuid = Uuid();

  late Stage _stage;
  bool _stageInitialized = false;
  String? _selectedElementId;
  bool _saving = false;
  StageElementType? _armedTool;
  bool _draggingElement = false;
  (double, double)? _drawStart;
  (double, double)? _drawCurrent;
  Offset _lastDelta = Offset.zero;

  @override
  void dispose() {
    super.dispose();
  }

  void _ensureStage(BuildContext context) {
    if (_stageInitialized) {
      return;
    }
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Stage) {
      _stage = args;
    } else {
      _stage = Stage(id: _uuid.v4(), title: 'New stage');
    }
    _stageInitialized = true;
  }

  StageElement? get _selectedElement {
    for (final element in _stage.elements) {
      if (element.id == _selectedElementId) {
        return element;
      }
    }
    return null;
  }

  void _updateStage(Stage stage) {
    setState(() => _stage = stage);
  }

  void _updateElement(StageElement element) {
    _updateStage(_stage.copyWith(elements: <StageElement>[
      for (final existing in _stage.elements)
        if (existing.id == element.id) element else existing,
    ]));
  }

  void _placeElement(StageElementType type, double x, double y) {
    final size = type.defaultSize;
    final element = StageElement(
      id: _uuid.v4(),
      type: type,
      position: Offset(x, y),
      width: size.width,
      height: size.height,
    );
    _updateStage(_stage.copyWith(
      elements: <StageElement>[..._stage.elements, element],
    ));
    setState(() => _selectedElementId = element.id);
  }

  void _deleteSelected() {
    final selected = _selectedElementId;
    if (selected == null) {
      return;
    }
    _updateStage(_stage.copyWith(
      elements: <StageElement>[
        for (final element in _stage.elements)
          if (element.id != selected) element,
      ],
    ));
    setState(() => _selectedElementId = null);
  }

  Future<void> _renameStage() async {
    final controller = TextEditingController(text: _stage.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Rename stage'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (newTitle == null || newTitle.isEmpty) {
      return;
    }
    _updateStage(_stage.copyWith(title: newTitle));
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(stagesProvider.notifier).save(_stage);
      messenger.showSnackBar(const SnackBar(content: Text('Stage saved')));
      navigator.pop();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Save failed: $error')),
      );
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  IconData _categoryIcon(PropCategory category) {
    switch (category) {
      case PropCategory.paperTargets:
        return Icons.adjust;
      case PropCategory.steel:
        return Icons.disc_full;
      case PropCategory.movers:
        return Icons.swap_horiz;
      case PropCategory.hardCoverVision:
        return Icons.visibility_off;
      case PropCategory.barricades:
        return Icons.foundation;
      case PropCategory.doorsPorts:
        return Icons.door_front_door;
      case PropCategory.markers:
        return Icons.timeline;
      case PropCategory.support:
        return Icons.chair;
    }
  }

  Future<void> _openToolsMenu() async {
    final selected = await showModalBottomSheet<StageElementType>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480),
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Prop library',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
                for (final category in PropCategory.values) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Text(
                      '${category.label} '
                      '(${StageElementType.values.where((t) => t.category == category).length})',
                      style: Theme.of(sheetContext)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            color:
                                Theme.of(sheetContext).colorScheme.primary,
                          ),
                    ),
                  ),
                  for (final type in StageElementType.values)
                    if (type.category == category)
                      ListTile(
                        dense: true,
                        leading: Icon(_categoryIcon(category)),
                        title: Text(type.label),
                        onTap: () => Navigator.of(sheetContext).pop(type),
                      ),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Place ${selected.label}'),
          content: Text(
            selected.archetype == PropArchetype.floorLine
                ? 'Draw it by dragging on the gallery floor.'
                : 'Tap the gallery floor to place it. '
                    'The tool stays active until you finish it.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Place'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      setState(() {
        _armedTool = selected;
        _selectedElementId = null;
      });
    }
  }

  String? _hitTestElement(_Perspective p, Offset point) {
    final candidates = <StageElement>[..._stage.elements];
    candidates.sort((a, b) => b.position.dy.compareTo(a.position.dy));
    for (final element in candidates) {
      final spec = element.type;
      final d = p.dOf(element.position.dy);
      final base = p.floorPoint(element.position.dx, element.position.dy);
      if (spec.archetype == PropArchetype.floorLine) {
        final rot = element.rotation * math.pi / 180;
        final dx = math.cos(rot) * element.width / 2;
        final dy = math.sin(rot) * element.width / 2;
        final a = p.floorPoint(
          element.position.dx - dx,
          element.position.dy - dy,
        );
        final b = p.floorPoint(
          element.position.dx + dx,
          element.position.dy + dy,
        );
        if (_distanceToSegment(point, a, b) < 10) {
          return element.id;
        }
        continue;
      }
      if (spec.archetype == PropArchetype.floorDisc) {
        final radius = math.max(p.widthPx(element.width / 2, d), 8.0);
        if ((point - base).distance <= radius) {
          return element.id;
        }
        continue;
      }
      final w = math.max(p.widthPx(element.width, d), 12.0);
      final h = math.max(p.heightPx(element.height, d), 16.0);
      final rect = Rect.fromLTWH(base.dx - w / 2, base.dy - h, w, h);
      if (rect.contains(point)) {
        return element.id;
      }
    }
    return null;
  }

  double _distanceToSegment(Offset point, Offset a, Offset b) {
    final ab = b - a;
    final ap = point - a;
    final lengthSquared = ab.distanceSquared;
    if (lengthSquared == 0) {
      return ap.distance;
    }
    final t =
        ((ap.dx * ab.dx + ap.dy * ab.dy) / lengthSquared).clamp(0.0, 1.0);
    return (point - a - ab * t).distance;
  }

  void _onTapUp(Offset local, Size size) {
    final p = _Perspective(size);
    if (_armedTool != null) {
      if (_armedTool!.archetype == PropArchetype.floorLine) {
        return;
      }
      final floor = p.floorFromScreen(local);
      if (floor == null) {
        return;
      }
      _placeElement(_armedTool!, floor.$1, floor.$2);
      return;
    }
    setState(() => _selectedElementId = _hitTestElement(p, local));
  }

  void _onPanStart(Offset local, Size size) {
    if (_armedTool != null &&
        _armedTool!.archetype == PropArchetype.floorLine) {
      final p = _Perspective(size);
      _drawStart = p.floorFromScreen(local);
      _drawCurrent = _drawStart;
      setState(() {});
      return;
    }
    final p = _Perspective(size);
    final hit = _hitTestElement(p, local);
    setState(() {
      _selectedElementId = hit;
      _draggingElement = hit != null;
    });
  }

  void _onPanUpdate(Offset local, Size size) {
    if (_armedTool != null &&
        _armedTool!.archetype == PropArchetype.floorLine) {
      if (_drawStart == null) {
        return;
      }
      final p = _Perspective(size);
      setState(() => _drawCurrent = p.floorFromScreen(local) ?? _drawCurrent);
      return;
    }
    if (!_draggingElement) {
      return;
    }
    final element = _selectedElement;
    if (element == null) {
      return;
    }
    final p = _Perspective(size);
    final d = p.dOf(element.position.dy);
    final baseY = p.floorPoint(element.position.dx, element.position.dy).dy;
    final newBaseY = baseY + _lastDelta.dy;
    final dy = newBaseY - p.horizonY;
    double newY = element.position.dy;
    if (dy > 1) {
      final newD = p.kv * _Perspective.camHeight / dy;
      newY = (_Perspective.camDepth - newD).clamp(0.0, _Perspective.nearY);
    }
    final newX = (element.position.dx + _lastDelta.dx * d / p.kx).clamp(
      -_Perspective.stageHalfWidth,
      _Perspective.stageHalfWidth,
    );
    _updateElement(element.copyWith(position: Offset(newX, newY)));
  }

  void _onPanEnd() {
    if (_armedTool != null &&
        _armedTool!.archetype == PropArchetype.floorLine) {
      final start = _drawStart;
      final current = _drawCurrent;
      if (start != null && current != null) {
        final dx = current.$1 - start.$1;
        final dy = current.$2 - start.$2;
        final length = math.sqrt(dx * dx + dy * dy);
        if (length >= 0.5) {
          final element = StageElement(
            id: _uuid.v4(),
            type: _armedTool!,
            position: Offset(
              (start.$1 + current.$1) / 2,
              (start.$2 + current.$2) / 2,
            ),
            rotation: math.atan2(dy, dx) * 180 / math.pi,
            width: length,
            height: _armedTool!.height,
          );
          _updateStage(_stage.copyWith(
            elements: <StageElement>[..._stage.elements, element],
          ));
        }
      }
      setState(() {
        _drawStart = null;
        _drawCurrent = null;
      });
      return;
    }
    setState(() => _draggingElement = false);
  }

  Widget _buildModeBanner() {
    final tool = _armedTool!;
    final hint = tool.archetype == PropArchetype.floorLine
        ? 'drag on the floor to draw'
        : 'tap the floor to place';
    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Placing: ${tool.label} — $hint'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Finish placing',
            onPressed: () => setState(() {
              _armedTool = null;
              _drawStart = null;
              _drawCurrent = null;
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureStage(context);
    final selected = _selectedElement;
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _renameStage,
          child: Text(_stage.title),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.construction),
            tooltip: 'Tools',
            onPressed: _openToolsMenu,
          ),
          if (selected != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete element',
              onPressed: _deleteSelected,
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Rename',
            onPressed: _renameStage,
          ),
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final size = constraints.biggest;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (TapUpDetails details) =>
                      _onTapUp(details.localPosition, size),
                  onPanStart: (DragStartDetails details) =>
                      _onPanStart(details.localPosition, size),
                  onPanUpdate: (DragUpdateDetails details) {
                    _lastDelta = details.delta;
                    _onPanUpdate(details.localPosition, size);
                  },
                  onPanEnd: (DragEndDetails details) => _onPanEnd(),
                  child: CustomPaint(
                    size: size,
                    painter: _GalleryPainter3D(
                      elements: _stage.elements,
                      selectedId: _selectedElementId,
                      previewStart: _drawStart,
                      previewEnd: _drawCurrent,
                    ),
                  ),
                );
              },
            ),
          ),
          if (_armedTool != null) _buildModeBanner(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Perspective {
  _Perspective(this.size);

  final Size size;

  static const double camHeight = 1.7;
  static const double camDepth = 52;
  static const double stageHalfWidth = 20;
  static const double corridorHalfWidth = 17;
  static const double farY = 5;
  static const double nearY = 50;
  static const double bermHeight = 2.5;

  double get horizonY => size.height * 0.14;
  double get floorNearY => size.height * 0.96;
  double get kv => (floorNearY - horizonY) * 2 / camHeight;
  double get kx => size.width * 0.2;

  double dOf(double y) => camDepth - y;

  double screenYFromD(double d) => horizonY + kv * camHeight / d;

  Offset floorPoint(double x, double y) {
    final d = dOf(y);
    return Offset(size.width / 2 + kx * x / d, screenYFromD(d));
  }

  (double, double)? floorFromScreen(Offset point) {
    final dy = point.dy - horizonY;
    if (dy <= 1) {
      return null;
    }
    final d = kv * camHeight / dy;
    final y = camDepth - d;
    if (y < 0 || y > nearY) {
      return null;
    }
    final x = (point.dx - size.width / 2) * d / kx;
    if (x < -stageHalfWidth || x > stageHalfWidth) {
      return null;
    }
    return (x, y);
  }

  double heightPx(double meters, double d) => kv * meters / d;

  double widthPx(double meters, double d) => kx * meters / d;
}

class _GalleryPainter3D extends CustomPainter {
  _GalleryPainter3D({
    required this.elements,
    required this.selectedId,
    this.previewStart,
    this.previewEnd,
  });

  final List<StageElement> elements;
  final String? selectedId;
  final (double, double)? previewStart;
  final (double, double)? previewEnd;

  @override
  void paint(Canvas canvas, Size size) {
    final p = _Perspective(size);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF7A6A52),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, p.horizonY),
      Paint()..color = const Color(0xFF5F5140),
    );

    final dFar = p.dOf(_Perspective.farY);
    final farFloorL =
        p.floorPoint(-_Perspective.stageHalfWidth, _Perspective.farY);
    final farFloorR =
        p.floorPoint(_Perspective.stageHalfWidth, _Perspective.farY);
    final farTopL = Offset(
      farFloorL.dx,
      farFloorL.dy - p.heightPx(_Perspective.bermHeight, dFar),
    );
    final farTopR = Offset(
      farFloorR.dx,
      farFloorR.dy - p.heightPx(_Perspective.bermHeight, dFar),
    );
    final farPath = Path()
      ..moveTo(farFloorL.dx, farFloorL.dy)
      ..lineTo(farFloorR.dx, farFloorR.dy)
      ..lineTo(farTopR.dx, farTopR.dy)
      ..lineTo(farTopL.dx, farTopL.dy)
      ..close();
    canvas.drawPath(farPath, Paint()..color = const Color(0xFF655641));

    final sideWall = Paint()..color = const Color(0xFF6E5E48);
    for (final side in <double>[
      -_Perspective.stageHalfWidth,
      _Perspective.stageHalfWidth,
    ]) {
      final dNear = p.dOf(_Perspective.nearY);
      final nearFloor = p.floorPoint(side, _Perspective.nearY);
      final farFloor = p.floorPoint(side, _Perspective.farY);
      final nearTop = Offset(
        nearFloor.dx,
        nearFloor.dy - p.heightPx(_Perspective.bermHeight, dNear),
      );
      final farTop = Offset(
        farFloor.dx,
        farFloor.dy - p.heightPx(_Perspective.bermHeight, dFar),
      );
      final wallPath = Path()
        ..moveTo(nearFloor.dx, nearFloor.dy)
        ..lineTo(farFloor.dx, farFloor.dy)
        ..lineTo(farTop.dx, farTop.dy)
        ..lineTo(nearTop.dx, nearTop.dy)
        ..close();
      canvas.drawPath(wallPath, sideWall);
    }

    final strip = Paint()..color = const Color(0xFF847458);
    for (final pair in <List<double>>[
      [-_Perspective.stageHalfWidth, -_Perspective.corridorHalfWidth],
      [_Perspective.corridorHalfWidth, _Perspective.stageHalfWidth],
    ]) {
      final path = Path()
        ..moveTo(
          p.floorPoint(pair[0], _Perspective.nearY).dx,
          p.floorPoint(pair[0], _Perspective.nearY).dy,
        )
        ..lineTo(
          p.floorPoint(pair[1], _Perspective.nearY).dx,
          p.floorPoint(pair[1], _Perspective.nearY).dy,
        )
        ..lineTo(
          p.floorPoint(pair[1], _Perspective.farY).dx,
          p.floorPoint(pair[1], _Perspective.farY).dy,
        )
        ..lineTo(
          p.floorPoint(pair[0], _Perspective.farY).dx,
          p.floorPoint(pair[0], _Perspective.farY).dy,
        )
        ..close();
      canvas.drawPath(path, strip);
    }

    final floorPath = Path()
      ..moveTo(
        p.floorPoint(-_Perspective.corridorHalfWidth, _Perspective.nearY).dx,
        p.floorPoint(-_Perspective.corridorHalfWidth, _Perspective.nearY).dy,
      )
      ..lineTo(
        p.floorPoint(_Perspective.corridorHalfWidth, _Perspective.nearY).dx,
        p.floorPoint(_Perspective.corridorHalfWidth, _Perspective.nearY).dy,
      )
      ..lineTo(
        p.floorPoint(_Perspective.corridorHalfWidth, _Perspective.farY).dx,
        p.floorPoint(_Perspective.corridorHalfWidth, _Perspective.farY).dy,
      )
      ..lineTo(
        p.floorPoint(-_Perspective.corridorHalfWidth, _Perspective.farY).dx,
        p.floorPoint(-_Perspective.corridorHalfWidth, _Perspective.farY).dy,
      )
      ..close();
    canvas.drawPath(floorPath, Paint()..color = const Color(0xFFA5A19A));

    final depthLine = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    for (double y = _Perspective.farY; y <= _Perspective.nearY; y += 5) {
      final left = p.floorPoint(-_Perspective.corridorHalfWidth, y);
      final right = p.floorPoint(_Perspective.corridorHalfWidth, y);
      canvas.drawLine(left, right, depthLine);
    }

    final sorted = [...elements]
      ..sort((a, b) => a.position.dy.compareTo(b.position.dy));
    for (final element in sorted) {
      _drawElement(canvas, p, element);
    }

    final start = previewStart;
    final end = previewEnd;
    if (start != null && end != null) {
      final a = p.floorPoint(start.$1, start.$2);
      final b = p.floorPoint(end.$1, end.$2);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = Colors.yellowAccent
          ..strokeWidth = 3,
      );
      canvas.drawCircle(a, 4, Paint()..color = Colors.yellowAccent);
      canvas.drawCircle(b, 4, Paint()..color = Colors.yellowAccent);
    }
  }

  void _drawElement(Canvas canvas, _Perspective p, StageElement element) {
    final isSelected = element.id == selectedId;
    final spec = element.type;
    final d = p.dOf(element.position.dy);
    final base = p.floorPoint(element.position.dx, element.position.dy);

    if (spec.archetype == PropArchetype.floorLine) {
      final rot = element.rotation * math.pi / 180;
      final dx = math.cos(rot) * element.width / 2;
      final dy = math.sin(rot) * element.width / 2;
      final a =
          p.floorPoint(element.position.dx - dx, element.position.dy - dy);
      final b =
          p.floorPoint(element.position.dx + dx, element.position.dy + dy);
      final linePaint = Paint()
        ..color = isSelected ? Colors.orange : spec.color
        ..strokeWidth = isSelected ? 4 : 2.5;
      if (spec == StageElementType.dashedLine) {
        final step = (b - a) / 8;
        for (var i = 0; i < 8; i += 2) {
          canvas.drawLine(a + step * i.toDouble(), a + step * (i + 1), linePaint);
        }
      } else {
        canvas.drawLine(a, b, linePaint);
      }
      if (isSelected) {
        _drawLabel(
          canvas,
          spec.label,
          Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2),
        );
      }
      return;
    }

    if (spec.archetype == PropArchetype.floorDisc) {
      final radius = math.max(p.widthPx(element.width / 2, d), 3.0);
      canvas.drawCircle(base, radius, Paint()..color = spec.color);
      canvas.drawCircle(
        base,
        radius,
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 3 : 1.5,
      );
      final badge = switch (spec) {
        StageElementType.shootingPosition => 'P',
        StageElementType.spMarker => 'SP',
        StageElementType.xxMarker => 'XX',
        StageElementType.activatorPad => 'ACT',
        _ => '',
      };
      if (badge.isNotEmpty) {
        _drawLabel(canvas, badge, Offset(base.dx, base.dy - radius - 4));
      }
      if (isSelected) {
        _drawLabel(canvas, spec.label, Offset(base.dx, base.dy + radius + 12));
      }
      return;
    }

    final w = math.max(p.widthPx(element.width, d), 6.0);
    final h = math.max(p.heightPx(element.height, d), 8.0);
    final rect = Rect.fromLTWH(base.dx - w / 2, base.dy - h, w, h);
    final border = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 1.5;

    switch (spec) {
      case StageElementType.cone:
        final path = Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
        canvas.drawPath(path, Paint()..color = spec.color);
        canvas.drawPath(path, border);
        break;
      case StageElementType.popper:
      case StageElementType.miniPopper:
        final head = Rect.fromLTWH(rect.left, rect.top, rect.width, h * 0.8);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            head,
            topLeft: Radius.circular(w * 0.45),
            topRight: Radius.circular(w * 0.45),
          ),
          Paint()..color = spec.color,
        );
        canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.top + h * 0.82, rect.width, h * 0.18),
          Paint()..color = Colors.grey.shade600,
        );
        break;
      case StageElementType.barrel:
      case StageElementType.barrelDouble:
        final drum = RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(w * 0.3),
          topRight: Radius.circular(w * 0.3),
          bottomLeft: Radius.circular(w * 0.3),
          bottomRight: Radius.circular(w * 0.3),
        );
        canvas.drawRRect(drum, Paint()..color = spec.color);
        canvas.drawRRect(drum, border);
        final rim = Paint()
          ..color = Colors.black26
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(rect.left, rect.top + h * 0.25),
          Offset(rect.right, rect.top + h * 0.25),
          rim,
        );
        canvas.drawLine(
          Offset(rect.left, rect.top + h * 0.75),
          Offset(rect.right, rect.top + h * 0.75),
          rim,
        );
        break;
      case StageElementType.paperTarget:
      case StageElementType.noShoot:
      case StageElementType.classicTarget:
      case StageElementType.noShootClassic:
      case StageElementType.ipscMiniTarget:
      case StageElementType.noShootMini:
      case StageElementType.classicMiniTarget:
      case StageElementType.classicMiniNoShoot:
      case StageElementType.partialTarget:
      case StageElementType.partialTargetTop:
      case StageElementType.partialTargetLeft:
      case StageElementType.partialTargetRight:
      case StageElementType.narrowTarget:
      case StageElementType.narrowTargetNoShoot:
      case StageElementType.dOctagonPeach:
      case StageElementType.dOctagonWhite:
      case StageElementType.dOctagonNoShoot:
      case StageElementType.roundHeadLarge:
      case StageElementType.roundHeadSmall:
      case StageElementType.ovalHead:
      case StageElementType.teardropHead:
      case StageElementType.halfHead:
      case StageElementType.penaltyTarget:
      case StageElementType.hardCoverTarget:
      case StageElementType.hardCoverPartial:
      case StageElementType.moverTarget:
      case StageElementType.swingingTarget:
      case StageElementType.dropTurner:
      case StageElementType.knockDownTarget:
        _drawPaperCard(canvas, element, rect, isSelected);
        break;
      case StageElementType.visionBarrier:
      case StageElementType.visionBarrierNarrow:
        canvas.drawRect(
          rect,
          Paint()..color = spec.color.withValues(alpha: 0.35),
        );
        canvas.drawRect(
          rect,
          Paint()
            ..color = spec.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 3 : 2,
        );
        break;
      case StageElementType.door:
      case StageElementType.doorWithWindow:
        canvas.drawRect(rect, Paint()..color = spec.color);
        canvas.drawRect(
          rect.inflate(w * 0.06),
          Paint()
            ..color = const Color(0xFF4E342A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(w * 0.08, 2),
        );
        if (spec == StageElementType.doorWithWindow) {
          canvas.drawRect(
            Rect.fromLTWH(
              rect.left + w * 0.2,
              rect.top + h * 0.15,
              w * 0.6,
              h * 0.25,
            ),
            Paint()..color = Colors.white70,
          );
        }
        break;
      case StageElementType.widePort:
      case StageElementType.windowFrame:
      case StageElementType.portSquare:
        canvas.drawRect(
          rect,
          Paint()
            ..color = spec.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(w * 0.12, 2),
        );
        break;
      case StageElementType.plateRack:
      case StageElementType.texasStar:
      case StageElementType.spinner:
        canvas.drawRect(rect, Paint()..color = spec.color);
        canvas.drawRect(rect, border);
        final platePaint = Paint()..color = Colors.grey.shade300;
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset(
              rect.left + w * (0.2 + 0.3 * i),
              rect.top + h * 0.4,
            ),
            math.max(w * 0.1, 1.5),
            platePaint,
          );
        }
        break;
      case StageElementType.pallet:
        canvas.drawRect(rect, Paint()..color = spec.color);
        canvas.drawRect(rect, border);
        final slat = Paint()
          ..color = Colors.black26
          ..strokeWidth = 1;
        for (var i = 1; i < 4; i++) {
          canvas.drawLine(
            Offset(rect.left, rect.top + h * i / 4),
            Offset(rect.right, rect.top + h * i / 4),
            slat,
          );
        }
        break;
      case StageElementType.mannequin:
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: Radius.circular(w * 0.5),
            topRight: Radius.circular(w * 0.5),
          ),
          Paint()..color = spec.color,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: Radius.circular(w * 0.5),
            topRight: Radius.circular(w * 0.5),
          ),
          border,
        );
        break;
      case StageElementType.redOutline:
        canvas.drawPath(
          _ipscPath(rect),
          Paint()
            ..color = spec.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        break;
      case StageElementType.wall:
      case StageElementType.barrier:
      case StageElementType.bowlingPin:
      case StageElementType.table:
      case StageElementType.sawhorse:
      case StageElementType.bench:
      case StageElementType.chair:
      case StageElementType.stackBoxes:
      case StageElementType.hayBale:
      case StageElementType.sandbagWall:
        canvas.drawRect(rect, Paint()..color = spec.color);
        canvas.drawRect(rect, border);
        break;
      case StageElementType.faultLine:
      case StageElementType.stopTape:
      case StageElementType.dashedLine:
      case StageElementType.moverRail:
      case StageElementType.plate:
      case StageElementType.plateLarge:
      case StageElementType.spMarker:
      case StageElementType.xxMarker:
      case StageElementType.activatorPad:
      case StageElementType.shootingPosition:
        break;
    }

    if (isSelected) {
      canvas.drawRect(
        rect.inflate(2),
        Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _drawLabel(canvas, spec.label, Offset(rect.center.dx, rect.top - 14));
    }
  }

  static const Color _cardboard = Color(0xFFF2D2A9);
  static const Color _cardOutline = Color(0xFF26262B);

  Path _ipscPath(Rect rect) {
    final cutY = rect.top + rect.height * 0.72;
    final topInset = rect.width * 0.28;
    return Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right, cutY)
      ..lineTo(rect.right - topInset, rect.top)
      ..lineTo(rect.left + topInset, rect.top)
      ..lineTo(rect.left, cutY)
      ..close();
  }

  Path _octagonPath(Rect r) {
    final cx = r.width * 0.3;
    final cy = r.height * 0.3;
    return Path()
      ..moveTo(r.left + cx, r.top)
      ..lineTo(r.right - cx, r.top)
      ..lineTo(r.right, r.top + cy)
      ..lineTo(r.right, r.bottom - cy)
      ..lineTo(r.right - cx, r.bottom)
      ..lineTo(r.left + cx, r.bottom)
      ..lineTo(r.left, r.bottom - cy)
      ..lineTo(r.left, r.top + cy)
      ..close();
  }

  Path _teardropPath(Rect r) {
    final cx = r.center.dx;
    return Path()
      ..moveTo(cx, r.bottom)
      ..quadraticBezierTo(r.left - r.width * 0.15, r.center.dy, cx, r.top)
      ..quadraticBezierTo(r.right + r.width * 0.15, r.center.dy, cx, r.bottom)
      ..close();
  }

  Path _domePath(Rect r) {
    return Path()
      ..moveTo(r.left, r.bottom)
      ..arcToPoint(
        Offset(r.right, r.bottom),
        radius: Radius.elliptical(r.width / 2, r.height),
      )
      ..close();
  }

  Path _cardShape(StageElementType spec, Rect r) {
    switch (spec) {
      case StageElementType.dOctagonPeach:
      case StageElementType.dOctagonWhite:
      case StageElementType.dOctagonNoShoot:
        return _octagonPath(r);
      case StageElementType.roundHeadLarge:
      case StageElementType.roundHeadSmall:
      case StageElementType.ovalHead:
        return Path()..addOval(r);
      case StageElementType.teardropHead:
        return _teardropPath(r);
      case StageElementType.halfHead:
        return _domePath(r);
      case StageElementType.paperTarget:
      case StageElementType.noShoot:
      case StageElementType.ipscMiniTarget:
      case StageElementType.noShootMini:
      case StageElementType.hardCoverTarget:
      case StageElementType.hardCoverPartial:
      case StageElementType.moverTarget:
      case StageElementType.swingingTarget:
      case StageElementType.dropTurner:
      case StageElementType.knockDownTarget:
        return _ipscPath(r);
      default:
        return Path()..addRect(r);
    }
  }

  Color _cardFill(StageElementType spec) {
    const whites = <StageElementType>{
      StageElementType.noShoot,
      StageElementType.noShootClassic,
      StageElementType.noShootMini,
      StageElementType.classicMiniNoShoot,
      StageElementType.narrowTargetNoShoot,
      StageElementType.dOctagonNoShoot,
      StageElementType.penaltyTarget,
      StageElementType.ovalHead,
    };
    if (whites.contains(spec)) {
      return Colors.white;
    }
    if (spec == StageElementType.knockDownTarget) {
      return const Color(0xFFCFD8DC);
    }
    return _cardboard;
  }

  bool _isNoShootCard(StageElementType spec) {
    const noShoots = <StageElementType>{
      StageElementType.noShoot,
      StageElementType.noShootClassic,
      StageElementType.noShootMini,
      StageElementType.classicMiniNoShoot,
      StageElementType.narrowTargetNoShoot,
      StageElementType.dOctagonNoShoot,
      StageElementType.penaltyTarget,
    };
    return noShoots.contains(spec);
  }

  void _drawPaperCard(
    Canvas canvas,
    StageElement element,
    Rect rect,
    bool isSelected,
  ) {
    final spec = element.type;
    const floating = <StageElementType>{
      StageElementType.dOctagonPeach,
      StageElementType.dOctagonWhite,
      StageElementType.dOctagonNoShoot,
      StageElementType.roundHeadLarge,
      StageElementType.roundHeadSmall,
      StageElementType.ovalHead,
      StageElementType.teardropHead,
      StageElementType.halfHead,
    };
    final hasLegs = floating.contains(spec);
    final cardRect = hasLegs
        ? Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.55)
        : rect;

    if (hasLegs) {
      final legW = math.max(cardRect.width * 0.08, 1.5);
      final legH = rect.bottom - cardRect.bottom;
      final legPaint = Paint()..color = _cardOutline;
      canvas.drawRect(
        Rect.fromLTWH(
          cardRect.left + cardRect.width * 0.2,
          cardRect.bottom,
          legW,
          legH,
        ),
        legPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          cardRect.right - cardRect.width * 0.2 - legW,
          cardRect.bottom,
          legW,
          legH,
        ),
        legPaint,
      );
    }

    final shape = _cardShape(spec, cardRect);
    canvas.drawPath(shape, Paint()..color = _cardFill(spec));

    final cover = spec == StageElementType.hardCoverTarget ||
        spec == StageElementType.hardCoverPartial;
    if (cover) {
      canvas.save();
      canvas.clipPath(shape);
      canvas.drawRect(
        Rect.fromLTWH(
          cardRect.left,
          cardRect.top,
          cardRect.width,
          cardRect.height * 0.4,
        ),
        Paint()..color = Colors.black87,
      );
      canvas.restore();
    }

    final inset = math.min(cardRect.width, cardRect.height) * 0.09;
    if (inset > 0.5) {
      final inner = _cardShape(spec, cardRect.deflate(inset));
      canvas.drawPath(
        inner,
        Paint()
          ..color = _cardOutline
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(cardRect.width * 0.02, 0.8),
      );
    }

    if (_isNoShootCard(spec)) {
      final cross = Paint()
        ..color = Colors.red
        ..strokeWidth = math.max(cardRect.width * 0.1, 2);
      canvas.drawLine(
        Offset(
          cardRect.left + cardRect.width * 0.25,
          cardRect.top + cardRect.height * 0.25,
        ),
        Offset(
          cardRect.right - cardRect.width * 0.25,
          cardRect.bottom - cardRect.height * 0.25,
        ),
        cross,
      );
      canvas.drawLine(
        Offset(
          cardRect.right - cardRect.width * 0.25,
          cardRect.top + cardRect.height * 0.25,
        ),
        Offset(
          cardRect.left + cardRect.width * 0.25,
          cardRect.bottom - cardRect.height * 0.25,
        ),
        cross,
      );
    }

    canvas.drawPath(
      shape,
      Paint()
        ..color = _cardOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.2,
    );

    if (spec == StageElementType.moverTarget ||
        spec == StageElementType.swingingTarget ||
        spec == StageElementType.dropTurner ||
        spec == StageElementType.knockDownTarget) {
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left - rect.width * 0.1,
          rect.top - rect.height * 0.12,
          rect.width * 1.2,
          rect.height * 0.07,
        ),
        Paint()..color = Colors.grey.shade700,
      );
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset at) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          backgroundColor: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height));
  }

  @override
  bool shouldRepaint(covariant _GalleryPainter3D oldDelegate) =>
      oldDelegate.elements != elements ||
      oldDelegate.selectedId != selectedId ||
      oldDelegate.previewStart != previewStart ||
      oldDelegate.previewEnd != previewEnd;
}
