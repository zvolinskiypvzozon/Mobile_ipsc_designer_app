import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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
  Offset _dragRawPos = Offset.zero;
  final FocusNode _canvasFocus = FocusNode();

  @override
  void dispose() {
    _canvasFocus.dispose();
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
      _stage = Stage(id: _uuid.v4(), title: 'Новый стейдж');
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
          title: const Text('Переименовать стейдж'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Название'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Переименовать'),
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
      messenger.showSnackBar(const SnackBar(content: Text('Стейдж сохранён')));
      navigator.pop();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $error')),
      );
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  IconData _categoryIcon(PropCategory category) {
    switch (category) {
      case PropCategory.ipscTargets:
        return Icons.adjust;
      case PropCategory.steel:
        return Icons.disc_full;
      case PropCategory.movers:
        return Icons.swap_horiz;
      case PropCategory.visualBarriers:
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
                    'Библиотека пропов',
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
          title: Text('Установить ${selected.label}'),
          content: Text(
            selected.archetype == PropArchetype.floorLine
                ? 'Нарисуйте линию, протянув палец или мышь по полу галереи.'
                : 'Коснитесь пола галереи, чтобы установить. '
                    'Инструмент остаётся активным, пока вы его не завершите.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Поставить'),
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
    _canvasFocus.requestFocus();
    final p = _Perspective(size);
    if (_armedTool != null) {
      if (_armedTool!.archetype == PropArchetype.floorLine) {
        return;
      }
      final hit = _hitTestElement(p, local);
      if (hit != null) {
        setState(() => _selectedElementId = hit);
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
      if (hit != null) {
        _dragRawPos = _stage
            .elements
            .firstWhere((element) => element.id == hit)
            .position;
      }
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
    final dRaw = p.dOf(_dragRawPos.dy);
    final baseY = p.screenYFromD(dRaw);
    final newBaseY = baseY + _lastDelta.dy;
    final dy = newBaseY - p.horizonY;
    double newY = _dragRawPos.dy;
    if (dy > 1) {
      final newD = p.kv * _Perspective.camHeight / dy;
      newY = (_Perspective.camDepth - newD).clamp(0.0, _Perspective.nearY);
    }
    final newX = (_dragRawPos.dx + _lastDelta.dx * dRaw / p.kx).clamp(
      -_Perspective.stageHalfWidth,
      _Perspective.stageHalfWidth,
    );
    _dragRawPos = Offset(newX, newY);
    _updateElement(
      element.copyWith(position: _snapAttach(element, _dragRawPos)),
    );
  }

  Offset _snapAttach(StageElement dragged, Offset position) {
    const snapDistance = 0.3;
    Offset? best;
    var bestDist = double.infinity;
    for (final other in _stage.elements) {
      if (other.id == dragged.id ||
          other.type.archetype != PropArchetype.billboard ||
          other.rotation != 0) {
        continue;
      }
      final candidates = <Offset>[
        Offset(
          other.position.dx - other.width / 2 - dragged.width / 2,
          other.position.dy,
        ),
        Offset(
          other.position.dx + other.width / 2 + dragged.width / 2,
          other.position.dy,
        ),
        Offset(
          other.position.dx,
          other.position.dy - other.height / 2 - dragged.height / 2,
        ),
        Offset(
          other.position.dx,
          other.position.dy + other.height / 2 + dragged.height / 2,
        ),
      ];
      for (final candidate in candidates) {
        final dist = (candidate - position).distance;
        if (dist < bestDist) {
          bestDist = dist;
          best = candidate;
        }
      }
    }
    if (best == null || bestDist > snapDistance) {
      return position;
    }
    return Offset(
      best.dx.clamp(-_Perspective.stageHalfWidth, _Perspective.stageHalfWidth),
      best.dy.clamp(0.0, _Perspective.nearY),
    );
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

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (_selectedElementId == null ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final step = HardwareKeyboard.instance.isShiftPressed ? 0.5 : 0.1;
    double? dx;
    double? dy;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        dx = -step;
      case LogicalKeyboardKey.arrowRight:
        dx = step;
      case LogicalKeyboardKey.arrowUp:
        dy = -step;
      case LogicalKeyboardKey.arrowDown:
        dy = step;
      default:
        return KeyEventResult.ignored;
    }
    final element = _selectedElement;
    if (element == null) {
      return KeyEventResult.ignored;
    }
    _updateElement(
      element.copyWith(
        position: Offset(
          (element.position.dx + (dx ?? 0)).clamp(
            -_Perspective.stageHalfWidth,
            _Perspective.stageHalfWidth,
          ),
          (element.position.dy + (dy ?? 0)).clamp(0.0, _Perspective.nearY),
        ),
      ),
    );
    return KeyEventResult.handled;
  }

  Widget _buildModeBanner() {
    final tool = _armedTool!;
    final hint = tool.archetype == PropArchetype.floorLine
        ? 'протяните по полу, чтобы нарисовать'
        : 'коснитесь пола, чтобы поставить';
    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Установка: ${tool.label} — $hint'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Завершить установку',
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
            tooltip: 'Инструменты',
            onPressed: _openToolsMenu,
          ),
          if (selected != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Удалить элемент',
              onPressed: _deleteSelected,
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Переименовать',
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
            tooltip: 'Сохранить',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Focus(
        focusNode: _canvasFocus,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Column(
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
                    key: const ValueKey('galleryCanvas'),
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
  double get kx => kv;

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
      if (spec == StageElementType.activatorPad) {
        final tp = TextPainter(
          text: TextSpan(
            text: 'Активатор',
            style: TextStyle(
              color: Colors.white,
              fontSize: math.max(radius * 0.34, 6),
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: radius * 2);
        tp.paint(canvas, base - Offset(tp.width / 2, tp.height / 2));
      } else {
        final badge = switch (spec) {
          StageElementType.shootingPosition => 'P',
          StageElementType.spMarker => 'SP',
          StageElementType.xxMarker => 'XX',
          _ => '',
        };
        if (badge.isNotEmpty) {
          _drawLabel(canvas, badge, Offset(base.dx, base.dy - radius - 4));
        }
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
        _drawPopper(canvas, rect, isSelected, Colors.white);
        break;
      case StageElementType.miniPopper:
        _drawPopper(canvas, rect, isSelected, Colors.white);
        break;
      case StageElementType.popperNs:
        _drawPopper(canvas, rect, isSelected, const Color(0xFFD32F2F));
        break;
      case StageElementType.popperNsMini:
        _drawPopper(canvas, rect, isSelected, const Color(0xFFD32F2F));
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
      case StageElementType.ipscStandart:
        _drawIpscStandart(canvas, rect, isSelected, Colors.white);
        break;
      case StageElementType.nsIpsc:
        _drawIpscStandart(canvas, rect, isSelected, const Color(0xFFD32F2F));
        break;
      case StageElementType.ipscMini:
        _drawIpscMini(canvas, rect, isSelected, Colors.white);
        break;
      case StageElementType.nsIpscMini:
        _drawIpscMini(canvas, rect, isSelected, const Color(0xFFD32F2F));
        break;
      case StageElementType.ipscMikro:
        _drawIpscMini(
          canvas,
          rect,
          isSelected,
          Colors.white,
          cardHeightFactor: 0.20,
        );
        break;
      case StageElementType.moverTarget:
        _drawMoverTarget(canvas, rect, isSelected);
        break;
      case StageElementType.upDownTarget:
        _drawUpDownTarget(canvas, rect, isSelected);
        break;
      case StageElementType.vbBarrel:
        _drawDrum(canvas, rect, openTop: false);
        break;
      case StageElementType.vbBarrelDouble:
        _drawDoubleDrum(canvas, rect);
        break;
      case StageElementType.vbBarrelOpen:
        _drawDrum(canvas, rect, openTop: true);
        break;
      case StageElementType.vbBarrier05:
      case StageElementType.vbBarrier1:
      case StageElementType.vbBarrier2:
      case StageElementType.vbBarrier3:
        _drawVisualBarrier(canvas, rect, isSelected);
        break;
      case StageElementType.wheelLarge:
        _drawWheelStack(canvas, rect, 1, isSelected);
        break;
      case StageElementType.wheelStack5:
        _drawWheelStack(canvas, rect, 5, isSelected);
        break;
      case StageElementType.wheelStack8:
        _drawWheelStack(canvas, rect, 8, isSelected);
        break;
      case StageElementType.curtainFrame1:
      case StageElementType.curtainFrame2:
      case StageElementType.curtainFrame3:
        _drawCurtainFrame(canvas, rect, isSelected);
        break;
      case StageElementType.vbPallet:
        _drawVbPallet(canvas, rect, isSelected);
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
      case StageElementType.roundPlate:
        _drawRoundPlate(canvas, rect, isSelected, Colors.white);
        break;
      case StageElementType.roundPlateNs:
        _drawRoundPlate(canvas, rect, isSelected, const Color(0xFFD32F2F));
        break;
      case StageElementType.squarePlate:
        _drawSquarePlate(canvas, rect, isSelected, Colors.white);
        break;
      case StageElementType.squarePlateNs:
        _drawSquarePlate(canvas, rect, isSelected, const Color(0xFFD32F2F));
        break;
      case StageElementType.texasStar:
        _drawTexasStar(canvas, rect, isSelected);
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

  Path _roundedOctagonPath(Rect r, {double corner = 0.18}) {
    final cx = r.width * 0.28;
    final cy = r.height * 0.28;
    final v = <Offset>[
      Offset(r.left + cx, r.top),
      Offset(r.right - cx, r.top),
      Offset(r.right, r.top + cy),
      Offset(r.right, r.bottom - cy),
      Offset(r.right - cx, r.bottom),
      Offset(r.left + cx, r.bottom),
      Offset(r.left, r.bottom - cy),
      Offset(r.left, r.top + cy),
    ];
    final k = corner;
    final path = Path();
    for (var i = 0; i < v.length; i++) {
      final prev = v[(i - 1 + v.length) % v.length];
      final cur = v[i];
      final next = v[(i + 1) % v.length];
      final p1 = Offset.lerp(cur, prev, k)!;
      final p2 = Offset.lerp(cur, next, k)!;
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.quadraticBezierTo(cur.dx, cur.dy, p2.dx, p2.dy);
    }
    path.close();
    return path;
  }

  void _drawIpscStandart(
    Canvas canvas,
    Rect rect,
    bool isSelected,
    Color fill,
  ) {
    final cardRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      rect.height * 0.65,
    );
    final legW = math.max(cardRect.width * 0.07, 1.5);
    final legH = rect.bottom - cardRect.bottom;
    final legPaint = Paint()..color = _cardOutline;
    canvas.drawRect(
      Rect.fromLTWH(
        cardRect.left + cardRect.width * 0.28,
        cardRect.bottom - legH * 0.06,
        legW,
        legH,
      ),
      legPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        cardRect.right - cardRect.width * 0.28 - legW,
        cardRect.bottom - legH * 0.06,
        legW,
        legH,
      ),
      legPaint,
    );
    final shape = _roundedOctagonPath(cardRect);
    canvas.drawPath(shape, Paint()..color = fill);
    final inset = cardRect.width * 0.09;
    if (inset > 0.5) {
      canvas.drawPath(
        _roundedOctagonPath(cardRect.deflate(inset)),
        Paint()
          ..color = _cardOutline
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(cardRect.width * 0.02, 0.8),
      );
    }
    canvas.drawPath(
      shape,
      Paint()
        ..color = _cardOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.2,
    );
  }

  void _drawIpscMini(
    Canvas canvas,
    Rect rect,
    bool isSelected,
    Color fill, {
    double cardHeightFactor = 0.34,
  }) {
    final cardW = rect.width * 0.62;
    final cardRect = Rect.fromLTWH(
      rect.center.dx - cardW / 2,
      rect.top,
      cardW,
      rect.height * cardHeightFactor,
    );
    final legW = math.max(rect.width * 0.05, 1.0);
    final legH = rect.bottom - cardRect.bottom;
    final legPaint = Paint()..color = _cardOutline;
    final spacing = rect.width * 0.16;
    canvas.drawRect(
      Rect.fromLTWH(
        rect.center.dx - spacing - legW / 2,
        cardRect.bottom - legH * 0.04,
        legW,
        legH,
      ),
      legPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        rect.center.dx + spacing - legW / 2,
        cardRect.bottom - legH * 0.04,
        legW,
        legH,
      ),
      legPaint,
    );
    final shape = _roundedOctagonPath(cardRect, corner: 0.10);
    canvas.drawPath(shape, Paint()..color = fill);
    canvas.drawPath(
      shape,
      Paint()
        ..color = _cardOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2 : 1,
    );
  }

  void _drawPopper(
    Canvas canvas,
    Rect rect,
    bool isSelected,
    Color fill,
  ) {
    final cx = rect.center.dx;
    final headR = rect.width * 0.30;
    final headC = Offset(cx, rect.top + headR);
    final neckW = rect.width * 0.42;
    final baseH = rect.height * 0.10;
    final bodyTop = headC.dy + headR * 0.5;
    final body = Rect.fromLTWH(
      cx - neckW / 2,
      bodyTop,
      neckW,
      rect.bottom - baseH - bodyTop,
    );
    final baseW = rect.width * 0.55;
    final base = Rect.fromLTWH(
      cx - baseW / 2,
      rect.bottom - baseH,
      baseW,
      baseH,
    );
    final head = Path()
      ..addOval(Rect.fromCircle(center: headC, radius: headR));
    final shape = Path.combine(
      PathOperation.union,
      head,
      Path.combine(
        PathOperation.union,
        Path()..addRect(body),
        Path()..addRect(base),
      ),
    );
    canvas.drawPath(shape, Paint()..color = fill);
    canvas.drawPath(
      shape,
      Paint()
        ..color = _cardOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.2,
    );
  }

  void _drawRoundPlate(
    Canvas canvas,
    Rect rect,
    bool isSelected,
    Color fill,
  ) {
    final r = rect.width / 2;
    final center = Offset(rect.center.dx, rect.top + r);
    final baseH = rect.height * 0.16;
    final baseW = rect.width * 0.55;
    final base = Rect.fromLTWH(
      rect.center.dx - baseW / 2,
      rect.bottom - baseH,
      baseW,
      baseH,
    );
    canvas.drawRect(base, Paint()..color = _cardOutline);
    canvas.drawCircle(center, r, Paint()..color = fill);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = _cardOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : math.max(rect.width * 0.08, 1.2),
    );
  }

  void _drawTexasStar(Canvas canvas, Rect rect, bool isSelected) {
    final starR = rect.width * 0.34;
    final plateR = starR * 0.36;
    final cy = rect.top + starR + plateR;
    final cx = rect.center.dx;
    final spoke = Paint()
      ..color = _cardOutline
      ..strokeWidth = math.max(rect.width * 0.03, 1.2);
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx, rect.bottom),
      spoke,
    );
    final baseH = math.max(rect.height * 0.025, 2.0);
    canvas.drawRect(
      Rect.fromLTWH(
        cx - rect.width * 0.17,
        rect.bottom - baseH,
        rect.width * 0.34,
        baseH,
      ),
      Paint()..color = _cardOutline,
    );
    final plateCenters = <Offset>[
      for (var i = 0; i < 5; i++)
        Offset(
          cx + starR * math.cos(-math.pi / 2 + i * 2 * math.pi / 5),
          cy + starR * math.sin(-math.pi / 2 + i * 2 * math.pi / 5),
        ),
    ];
    for (final plateC in plateCenters) {
      canvas.drawLine(Offset(cx, cy), plateC, spoke);
    }
    canvas.drawCircle(Offset(cx, cy), plateR * 0.5, Paint()..color = _cardOutline);
    for (final plateC in plateCenters) {
      canvas.drawCircle(plateC, plateR, Paint()..color = Colors.white);
      canvas.drawCircle(
        plateC,
        plateR,
        Paint()
          ..color = _cardOutline
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2 : 1.2,
      );
    }
  }

  void _drawSquarePlate(Canvas canvas, Rect rect, bool isSelected, Color fill) {
    final side = rect.width;
    final plate = Rect.fromLTWH(rect.left, rect.top, side, side);
    final baseH = rect.height * 0.16;
    final baseW = rect.width * 0.55;
    final base = Rect.fromLTWH(
      rect.center.dx - baseW / 2,
      rect.bottom - baseH,
      baseW,
      baseH,
    );
    canvas.drawRect(base, Paint()..color = _cardOutline);
    canvas.drawRect(plate, Paint()..color = fill);
    canvas.drawRect(
      plate,
      Paint()
        ..color = _cardOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : math.max(rect.width * 0.10, 1.5),
    );
  }

  void _drawMoverTarget(Canvas canvas, Rect rect, bool isSelected) {
    final cx = rect.center.dx;
    final pivot = Offset(cx, rect.top + rect.height * 0.58);
    const plateColors = <Color>[
      Color(0xFFF2EDE3),
      Color(0xFFC9B78C),
      Color(0xFFE8DCC0),
      Color(0xFFD9C7A0),
    ];
    final armR = rect.width * 0.34;
    final octW = rect.width * 0.20;
    final octH = rect.width * 0.26;
    final spoke = Paint()
      ..color = _cardOutline
      ..strokeWidth = math.max(rect.width * 0.012, 1);
    final outline = Paint()
      ..color = _cardOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.5 : 1;
    final plateRects = <Rect>[
      for (final deg in <double>[-150, -118, -80, -42])
        Rect.fromCenter(
          center: Offset(
            pivot.dx + armR * math.cos(deg * math.pi / 180),
            pivot.dy + armR * math.sin(deg * math.pi / 180),
          ),
          width: octW,
          height: octH,
        ),
    ];
    for (final plateRect in plateRects) {
      canvas.drawLine(pivot, plateRect.center, spoke);
    }
    for (var i = 0; i < plateRects.length; i++) {
      final shape = _roundedOctagonPath(plateRects[i], corner: 0.14);
      canvas.drawPath(shape, Paint()..color = plateColors[i]);
      canvas.drawPath(shape, outline);
    }
    final armEnd1 = Offset(cx - rect.width * 0.17, pivot.dy + rect.height * 0.15);
    final armEnd2 = Offset(cx + rect.width * 0.17, pivot.dy + rect.height * 0.15);
    canvas.drawLine(armEnd1, Offset(cx + rect.width * 0.07, pivot.dy + rect.height * 0.02), spoke);
    canvas.drawLine(armEnd2, Offset(cx - rect.width * 0.07, pivot.dy + rect.height * 0.02), spoke);
    final weightW = rect.width * 0.055;
    canvas.drawRect(
      Rect.fromCenter(center: armEnd1, width: weightW, height: weightW),
      Paint()..color = _cardOutline,
    );
    canvas.drawRect(
      Rect.fromCenter(center: armEnd2, width: weightW, height: weightW),
      Paint()..color = _cardOutline,
    );
    canvas.drawLine(pivot, Offset(cx, rect.bottom - rect.height * 0.04), spoke);
    final baseH = math.max(rect.height * 0.025, 2.0);
    canvas.drawRect(
      Rect.fromLTWH(
        cx - rect.width * 0.15,
        rect.bottom - baseH,
        rect.width * 0.30,
        baseH,
      ),
      Paint()..color = _cardOutline,
    );
    final arcRect = Rect.fromLTWH(
      cx - rect.width * 0.30,
      rect.top + rect.height * 0.05,
      rect.width * 0.58,
      rect.height * 0.26,
    );
    final arcPaint = Paint()
      ..color = _cardOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(rect.width * 0.018, 1.2);
    const startAngle = math.pi + math.pi / 12;
    const sweepAngle = 2 * math.pi / 3;
    const endAngle = startAngle + sweepAngle;
    final dotR = math.max(rect.width * 0.008, 1.0);
    for (final t in <double>[0.18, 0.38, 0.58, 0.78]) {
      final theta = startAngle + sweepAngle * t;
      final dot = Offset(
        arcRect.center.dx + arcRect.width / 2 * math.cos(theta),
        arcRect.center.dy + arcRect.height / 2 * math.sin(theta),
      );
      canvas.drawCircle(dot, dotR, arcPaint);
    }
    final end = Offset(
      arcRect.center.dx + arcRect.width / 2 * math.cos(endAngle),
      arcRect.center.dy + arcRect.height / 2 * math.sin(endAngle),
    );
    final dir = Offset(-math.sin(endAngle), math.cos(endAngle));
    final barbLen = rect.width * 0.05;
    for (final phi in <double>[math.pi / 6, -math.pi / 6]) {
      final rotated = Offset(
        dir.dx * math.cos(phi) - dir.dy * math.sin(phi),
        dir.dx * math.sin(phi) + dir.dy * math.cos(phi),
      );
      canvas.drawLine(end, end - rotated * (barbLen / rotated.distance), arcPaint);
    }
  }

  void _drawUpDownTarget(Canvas canvas, Rect rect, bool isSelected) {
    final cx = rect.center.dx;
    const plateColors = <Color>[
      Color(0xFFC9B78C),
      Color(0xFFCFD8DC),
      Color(0xFFF2EDE3),
    ];
    final octW = rect.width * 0.30;
    final octH = octW * 1.7;
    final outline = Paint()
      ..color = _cardOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final centerY = rect.top + rect.height * 0.28;
    final spacing = octH * 0.55;
    final plateRects = <Rect>[
      for (var i = 0; i < plateColors.length; i++)
        Rect.fromCenter(
          center: Offset(cx, centerY + i * spacing),
          width: octW,
          height: octH,
        ),
    ];
    for (var i = 0; i < plateRects.length; i++) {
      final ghost = i < plateRects.length - 1;
      final fill = ghost
          ? plateColors[i].withValues(alpha: 0.75)
          : plateColors[i];
      final shape = _roundedOctagonPath(plateRects[i], corner: 0.12);
      canvas.drawPath(shape, Paint()..color = fill);
      canvas.drawPath(shape, outline);
    }
    final bottomRect = plateRects.last;
    final arrowX = cx + rect.width * 0.42;
    final arrowPaint = Paint()
      ..color = _cardOutline
      ..strokeWidth = math.max(rect.width * 0.015, 1);
    final yTop = rect.top + rect.height * 0.05;
    final yBottom = bottomRect.bottom + rect.height * 0.04;
    final tick = octW * 0.22;
    canvas.drawLine(Offset(arrowX, yTop), Offset(arrowX, yBottom), arrowPaint);
    canvas.drawLine(
      Offset(arrowX - tick, yTop),
      Offset(arrowX + tick, yTop),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(arrowX - tick, yBottom),
      Offset(arrowX + tick, yBottom),
      arrowPaint,
    );
    final standTop = bottomRect.bottom + rect.height * 0.02;
    canvas.drawLine(
      Offset(cx, standTop),
      Offset(cx, rect.bottom - rect.height * 0.05),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(cx, rect.bottom - rect.height * 0.05),
      Offset(cx - rect.width * 0.14, rect.bottom),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(cx, rect.bottom - rect.height * 0.05),
      Offset(cx + rect.width * 0.14, rect.bottom),
      arrowPaint,
    );
  }

  static const Color _drumBody = Color(0xFF2E5E96);
  static const Color _drumRim = Color(0xFF5B8FD9);
  static const Color _drumOpening = Color(0xFF14141A);
  static const Color _barrierFill = Color(0xFFD6DCE5);
  static const Color _barrierEdge = Color(0xFFE8ECF2);
  static const Color _tire = Color(0xFF23232A);

  void _drawDrumSegment(
    Canvas canvas,
    Rect body,
    Offset topCenter,
    double topH,
    bool openTop,
  ) {
    final drum = RRect.fromRectAndCorners(
      body,
      topLeft: Radius.circular(body.width * 0.12),
      topRight: Radius.circular(body.width * 0.12),
      bottomLeft: Radius.circular(body.width * 0.12),
      bottomRight: Radius.circular(body.width * 0.12),
    );
    canvas.drawRRect(drum, Paint()..color = _drumBody);
    canvas.drawRRect(
      drum,
      Paint()
        ..color = _cardOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final rim = Rect.fromCenter(center: topCenter, width: body.width * 0.92, height: topH);
    canvas.drawOval(rim, Paint()..color = _drumRim);
    canvas.drawOval(
      rim,
      Paint()
        ..color = _cardOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (openTop) {
      canvas.drawOval(
        Rect.fromCenter(
          center: topCenter,
          width: body.width * 0.68,
          height: topH * 0.62,
        ),
        Paint()..color = _drumOpening,
      );
    }
  }

  void _drawDrum(Canvas canvas, Rect rect, {required bool openTop}) {
    final topH = rect.width * 0.20;
    final bodyTop = rect.top + topH / 2;
    final body = Rect.fromLTWH(
      rect.left,
      bodyTop,
      rect.width,
      rect.height - (bodyTop - rect.top) - rect.width * 0.06,
    );
    _drawDrumSegment(
      canvas,
      body,
      Offset(rect.center.dx, rect.top + topH / 2),
      topH,
      openTop,
    );
  }

  void _drawDoubleDrum(Canvas canvas, Rect rect) {
    final inset = (rect.width - rect.width * 0.72) / 2;
    final topH = rect.width * 0.72 * 0.22;
    final segH = rect.height / 2;
    _drawDrumSegment(
      canvas,
      Rect.fromLTWH(
        rect.left + inset,
        rect.top + topH / 2,
        rect.width * 0.72,
        segH - topH / 2 - rect.width * 0.05,
      ),
      Offset(rect.center.dx, rect.top + topH / 2),
      topH,
      false,
    );
    _drawDrumSegment(
      canvas,
      Rect.fromLTWH(
        rect.left + inset,
        rect.top + segH + topH / 2,
        rect.width * 0.72,
        segH - topH / 2 - rect.width * 0.05,
      ),
      Offset(rect.center.dx, rect.top + segH + topH / 2),
      topH,
      false,
    );
  }

  void _drawVisualBarrier(Canvas canvas, Rect rect, bool isSelected) {
    canvas.drawRect(
      rect,
      Paint()..color = _barrierFill.withValues(alpha: 0.22),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = _barrierEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 2,
    );
  }

  void _drawWheelStack(Canvas canvas, Rect rect, int count, bool isSelected) {
    final tireH = rect.height / count;
    final tirePaint = Paint()
      ..color = _tire
      ..style = PaintingStyle.stroke
      ..strokeWidth = tireH * 0.52;
    final outline = Paint()
      ..color = _cardOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < count; i++) {
      final centerY = rect.bottom - tireH * (i + 0.5);
      final tire = Rect.fromCenter(
        center: Offset(rect.center.dx, centerY),
        width: rect.width * 0.94,
        height: tireH * 0.82,
      );
      canvas.drawOval(tire, tirePaint);
      canvas.drawOval(tire, outline);
    }
  }

  void _drawCurtainFrame(Canvas canvas, Rect rect, bool isSelected) {
    canvas.drawRect(
      rect,
      Paint()..color = _barrierFill.withValues(alpha: 0.16),
    );
    final stripe = Paint()
      ..color = _barrierEdge
      ..strokeWidth = math.max(rect.width * 0.02, 1);
    final stripes = ((rect.width / rect.height) * 8).round().clamp(4, 14);
    final inset = rect.width * 0.06;
    for (var i = 1; i < stripes; i++) {
      final x = rect.left + inset + (rect.width - inset * 2) * i / stripes;
      canvas.drawLine(
        Offset(x, rect.top + rect.height * 0.03),
        Offset(x, rect.bottom - rect.height * 0.03),
        stripe,
      );
    }
    canvas.drawRect(
      rect,
      Paint()
        ..color = _barrierEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 2,
    );
  }

  void _drawVbPallet(Canvas canvas, Rect rect, bool isSelected) {
    canvas.drawRect(rect, Paint()..color = const Color(0xFFC9A66B));
    canvas.drawRect(rect, Paint()..color = const Color(0xFF8D6E63));
    final gap = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = math.max(rect.height * 0.035, 1.5);
    for (var i = 1; i < 5; i++) {
      final y = rect.top + rect.height * i / 5;
      canvas.drawLine(
        Offset(rect.left + rect.width * 0.04, y),
        Offset(rect.right - rect.width * 0.04, y),
        gap,
      );
    }
    canvas.drawRect(
      rect,
      Paint()
        ..color = _cardOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.2,
    );
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
