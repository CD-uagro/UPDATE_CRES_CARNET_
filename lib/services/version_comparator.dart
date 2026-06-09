List<int> _parseSemanticVersion(String version) {
  final core = version.trim().split(RegExp(r'[-+]')).first;
  if (core.isEmpty) return const [0];

  return core.split('.').map((part) {
    final match = RegExp(r'^\d+').firstMatch(part.trim());
    return match == null ? 0 : int.parse(match.group(0)!);
  }).toList();
}

/// Compares two semantic versions without lexicographic string ordering.
///
/// Returns:
/// - a positive value when [a] is greater than [b]
/// - zero when both versions are equal
/// - a negative value when [a] is lower than [b]
int compareSemanticVersions(String a, String b) {
  final left = _parseSemanticVersion(a);
  final right = _parseSemanticVersion(b);
  final maxLength = left.length > right.length ? left.length : right.length;

  for (var i = 0; i < maxLength; i++) {
    final leftPart = i < left.length ? left[i] : 0;
    final rightPart = i < right.length ? right[i] : 0;

    if (leftPart != rightPart) {
      return leftPart.compareTo(rightPart);
    }
  }

  return 0;
}
