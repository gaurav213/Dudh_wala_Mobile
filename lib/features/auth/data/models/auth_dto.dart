import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/json_parsing.dart';

part 'auth_dto.g.dart';

@JsonSerializable()
class LoginRequest {
  LoginRequest(
      {required this.mobileNumber, required this.password, this.deviceId});

  final String mobileNumber;
  final String password;
  final String? deviceId;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterFarmOwnerRequest {
  RegisterFarmOwnerRequest({
    required this.name,
    required this.mobileNumber,
    required this.password,
    required this.farmName,
    required this.addressLine1,
    required this.area,
    required this.city,
    required this.state,
    required this.postalCode,
    this.businessName,
    this.email,
    this.addressLine2,
    this.description,
  });

  final String name;
  final String mobileNumber;
  final String password;
  final String farmName;
  final String? businessName;
  final String? description;
  final String? email;
  final String addressLine1;
  final String? addressLine2;
  final String area;
  final String city;
  final String state;
  final String postalCode;

  factory RegisterFarmOwnerRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterFarmOwnerRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterFarmOwnerRequestToJson(this);
}

@JsonSerializable()
class RegisterCustomerRequest {
  RegisterCustomerRequest({
    required this.name,
    required this.mobileNumber,
    required this.password,
  });

  final String name;
  final String mobileNumber;
  final String password;

  factory RegisterCustomerRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterCustomerRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterCustomerRequestToJson(this);
}

@JsonSerializable()
class AuthTokensDto {
  AuthTokensDto({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUserDto? user;

  factory AuthTokensDto.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    return AuthTokensDto(
      accessToken: asStringOr(json['accessToken']),
      refreshToken: asStringOr(json['refreshToken']),
      user: userRaw is Map<String, dynamic>
          ? AuthUserDto.fromJson(userRaw)
          : null,
    );
  }
  Map<String, dynamic> toJson() => _$AuthTokensDtoToJson(this);
}

@JsonSerializable()
class AuthUserDto {
  AuthUserDto({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.role,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String mobileNumber;
  final String role;
  final String? email;
  final String? avatarUrl;

  factory AuthUserDto.fromJson(Map<String, dynamic> json) => AuthUserDto(
        id: asStringOr(json['id'] ?? json['userId']),
        name: asStringOr(json['name'], 'User'),
        mobileNumber: asStringOr(
          json['mobileNumber'] ?? json['mobile_number'],
        ),
        role: asStringOr(json['role'], 'CUSTOMER'),
        email: asStringOrNull(json['email']),
        avatarUrl: asStringOrNull(json['avatarUrl'] ?? json['avatar_url']),
      );
  Map<String, dynamic> toJson() => _$AuthUserDtoToJson(this);
}
