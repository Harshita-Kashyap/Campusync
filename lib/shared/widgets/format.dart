String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

const demoLabel = 'Demo data · Estimates, not live sensor measurements';

/// 1234.5 -> "1,235" (or "1,234.5" with digits: 1).
String fmtNum(num v, [int digits = 0]) {
  final neg = v < 0;
  final parts = v.abs().toStringAsFixed(digits).split('.');
  final ip = parts[0];
  final b = StringBuffer();
  for (var i = 0; i < ip.length; i++) {
    if (i > 0 && (ip.length - i) % 3 == 0) b.write(',');
    b.write(ip[i]);
  }
  return '${neg ? '-' : ''}$b${parts.length > 1 ? '.${parts[1]}' : ''}';
}

/// "in_progress" -> "In progress".
String prettyStatus(String s) {
  final t = s.replaceAll('_', ' ');
  return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}
