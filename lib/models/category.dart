import '../core/constants.dart';

class Category {
  final int? id;
  final String name;
  final CategoryType type;
  final String? icon;

  const Category({
    this.id,
    required this.name,
    required this.type,
    this.icon,
  });

  Category copyWith({int? id, String? name, CategoryType? type, String? icon}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type.value,
      'icon': icon,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: CategoryTypeExt.fromString(map['type'] as String),
      icon: map['icon'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ type.hashCode;
}

// Default categories untuk seed data
final List<Map<String, dynamic>> defaultCategories = [
  // Expense
  {'name': 'Makanan & Minuman', 'type': 'expense', 'icon': 'food'},
  {'name': 'Transportasi', 'type': 'expense', 'icon': 'transport'},
  {'name': 'Belanja', 'type': 'expense', 'icon': 'shopping'},
  {'name': 'Hiburan', 'type': 'expense', 'icon': 'entertainment'},
  {'name': 'Kesehatan', 'type': 'expense', 'icon': 'health'},
  {'name': 'Pendidikan', 'type': 'expense', 'icon': 'education'},
  {'name': 'Tagihan', 'type': 'expense', 'icon': 'bill'},
  {'name': 'Investasi Emas', 'type': 'expense', 'icon': 'gold'},
  {'name': 'Lainnya', 'type': 'expense', 'icon': 'other'},
  // Income
  {'name': 'Gaji', 'type': 'income', 'icon': 'salary'},
  {'name': 'Bonus', 'type': 'income', 'icon': 'bonus'},
  {'name': 'Freelance', 'type': 'income', 'icon': 'freelance'},
  {'name': 'Jual Emas', 'type': 'income', 'icon': 'gold'},
  {'name': 'Lainnya', 'type': 'income', 'icon': 'other'},
];
