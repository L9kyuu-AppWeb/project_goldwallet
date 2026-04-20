import '../core/constants.dart';

class Wallet {
  final int? id;
  final String name;
  final WalletType type;
  final double balance; // Untuk gold: dalam GRAM. Lainnya: IDR
  final bool isMain;
  final DateTime createdAt;

  const Wallet({
    this.id,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.isMain = false,
    required this.createdAt,
  });

  bool get isGold => type == WalletType.gold;

  Wallet copyWith({
    int? id,
    String? name,
    WalletType? type,
    double? balance,
    bool? isMain,
    DateTime? createdAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      isMain: isMain ?? this.isMain,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type.value,
      'balance': balance,
      'is_main': isMain ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: WalletTypeExt.fromString(map['type'] as String),
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      isMain: (map['is_main'] as int?) == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  String toString() => 'Wallet(id: $id, name: $name, type: ${type.value}, balance: $balance)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ type.hashCode;
}
