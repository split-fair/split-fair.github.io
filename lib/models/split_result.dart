import 'room.dart';

class SplitResult {
  final Room room;
  final double score;
  final double percentage;
  final double amount;

  const SplitResult({
    required this.room, required this.score,
    required this.percentage, required this.amount,
  });
}

List<SplitResult> calculateSplit({
  required List<Room> rooms,
  required double totalRent,
  List<double>? communalSqftByRoom,
}) {
  if (rooms.isEmpty || totalRent <= 0) return [];
  final scores = List.generate(rooms.length, (i) {
    final extra = (communalSqftByRoom != null && i < communalSqftByRoom.length)
        ? communalSqftByRoom[i] : 0.0;
    return rooms[i].computeScore(extraSqft: extra);
  });
  final totalScore = scores.fold(0.0, (a, b) => a + b);
  return List.generate(rooms.length, (i) {
    final pct = scores[i] / totalScore;
    return SplitResult(room: rooms[i], score: scores[i], percentage: pct, amount: totalRent * pct);
  });
}