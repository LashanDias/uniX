/// Short, human relative time, e.g. "2m ago", "3h ago", "5d ago".
///
/// [now] is injectable so tests do not depend on the wall clock.
String timeAgo(DateTime moment, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(moment);

  if (difference.isNegative) {
    final ahead = difference.abs();
    if (ahead.inMinutes < 1) return 'Just now';
    if (ahead.inHours < 1) return 'in ${ahead.inMinutes}m';
    if (ahead.inDays < 1) return 'in ${ahead.inHours}h';
    return 'in ${ahead.inDays}d';
  }

  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  if (difference.inDays < 365) return '${(difference.inDays / 7).floor()}w ago';
  return '${(difference.inDays / 365).floor()}y ago';
}
