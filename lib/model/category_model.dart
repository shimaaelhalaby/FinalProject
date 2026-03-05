class Category {
  final int? id;
  String name;
  bool isSelected;
  String? firestoreId;
  bool isSynced;
  String? userId;

  Category({
    this.id,
    required this.name,
    this.isSelected = false,
    this.firestoreId,
    this.isSynced = false,
    this.userId,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      isSelected: map['isSelected'] == 1,
      firestoreId: map['firestoreId'],
      isSynced: (map['isSynced'] ?? 0) == 1,
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isSelected': isSelected ? 1 : 0,
      'firestoreId': firestoreId,
      'isSynced': isSynced ? 1 : 0,
      'userId': userId,
    };
  }
}
