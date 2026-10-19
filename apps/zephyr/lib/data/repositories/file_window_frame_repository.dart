import '../../domain/models/window_frame.dart';
import '../../domain/repositories/window_frame_repository.dart';
import '../services/window_frame_file_storage.dart';

class FileWindowFrameRepository implements WindowFrameRepository {
  FileWindowFrameRepository(this._storage);

  final WindowFrameFileStorage _storage;

  @override
  Future<WindowFrame> load() async {
    final values = await _storage.read();
    if (values == null) {
      return WindowFrame.defaults;
    }
    final width = _double(values, 'width') ?? WindowFrame.defaultWidth;
    final height = _double(values, 'height') ?? WindowFrame.defaultHeight;
    if (width <= 0 || height <= 0) {
      return WindowFrame.defaults;
    }
    return WindowFrame(
      width: width,
      height: height,
      x: _double(values, 'x'),
      y: _double(values, 'y'),
      maximized: values['maximized'] == true,
    );
  }

  @override
  Future<void> save(WindowFrame frame) => _storage.write({
    'width': frame.width,
    'height': frame.height,
    'x': frame.x,
    'y': frame.y,
    'maximized': frame.maximized,
  });

  double? _double(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value == null) return null;
    if (value is! num) throw FormatException('Invalid $key window frame.');
    return value.toDouble();
  }
}
