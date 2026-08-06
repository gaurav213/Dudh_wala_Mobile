import 'package:json_annotation/json_annotation.dart';

part 'auth_dto.g.dart';

@JsonSerializable()
class LoginRequest {
  LoginRequest({required this.phone, required this.password});

  final String phone;
  final String password;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  RegisterRequest({
    required this.name,
    required this.phone,
    required this.password,
    this.email,
    this.role = 'supplier',
  });

  final String name;
  final String phone;
  final String password;
  final String? email;
  final String role;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class AuthTokensDto {
  AuthTokensDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUserDto user;

  factory AuthTokensDto.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AuthTokensDtoToJson(this);
}

@JsonSerializable()
class AuthUserDto {
  AuthUserDto({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email,
  });

  final String id;
  final String name;
  final String phone;
  final String role;
  final String? email;

  factory AuthUserDto.fromJson(Map<String, dynamic> json) =>
      _$AuthUserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AuthUserDtoToJson(this);
}
