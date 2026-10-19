import '../models/window_frame.dart';

abstract interface class WindowFrameRepository {
  Future<WindowFrame> load();
  Future<void> save(WindowFrame frame);
}
