import '../utils/delivery_schedule_helpers.dart';
import '../utils/json_parsing.dart';

/// Shared between the farm-owner and customer marketplace features since
/// both sides read the same `farm_milk_products` / `customer_service_requests`
/// / `farm_customer_invitations` API shapes.

class FarmProductModel {
  const FarmProductModel({
    required this.id,
    required this.name,
    required this.milkType,
    this.description,
    required this.currentRatePerLitre,
    required this.minimumQuantity,
    this.maximumQuantity,
    required this.availableShifts,
    required this.isAvailable,
  });

  final String id;
  final String name;
  final String milkType;
  final String? description;
  final String currentRatePerLitre;
  final String minimumQuantity;
  final String? maximumQuantity;
  final List<String> availableShifts;
  final bool isAvailable;

  factory FarmProductModel.fromJson(Map<String, dynamic> json) =>
      FarmProductModel(
        id: asStringOr(json['id']),
        name: asStringOr(json['name']),
        milkType: asStringOr(json['milkType']),
        description: asStringOrNull(json['description']),
        currentRatePerLitre: asStringOr(json['currentRatePerLitre'], '0'),
        minimumQuantity: asStringOr(json['minimumQuantity'], '0'),
        maximumQuantity: asStringOrNull(json['maximumQuantity']),
        availableShifts: asStringList(json['availableShifts']),
        isAvailable: asBool(json['isAvailable'], fallback: true),
      );
}

class ServiceRequestModel {
  const ServiceRequestModel({
    required this.id,
    required this.farmId,
    required this.customerUserId,
    required this.addressId,
    required this.productId,
    required this.quantity,
    required this.deliveryShift,
    required this.preferredStartDate,
    this.deliveryInstructions,
    required this.status,
    this.rejectionReason,
    this.createdAt,
    this.scheduleType = 'EVERY_DAY',
    this.customerName,
    this.customerMobileNumber,
    this.customerAvatarUrl,
    this.customerAverageRating,
    this.customerReviewCount = 0,
    this.productName,
    this.milkType,
    this.addressSummary,
    this.farmName,
    this.firstDeliveryDate,
    this.nextDeliveryDate,
  });

  final String id;
  final String farmId;
  final String customerUserId;
  final String addressId;
  final String productId;
  final String quantity;
  final String deliveryShift;
  final String preferredStartDate;
  final String? deliveryInstructions;
  final String status;
  final String? rejectionReason;
  final DateTime? createdAt;
  final String scheduleType;
  final String? customerName;
  final String? customerMobileNumber;
  final String? customerAvatarUrl;
  final double? customerAverageRating;
  final int customerReviewCount;
  final String? productName;
  final String? milkType;
  final String? addressSummary;
  final String? farmName;
  final String? firstDeliveryDate;
  final String? nextDeliveryDate;

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';

  String get scheduleLabel => deliveryScheduleLabel(scheduleType);

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) =>
      ServiceRequestModel(
        id: asStringOr(json['id']),
        farmId: asStringOr(json['farmId']),
        customerUserId: asStringOr(json['customerUserId']),
        addressId: asStringOr(json['addressId']),
        productId: asStringOr(json['productId']),
        quantity: asStringOr(json['quantity'], '0'),
        deliveryShift: asStringOr(json['deliveryShift']),
        preferredStartDate: asStringOr(json['preferredStartDate']),
        deliveryInstructions: asStringOrNull(json['deliveryInstructions']),
        status: asStringOr(json['status'], 'PENDING'),
        rejectionReason: asStringOrNull(json['rejectionReason']),
        createdAt: parseDateTime(json['createdAt']),
        scheduleType: asStringOr(json['scheduleType'], 'EVERY_DAY'),
        customerName: asStringOrNull(json['customerName']),
        customerMobileNumber: asStringOrNull(json['customerMobileNumber']),
        customerAvatarUrl: asStringOrNull(json['customerAvatarUrl']),
        customerAverageRating: (json['customerAverageRating'] as num?)?.toDouble(),
        customerReviewCount: asInt(json['customerReviewCount']),
        productName: asStringOrNull(json['productName']),
        milkType: asStringOrNull(json['milkType']),
        addressSummary: asStringOrNull(json['addressSummary']),
        farmName: asStringOrNull(json['farmName']),
        firstDeliveryDate: asStringOrNull(json['firstDeliveryDate']),
        nextDeliveryDate: asStringOrNull(json['nextDeliveryDate']),
      );
}

class CustomerInvitationModel {
  const CustomerInvitationModel({
    required this.id,
    required this.farmId,
    this.farmName,
    this.farmArea,
    this.farmCity,
    required this.mobileNumber,
    this.customerName,
    required this.productId,
    this.productName,
    this.milkType,
    required this.quantity,
    required this.deliveryShift,
    required this.proposedRate,
    required this.preferredStartDate,
    this.deliveryInstructions,
    required this.status,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String farmId;
  final String? farmName;
  final String? farmArea;
  final String? farmCity;
  final String mobileNumber;
  final String? customerName;
  final String productId;
  final String? productName;
  final String? milkType;
  final String quantity;
  final String deliveryShift;
  final String proposedRate;
  final String preferredStartDate;
  final String? deliveryInstructions;
  final String status;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  bool get isPending => status == 'PENDING';
  bool get isExpired =>
      status == 'EXPIRED' ||
      (expiresAt != null && expiresAt!.isBefore(DateTime.now()));

  factory CustomerInvitationModel.fromJson(Map<String, dynamic> json) =>
      CustomerInvitationModel(
        id: asStringOr(json['id']),
        farmId: asStringOr(json['farmId']),
        farmName: asStringOrNull(json['farmName']),
        farmArea: asStringOrNull(json['farmArea']),
        farmCity: asStringOrNull(json['farmCity']),
        mobileNumber: asStringOr(json['mobileNumber']),
        customerName: asStringOrNull(json['customerName']),
        productId: asStringOr(json['productId']),
        productName: asStringOrNull(json['productName']),
        milkType: asStringOrNull(json['milkType']),
        quantity: asStringOr(json['quantity'], '0'),
        deliveryShift: asStringOr(json['deliveryShift']),
        proposedRate: asStringOr(json['proposedRate'], '0'),
        preferredStartDate: asStringOr(json['preferredStartDate']),
        deliveryInstructions: asStringOrNull(json['deliveryInstructions']),
        status: asStringOr(json['status'], 'PENDING'),
        expiresAt: parseDateTime(json['expiresAt']),
        createdAt: parseDateTime(json['createdAt']),
      );
}
