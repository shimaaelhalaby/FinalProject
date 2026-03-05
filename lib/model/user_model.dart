class UserModel {
  final String id;
  final String name;
  final String email;
  final String? imagePath;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email, 'imagePath': imagePath};
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      imagePath: map['imagePath'],
    );
  }

  factory UserModel.fromFirestore(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      imagePath: map['imagePath'],
    );
  }
}
