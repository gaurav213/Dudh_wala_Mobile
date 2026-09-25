enum UserRole { farmOwner, deliveryStaff, customer, platformOwner }

class UserEntity {
  const UserEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email,
    this.avatarUrl,
    this.remoteId,
  });

  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? email;
  final String? avatarUrl;
  final String? remoteId;

  bool get isSupplier =>
      role == UserRole.farmOwner || role == UserRole.deliveryStaff;
  bool get isCustomer => role == UserRole.customer;
  bool get isFarmOwner => role == UserRole.farmOwner;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static UserRole roleFromApi(String raw) {
    switch (raw.toUpperCase()) {
      case 'CUSTOMER':
        return UserRole.customer;
      case 'DELIVERY_STAFF':
        return UserRole.deliveryStaff;
      case 'PLATFORM_OWNER':
        return UserRole.platformOwner;
      case 'FARM_OWNER':
      default:
        return UserRole.farmOwner;
    }
  }

  static String roleToStorage(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'CUSTOMER';
      case UserRole.deliveryStaff:
        return 'DELIVERY_STAFF';
      case UserRole.platformOwner:
        return 'PLATFORM_OWNER';
      case UserRole.farmOwner:
        return 'FARM_OWNER';
    }
  }

  factory UserEntity.fromMap(Map<String, Object?> map) {
    final roleRaw = map['role'] as String? ?? 'FARM_OWNER';
    return UserEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      remoteId: map['remote_id'] as String?,
      role: roleFromApi(roleRaw),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'remote_id': remoteId,
        'name': name,
        'phone': phone,
        'email': email,
        'avatar_url': avatarUrl,
        'role': roleToStorage(role),
      };
}
