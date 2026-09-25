// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
      mobileNumber: json['mobileNumber'] as String,
      password: json['password'] as String,
      deviceId: json['deviceId'] as String?,
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'mobileNumber': instance.mobileNumber,
      'password': instance.password,
      'deviceId': instance.deviceId,
    };

RegisterFarmOwnerRequest _$RegisterFarmOwnerRequestFromJson(
        Map<String, dynamic> json) =>
    RegisterFarmOwnerRequest(
      name: json['name'] as String,
      mobileNumber: json['mobileNumber'] as String,
      password: json['password'] as String,
      farmName: json['farmName'] as String,
      addressLine1: json['addressLine1'] as String,
      area: json['area'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      postalCode: json['postalCode'] as String,
      businessName: json['businessName'] as String?,
      email: json['email'] as String?,
      addressLine2: json['addressLine2'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$RegisterFarmOwnerRequestToJson(
        RegisterFarmOwnerRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'mobileNumber': instance.mobileNumber,
      'password': instance.password,
      'farmName': instance.farmName,
      'businessName': instance.businessName,
      'description': instance.description,
      'email': instance.email,
      'addressLine1': instance.addressLine1,
      'addressLine2': instance.addressLine2,
      'area': instance.area,
      'city': instance.city,
      'state': instance.state,
      'postalCode': instance.postalCode,
    };

RegisterCustomerRequest _$RegisterCustomerRequestFromJson(
        Map<String, dynamic> json) =>
    RegisterCustomerRequest(
      name: json['name'] as String,
      mobileNumber: json['mobileNumber'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$RegisterCustomerRequestToJson(
        RegisterCustomerRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'mobileNumber': instance.mobileNumber,
      'password': instance.password,
    };

AuthTokensDto _$AuthTokensDtoFromJson(Map<String, dynamic> json) =>
    AuthTokensDto(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: json['user'] == null
          ? null
          : AuthUserDto.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthTokensDtoToJson(AuthTokensDto instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
    };

AuthUserDto _$AuthUserDtoFromJson(Map<String, dynamic> json) => AuthUserDto(
      id: json['id'] as String,
      name: json['name'] as String,
      mobileNumber: json['mobileNumber'] as String,
      role: json['role'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$AuthUserDtoToJson(AuthUserDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'mobileNumber': instance.mobileNumber,
      'role': instance.role,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
    };
