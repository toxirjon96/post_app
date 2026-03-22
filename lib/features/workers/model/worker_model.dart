class WorkerModel {
  const WorkerModel({
    required this.id,
    required this.fullName,
    this.imageUrl,
    this.birthDate,
    this.checkInTime,
    this.checkOutTime,
    this.address,
    this.department,
    this.position,
    this.isOnline = false,
    this.phoneNumber,
  });

  final String id;
  final String fullName;
  final String? imageUrl;

  /// Format: 'DD.MM.YYYY'
  final String? birthDate;

  /// Format: 'HH:mm'
  final String? checkInTime;

  /// Format: 'HH:mm'
  final String? checkOutTime;

  final String? address;
  final String? department;
  final String? position;
  final bool isOnline;
  final String? phoneNumber;

  /// Returns initials (up to 2 chars) from fullName.
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}