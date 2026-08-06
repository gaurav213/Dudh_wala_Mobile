// GENERATED CODE - HAND STUB (replace via build_runner)
// ignore_for_file: type=lint

part of 'auth_dto.dart';

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
      phone: json['phone'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'password': instance.password,
    };

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      name: json['name'] as String,
      phone: json['phone'] as String,
      password: json['password'] as String,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'supplier',
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
      'password': instance.password,
      'email': instance.email,
      'role': instance.role,
    };

AuthTokensDto _$AuthTokensDtoFromJson(Map<String, dynamic> json) =>
    AuthTokensDto(
      accessToken: json['accessToken'] as String? ??
          json['access_token'] as String,
      refreshToken: json['refreshToken'] as String? ??
          json['refresh_token'] as String,
      user: AuthUserDto.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthTokensDtoToJson(AuthTokensDto instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user.toJson(),
    };

AuthUserDto _$AuthUserDtoFromJson(Map<String, dynamic> json) => AuthUserDto(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      email: json['email'] as String?,
    );

Map<String, dynamic> _$AuthUserDtoToJson(AuthUserDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'role': instance.role,
      'email': instance.email,
    };
