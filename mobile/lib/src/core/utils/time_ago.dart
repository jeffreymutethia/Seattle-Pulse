String timeAgo(String isoDate) {
  final date = DateTime.parse(isoDate);
  final now = DateTime.now();
  final seconds = now.difference(date).inSeconds;
  final minutes = now.difference(date).inMinutes;
  final hours = now.difference(date).inHours;
  final days = now.difference(date).inDays;

  if (days > 1) return '$days days ago';
  if (days == 1) return '1 day ago';
  if (hours > 1) return '$hours hours ago';
  if (hours == 1) return '1 hour ago';
  if (minutes > 1) return '$minutes minutes ago';
  if (minutes == 1) return '1 minute ago';
  return 'Just now';
}
