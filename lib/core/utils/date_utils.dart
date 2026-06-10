class AppDateUtils {
  AppDateUtils._();

  static String formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Khong co';
    }
    return value.split('T').first;
  }
}
