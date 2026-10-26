import 'dart:convert';

// Helper function to parse the list
List<TokenHistoryItem> tokenHistoryFromJson(String str) =>
    List<TokenHistoryItem>.from(
        json.decode(str).map((x) => TokenHistoryItem.fromJson(x)));

class TokenHistoryItem {
  TokenHistoryItem({
    required this.tokenNumber,
    required this.mealType,
    required this.date,
    required this.generatedAt,
    required this.name,
    this.enrollmentNo,
    this.year,
    this.room,
  });

  final int tokenNumber;
  final String mealType;
  final String date;
  final DateTime generatedAt;
  final String name;
  final String? enrollmentNo;
  final int? year;
  final int? room;

  factory TokenHistoryItem.fromJson(Map<String, dynamic> json) =>
      TokenHistoryItem(
        tokenNumber: json["tokenNumber"],
        mealType: json["mealType"],
        date: json["date"],
        generatedAt: DateTime.parse(json["generatedAt"]),
        name: json["name"],
        enrollmentNo: json["enrollmentNo"],
        year: json["year"],
        room: json["room"],
      );
}