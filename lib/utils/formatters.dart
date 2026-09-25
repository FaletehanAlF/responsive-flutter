import 'package:intl/intl.dart';

final DateFormat _postDateFormat = DateFormat('d MMM yyyy', 'id');

String formatPostDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';

  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;

  return _postDateFormat.format(parsed);
}
