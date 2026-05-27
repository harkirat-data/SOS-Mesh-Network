import 'dart:convert';
import 'package:uuid/uuid.dart';

class SosMessage {
  final String id;
  final String senderName;
  final double lat;
  final double lng;
  final int timestamp;
  final int hopCount;

  SosMessage({
    String? id,
    required this.senderName,
    required this.lat,
    required this.lng,
    required this.timestamp,
    required this.hopCount,
  }) : id = id ?? const Uuid().v4();

  SosMessage copyWith({
    String? id,
    String? senderName,
    double? lat,
    double? lng,
    int? timestamp,
    int? hopCount,
  }) {
    return SosMessage(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      timestamp: timestamp ?? this.timestamp,
      hopCount: hopCount ?? this.hopCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderName': senderName,
      'lat': lat,
      'lng': lng,
      'timestamp': timestamp,
      'hopCount': hopCount,
    };
  }

  factory SosMessage.fromMap(Map<String, dynamic> map) {
    return SosMessage(
      id: map['id'] ?? '',
      senderName: map['senderName'] ?? '',
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
      timestamp: map['timestamp'] ?? 0,
      hopCount: map['hopCount'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory SosMessage.fromJson(String source) => SosMessage.fromMap(json.decode(source));
}
