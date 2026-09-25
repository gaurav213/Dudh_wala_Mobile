import '../../../../core/models/marketplace_models.dart';
import '../../../../core/utils/json_parsing.dart';

class CustomerAddressModel {
  const CustomerAddressModel({
    required this.id,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.area,
    required this.city,
    required this.state,
    required this.postalCode,
    this.latitude,
    this.longitude,
    this.deliveryInstructions,
    required this.isDefault,
  });

  final String id;
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String area;
  final String city;
  final String state;
  final String postalCode;
  final String? latitude;
  final String? longitude;
  final String? deliveryInstructions;
  final bool isDefault;

  String get shortLine => '$area, $city';

  factory CustomerAddressModel.fromJson(Map<String, dynamic> json) =>
      CustomerAddressModel(
        id: asStringOr(json['id']),
        label: asStringOr(json['label']),
        addressLine1: asStringOr(json['addressLine1']),
        addressLine2: asStringOrNull(json['addressLine2']),
        area: asStringOr(json['area']),
        city: asStringOr(json['city']),
        state: asStringOr(json['state']),
        postalCode: asStringOr(json['postalCode']),
        latitude: asStringOrNull(json['latitude']),
        longitude: asStringOrNull(json['longitude']),
        deliveryInstructions: asStringOrNull(json['deliveryInstructions']),
        isDefault: asBool(json['isDefault']),
      );
}

class FarmSearchConnectionProduct {
  const FarmSearchConnectionProduct({
    required this.name,
    required this.milkType,
  });

  final String name;
  final String milkType;

  factory FarmSearchConnectionProduct.fromJson(Map<String, dynamic> json) =>
      FarmSearchConnectionProduct(
        name: asStringOr(json['name']),
        milkType: asStringOr(json['milkType']),
      );
}

class FarmSearchConnection {
  const FarmSearchConnection({
    required this.connected,
    this.products = const [],
  });

  final bool connected;
  final List<FarmSearchConnectionProduct> products;

  factory FarmSearchConnection.fromJson(Object? json) {
    if (json is! Map) {
      return const FarmSearchConnection(connected: false);
    }
    final map = Map<String, dynamic>.from(json);
    return FarmSearchConnection(
      connected: asBool(map['connected']),
      products: asMapList(map['products'])
          .map(FarmSearchConnectionProduct.fromJson)
          .toList(),
    );
  }
}

class FarmSearchResultModel {
  const FarmSearchResultModel({
    required this.id,
    required this.name,
    this.description,
    required this.area,
    required this.city,
    this.postalCode,
    required this.serviceAreaMatch,
    required this.products,
    this.connection = const FarmSearchConnection(connected: false),
  });

  final String id;
  final String name;
  final String? description;
  final String area;
  final String city;
  final String? postalCode;
  final String serviceAreaMatch;
  final List<FarmProductModel> products;
  final FarmSearchConnection connection;

  factory FarmSearchResultModel.fromJson(Map<String, dynamic> json) =>
      FarmSearchResultModel(
        id: asStringOr(json['id']),
        name: asStringOr(json['name']),
        description: asStringOrNull(json['description']),
        area: asStringOr(json['area']),
        city: asStringOr(json['city']),
        postalCode: asStringOrNull(json['postalCode']),
        serviceAreaMatch: asStringOr(json['serviceAreaMatch'], 'NONE'),
        products:
            asMapList(json['products']).map(FarmProductModel.fromJson).toList(),
        connection: FarmSearchConnection.fromJson(json['connection']),
      );
}

class FarmSearchDiagnosticReason {
  const FarmSearchDiagnosticReason({required this.code, required this.message});

  final String code;
  final String message;

  factory FarmSearchDiagnosticReason.fromJson(Map<String, dynamic> json) =>
      FarmSearchDiagnosticReason(
        code: asStringOr(json['code']),
        message: asStringOr(json['message']),
      );
}

class FarmSearchResponse {
  const FarmSearchResponse(
      {required this.items, required this.total, this.diagnosticReasons});

  final List<FarmSearchResultModel> items;
  final int total;
  final List<FarmSearchDiagnosticReason>? diagnosticReasons;
}

class FarmPublicDetailModel {
  const FarmPublicDetailModel({
    required this.id,
    required this.name,
    this.businessName,
    this.description,
    required this.area,
    required this.city,
    required this.state,
    required this.postalCode,
    this.createdAt,
    this.products = const [],
    this.images = const [],
    this.averageRating,
    this.reviewCount = 0,
    this.reviews = const [],
  });

  final String id;
  final String name;
  final String? businessName;
  final String? description;
  final String area;
  final String city;
  final String state;
  final String postalCode;
  final DateTime? createdAt;
  final List<FarmProductModel> products;
  final List<FarmImageModel> images;
  final double? averageRating;
  final int reviewCount;
  final List<FarmReviewModel> reviews;

  factory FarmPublicDetailModel.fromJson(Map<String, dynamic> json) =>
      FarmPublicDetailModel(
        id: asStringOr(json['id']),
        name: asStringOr(json['name']),
        businessName: asStringOrNull(json['businessName']),
        description: asStringOrNull(json['description']),
        area: asStringOr(json['area']),
        city: asStringOr(json['city']),
        state: asStringOr(json['state']),
        postalCode: asStringOr(json['postalCode']),
        createdAt: parseDateTime(json['createdAt']),
        products:
            asMapList(json['products']).map(FarmProductModel.fromJson).toList(),
        images:
            asMapList(json['images']).map(FarmImageModel.fromJson).toList(),
        averageRating: (json['averageRating'] as num?)?.toDouble(),
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        reviews:
            asMapList(json['reviews']).map(FarmReviewModel.fromJson).toList(),
      );
}

class FarmImageModel {
  const FarmImageModel({
    required this.id,
    required this.url,
    this.sortOrder = 0,
  });

  final String id;
  final String url;
  final int sortOrder;

  factory FarmImageModel.fromJson(Map<String, dynamic> json) => FarmImageModel(
        id: asStringOr(json['id']),
        url: asStringOr(json['url']),
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );
}

class FarmReviewModel {
  const FarmReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  final String id;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  factory FarmReviewModel.fromJson(Map<String, dynamic> json) =>
      FarmReviewModel(
        id: asStringOr(json['id']),
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        comment: asStringOrNull(json['comment']),
        createdAt: parseDateTime(json['createdAt']),
      );
}

/// Navigation payload passed from the search results list to the farm
/// detail screen so the (customer-inaccessible) product catalog doesn't
/// need a second network round-trip.
class CustomerFarmDetailArgs {
  const CustomerFarmDetailArgs({required this.farm, this.addressId});

  final FarmSearchResultModel farm;
  final String? addressId;
}
