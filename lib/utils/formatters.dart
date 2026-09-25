import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

final DateFormat _postDateFormat = DateFormat('d MMM yyyy', 'id');

bool _localeReady = false;

String formatPostDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';

  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;

  if (!_localeReady) {
    initializeDateFormatting('id', null);
    _localeReady = true;
  }

  return _postDateFormat.format(parsed);
}
