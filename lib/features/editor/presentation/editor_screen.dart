import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/stage.dart';
import '../../../core/models/stage_element.dart';
import '../../stage_library/providers/stages_provider.dart';

const double kPixelsPerMeter = 50;
const Size kStageSizeMeters = Size(25, 15);
const double kMinElementWidth = 0.05;
const double kMaxElementWidth = 8;
const double kMinElementHeight = 0.05;
const double kMaxElementHeight = 3;
const double kMaxRotationDegrees = 180;

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  static const _uuid = Uuid();
  static final _random = math.Random();

  late Stage _stage;
  bool _stageInitialized = false;
  String? _selectedElementId;
  bool _saving = false;
  final TransformationController _transformation = TransformationController();

  @override
  void dispose() {
    _transformation.dispose();
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

  double get _currentScale =>
      _transformation.value.getMaxScaleOnAxis().clamp(0.01, 100).toDouble();

  void _updateStage(Stage stage) {
    setState(() => _stage = stage);
  }

  void _updateElement(StageElement element) {
    _updateStage(_stage.copyWith(elements: <StageElement>[
      for (final existing in _stage.elements)
        if (existing.id == element.id) element else existing,
    ]));
  }

  void _addElement(StageElementType type) {
    final size = type.defaultSize;
    final jitter = Offset(
      _random.nextDouble() * 2 - 1,
      _random.nextDouble() * 2 - 1,
    );
    final position = Offset(
      (kStageSizeMeters.width / 2 + jitter.dx)
          .clamp(size.width / 2, kStageSizeMeters.width - size.width / 2)
          .toDouble(),
      (kStageSizeMeters.height / 2 + jitter.dy)
          .clamp(size.height / 2, kStageSizeMeters.height - size.height / 2)
          .toDouble(),
    );
    final element = StageElement(
      id: _uuid.v4(),
      type: type,
      position: position,
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

  Widget _buildCanvasBackground() {
    return Container(
      width: kStageSizeMeters.width * kPixelsPerMeter,
      height: kStageSizeMeters.height * kPixelsPerMeter,
      decoration: BoxDecoration(
        color: const Color(0xFF101613),
        border: Border.all(color: Colors.white24),
      ),
      child: CustomPaint(
        painter: _GridPainter(
          spacing: kPixelsPerMeter,
          stageWidth: kStageSizeMeters.width,
          stageHeight: kStageSizeMeters.height,
        ),
      ),
    );
  }

  Widget _buildElementView(StageElement element) {
    final width = element.width * kPixelsPerMeter;
    final height = element.height * kPixelsPerMeter;
    final borderRadius = BorderRadius.circular(4);

    switch (element.type) {
      case StageElementType.paperTarget:
      case StageElementType.noShoot:
        final isNoShoot = element.type == StageElementType.noShoot;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
            border: Border.all(
              color: isNoShoot ? Colors.black : Colors.brown,
              width: 2,
            ),
          ),
          child: isNoShoot
              ? Icon(Icons.close, size: width * 0.6, color: Colors.red)
              : Center(
                  child: Container(
                    width: width * 0.3,
                    height: width * 0.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.brown, width: 1.5),
                    ),
                  ),
                ),
        );
      case StageElementType.popper:
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
              width: width * 0.8,
              height: height * 0.7,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(width * 0.4),
                  topRight: Radius.circular(width * 0.4),
                ),
              ),
            ),
            Container(
              width: width,
              height: height * 0.18,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: borderRadius,
              ),
            ),
          ],
        );
      case StageElementType.plate:
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade300,
            border: Border.all(color: Colors.black54, width: 1.5),
          ),
        );
      case StageElementType.wall:
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: borderRadius,
            border: Border.all(color: Colors.black, width: 2),
          ),
        );
      case StageElementType.barrier:
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.35),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.orange, width: 2),
          ),
        );
      case StageElementType.faultLine:
        return Container(
          width: width,
          height: math.max(height, 3),
          decoration: BoxDecoration(
            color: Colors.yellowAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case StageElementType.shootingPosition:
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.shade700,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              'P',
              style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
    }
  }

  Widget _buildElement(StageElement element) {
    final selected = element.id == _selectedElementId;
    final bounds = element.bounds;
    final boundsPx = Rect.fromCenter(
      center: Offset(
        bounds.center.dx * kPixelsPerMeter,
        bounds.center.dy * kPixelsPerMeter,
      ),
      width: bounds.width * kPixelsPerMeter,
      height: bounds.height * kPixelsPerMeter,
    );
    return Positioned(
      left: boundsPx.left,
      top: boundsPx.top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedElementId = element.id),
        onPanUpdate: (DragUpdateDetails details) {
          final scale = _currentScale;
          final delta = Offset(
            details.delta.dx / (kPixelsPerMeter * scale),
            details.delta.dy / (kPixelsPerMeter * scale),
          );
          _updateElement(element.copyWith(
            position: Offset(
              (element.position.dx + delta.dx)
                  .clamp(
                    element.width / 2,
                    kStageSizeMeters.width - element.width / 2,
                  )
                  .toDouble(),
              (element.position.dy + delta.dy)
                  .clamp(
                    element.height / 2,
                    kStageSizeMeters.height - element.height / 2,
                  )
                  .toDouble(),
            ),
          ));
        },
        child: Transform.rotate(
          angle: element.rotation * math.pi / 180,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              _buildElementView(element),
              if (selected)
                Positioned(
                  left: 0,
                  right: 0,
                  top: -20,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        element.type.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPalette() {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: <Widget>[
          for (final type in StageElementType.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ActionChip(
                label: Text(type.label),
                onPressed: () => _addElement(type),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertiesPanel(StageElement element) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: const BoxDecoration(
        color: Colors.black26,
        border: Border(top: BorderSide(color: Colors.white24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  element.type.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete element',
                onPressed: _deleteSelected,
              ),
            ],
          ),
          _LabeledSlider(
            label: 'Rotation ${element.rotation.toStringAsFixed(0)}°',
            value: element.rotation,
            min: -kMaxRotationDegrees,
            max: kMaxRotationDegrees,
            onChanged: (value) => _updateElement(
              element.copyWith(rotation: value),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: _LabeledSlider(
                  label: 'W ${element.width.toStringAsFixed(2)} m',
                  value: element.width,
                  min: kMinElementWidth,
                  max: kMaxElementWidth,
                  onChanged: (value) =>
                      _updateElement(element.copyWith(width: value)),
                ),
              ),
              Expanded(
                child: _LabeledSlider(
                  label: 'H ${element.height.toStringAsFixed(2)} m',
                  value: element.height,
                  min: kMinElementHeight,
                  max: kMaxElementHeight,
                  onChanged: (value) =>
                      _updateElement(element.copyWith(height: value)),
                ),
              ),
            ],
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
            child: GestureDetector(
              onTap: () => setState(() => _selectedElementId = null),
              child: InteractiveViewer(
                transformationController: _transformation,
                boundaryMargin: const EdgeInsets.all(2000),
                maxScale: 4,
                minScale: 0.2,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      _buildCanvasBackground(),
                      for (final element in _stage.elements)
                        _buildElement(element),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildPalette(),
          if (selected != null) _buildPropertiesPanel(selected),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({
    required this.spacing,
    required this.stageWidth,
    required this.stageHeight,
  });

  final double spacing;
  final double stageWidth;
  final double stageHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final meterPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 2;
    final meterStep = 5 * spacing;
    for (double x = meterStep; x < size.width; x += meterStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), meterPaint);
    }
    for (double y = meterStep; y < size.height; y += meterStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), meterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.spacing != spacing ||
      oldDelegate.stageWidth != stageWidth ||
      oldDelegate.stageHeight != stageHeight;
}
