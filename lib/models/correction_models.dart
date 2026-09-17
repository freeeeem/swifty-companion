/// Créneau de correction réservable, tel que renvoyé par
/// l'endpoint /v2/users/:id/slots de l'API 42.
class CorrectionSlot {
  final int id;
  final DateTime beginAt;
  final DateTime endAt;

  /// Un créneau est réservé lorsqu'une équipe d'évaluation y est associée.
  final bool isBooked;

  /// L'intra découpe les disponibilités en petits blocs ; cette liste
  /// rassemble les IDs de tous les blocs fusionnés dans ce créneau
  /// ([id] seul quand le créneau n'est pas le résultat d'une fusion).
  final List<int> chunkIds;

  const CorrectionSlot({
    required this.id,
    required this.beginAt,
    required this.endAt,
    required this.isBooked,
    this.chunkIds = const [],
  });

  factory CorrectionSlot.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt() ?? 0;
    return CorrectionSlot(
      id: id,
      beginAt: DateTime.tryParse(json['begin_at'] ?? '') ?? DateTime.now(),
      endAt: DateTime.tryParse(json['end_at'] ?? '') ?? DateTime.now(),
      isBooked: json['scale_team'] != null,
      chunkIds: [id],
    );
  }
}