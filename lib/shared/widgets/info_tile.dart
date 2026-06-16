import 'package:flutter/material.dart';

class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon == null ? null : Icon(icon),
      title: Text(label, style: Theme.of(context).textTheme.labelLarge),
      subtitle: Text(value.isEmpty ? 'Không có' : value),
      dense: true,
    );
  }
}
