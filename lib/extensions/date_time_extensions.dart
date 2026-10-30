import 'package:intl/intl.dart';

extension DateTimeFormatting on DateTime {
  String toIsoDateString() => DateFormat('yyyy-MM-dd').format(this);
}
