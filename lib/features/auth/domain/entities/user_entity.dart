enum UserRole { supplier, customer }

class UserEntity {
  const UserEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email,
    this.remoteId,
  });

  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? email;
  final String? remoteId;

  bool get isSupplier => role == UserRole.supplier;

  factory UserEntity.fromMap(Map<String, Object?> map) {
    final roleRaw = (map['role'] as String? ?? 'supplier').toLowerCase();
    return UserEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      remoteId: map['remote_id'] as String?,
      role: roleRaw == 'customer' ? UserRole.customer : UserRole.supplier,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'remote_id': remoteId,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role == UserRole.customer ? 'customer' : 'supplier',
      };
}
