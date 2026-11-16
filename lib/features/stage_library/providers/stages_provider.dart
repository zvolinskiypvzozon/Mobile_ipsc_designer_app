import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/stage.dart';

final stagesProvider = Provider<List<Stage>>((ref) => const <Stage>[]);
