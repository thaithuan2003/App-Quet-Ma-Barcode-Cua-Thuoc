class AppDateUtils {
  AppDateUtils._();

  static String formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Không có';
    }
    return value.split('T').first;
  }
}
