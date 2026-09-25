import '../../../../core/utils/json_parsing.dart';

/// A review a farm/delivery-staff left about this customer.
/// `GET /customers/:customerId/reviews` treats the path segment as the
/// customer's *user* id (not a farm-scoped `Customer` row), so a customer
/// can fetch their own reviews with their own user id.
class CustomerReviewModel {
  const CustomerReviewModel({
    required this.id,
    required this.farmId,
    required this.rating,
    this.communicationRating,
    this.addressAccuracyRating,
    this.paymentReliabilityRating,
    this.comment,
    this.customerResponse,
    required this.createdAt,
  });

  final String id;
  final String farmId;
  final int rating;
  final int? communicationRating;
  final int? addressAccuracyRating;
  final int? paymentReliabilityRating;
  final String? comment;
  final String? customerResponse;
  final DateTime createdAt;

  factory CustomerReviewModel.fromJson(Map<String, dynamic> json) =>
      CustomerReviewModel(
        id: asStringOr(json['id']),
        farmId: asStringOr(json['farmId']),
        rating: asInt(json['rating'], fallback: 5),
        communicationRating: json['communicationRating'] == null
            ? null
            : asInt(json['communicationRating']),
        addressAccuracyRating: json['addressAccuracyRating'] == null
            ? null
            : asInt(json['addressAccuracyRating']),
        paymentReliabilityRating: json['paymentReliabilityRating'] == null
            ? null
            : asInt(json['paymentReliabilityRating']),
        comment: asStringOrNull(json['comment']),
        customerResponse: asStringOrNull(json['customerResponse']),
        createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      );
}
