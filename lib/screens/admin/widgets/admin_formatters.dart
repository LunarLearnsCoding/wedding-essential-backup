/// Groups the data and behavior required by the admin formatters component.
class AdminFormatters {
  AdminFormatters._();

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String date(DateTime? value) {
    if (value == null) return 'No date';
    return '${_months[value.month - 1]} ${value.day}, ${value.year}';
  }

  static String dateTime(DateTime? value) {
    if (value == null) return 'No date';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '${date(value)} | $hour:$minute $period';
  }

  static String currency(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final fromEnd = text.length - i;
      buffer.write(text[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return 'Rs. ${buffer.toString()}';
  }
}
