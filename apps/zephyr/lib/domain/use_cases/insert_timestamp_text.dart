import 'package:intl/intl.dart';

/// Plain-text timestamp for the quick-toolbar insert action.
String insertTimestampText({String? localeName}) {
  final locale = localeName ?? 'zh_CN';
  return DateFormat('yyyy-MM-dd HH:mm:ss', locale).format(DateTime.now());
}
