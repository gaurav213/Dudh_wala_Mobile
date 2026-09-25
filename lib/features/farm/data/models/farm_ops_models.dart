import '../../../../core/utils/json_parsing.dart';

class FarmTodayMetrics {
  const FarmTodayMetrics({
    required this.date,
    required this.scheduledQuantity,
    required this.customerExtraQuantity,
    required this.staffExtraQuantity,
    required this.totalExtraQuantity,
    required this.totalDeliveredQuantity,
    required this.pendingCount,
    required this.deliveredCount,
    required this.skippedCount,
    required this.editedDeliveryCount,
    required this.totalCount,
    this.collectionsToday = '0.00',
  });

  final String date;
  final String scheduledQuantity;
  final String customerExtraQuantity;
  final String staffExtraQuantity;
  final String totalExtraQuantity;
  final String totalDeliveredQuantity;
  final int pendingCount;
  final int deliveredCount;
  final int skippedCount;
  final int editedDeliveryCount;
  final int totalCount;
  final String collectionsToday;

  factory FarmTodayMetrics.fromJson(Map<String, dynamic> json) {
    final breakdown = json['extraBreakdown'] as Map?;
    return FarmTodayMetrics(
      date: asStringOr(json['date']),
      scheduledQuantity: asStringOr(json['scheduledQuantity'], '0'),
      customerExtraQuantity: asStringOr(
        json['customerExtraQuantity'] ?? breakdown?['customerRequested'],
        '0',
      ),
      staffExtraQuantity: asStringOr(
        json['staffExtraQuantity'] ?? breakdown?['staffAdded'],
        '0',
      ),
      totalExtraQuantity: asStringOr(
        json['totalExtraQuantity'] ?? breakdown?['total'],
        '0',
      ),
      totalDeliveredQuantity: asStringOr(json['totalDeliveredQuantity'], '0'),
      pendingCount: asInt(json['pendingCount']),
      deliveredCount: asInt(json['deliveredCount']),
      skippedCount: asInt(json['skippedCount']),
      editedDeliveryCount: asInt(json['editedDeliveryCount']),
      totalCount: asInt(json['totalCount']),
      collectionsToday: asStringOr(json['collectionsToday'], '0.00'),
    );
  }
}

class StaffDetailModel {
  const StaffDetailModel({
    required this.profile,
    required this.today,
    required this.lifetimeDeliveryCount,
    required this.editStats,
    required this.memberId,
  });

  final StaffProfileModel profile;
  final StaffTodaySummary today;
  final int lifetimeDeliveryCount;
  final StaffEditStats editStats;
  final String memberId;

  factory StaffDetailModel.fromJson(Map<String, dynamic> json) {
    final member = json['member'] as Map<String, dynamic>? ?? const {};
    final profile = json['profile'] as Map<String, dynamic>? ?? const {};
    final today = json['today'] as Map<String, dynamic>? ?? const {};
    final editStats = json['editStats'] as Map<String, dynamic>? ?? const {};
    return StaffDetailModel(
      memberId: asStringOr(member['id']),
      profile: StaffProfileModel.fromJson(profile),
      today: StaffTodaySummary.fromJson(today),
      lifetimeDeliveryCount: asInt(json['lifetimeDeliveryCount']),
      editStats: StaffEditStats.fromJson(editStats),
    );
  }
}

class StaffProfileModel {
  const StaffProfileModel({
    required this.id,
    required this.name,
    required this.mobileNumber,
    this.email,
    required this.status,
    this.joinedAt,
  });

  final String id;
  final String name;
  final String mobileNumber;
  final String? email;
  final String status;
  final DateTime? joinedAt;

  factory StaffProfileModel.fromJson(Map<String, dynamic> json) =>
      StaffProfileModel(
        id: asStringOr(json['id']),
        name: asStringOr(json['name']),
        mobileNumber: asStringOr(json['mobileNumber']),
        email: asStringOrNull(json['email']),
        status: asStringOr(json['status'], 'ACTIVE'),
        joinedAt: parseDateTime(json['joinedAt']),
      );
}

class StaffTodaySummary {
  const StaffTodaySummary({
    required this.assignedCustomers,
    required this.deliveredCount,
    required this.pendingCount,
    required this.skippedCount,
    required this.scheduledQuantity,
    required this.totalExtraQuantity,
    required this.totalDeliveredQuantity,
    required this.editedDeliveryCount,
    required this.cashCollected,
  });

  final int assignedCustomers;
  final int deliveredCount;
  final int pendingCount;
  final int skippedCount;
  final String scheduledQuantity;
  final String totalExtraQuantity;
  final String totalDeliveredQuantity;
  final int editedDeliveryCount;
  final String cashCollected;

  factory StaffTodaySummary.fromJson(Map<String, dynamic> json) =>
      StaffTodaySummary(
        assignedCustomers:
            asInt(json['assignedCustomers'] ?? json['totalCount']),
        deliveredCount: asInt(json['deliveredCount']),
        pendingCount: asInt(json['pendingCount']),
        skippedCount: asInt(json['skippedCount']),
        scheduledQuantity: asStringOr(json['scheduledQuantity'], '0'),
        totalExtraQuantity: asStringOr(json['totalExtraQuantity'], '0'),
        totalDeliveredQuantity: asStringOr(json['totalDeliveredQuantity'], '0'),
        editedDeliveryCount: asInt(json['editedDeliveryCount']),
        cashCollected: asStringOr(json['cashCollected'], '0.00'),
      );
}

class StaffEditStats {
  const StaffEditStats({
    required this.editedToday,
    required this.editedThisWeek,
    required this.editedThisMonth,
  });

  final int editedToday;
  final int editedThisWeek;
  final int editedThisMonth;

  factory StaffEditStats.fromJson(Map<String, dynamic> json) => StaffEditStats(
        editedToday: asInt(json['editedToday']),
        editedThisWeek: asInt(json['editedThisWeek']),
        editedThisMonth: asInt(json['editedThisMonth']),
      );
}

class StaffTodayDeliveryRow {
  const StaffTodayDeliveryRow({
    required this.id,
    required this.customerId,
    this.customerName,
    this.mobileNumber,
    this.address,
    this.productName,
    required this.scheduledQuantity,
    required this.extraQuantity,
    this.finalDeliveredQuantity,
    required this.status,
    this.deliveredAt,
    required this.isEdited,
    required this.editReviewStatus,
  });

  final String id;
  final String customerId;
  final String? customerName;
  final String? mobileNumber;
  final String? address;
  final String? productName;
  final String scheduledQuantity;
  final String extraQuantity;
  final String? finalDeliveredQuantity;
  final String status;
  final DateTime? deliveredAt;
  final bool isEdited;
  final String editReviewStatus;

  factory StaffTodayDeliveryRow.fromJson(Map<String, dynamic> json) =>
      StaffTodayDeliveryRow(
        id: asStringOr(json['id']),
        customerId: asStringOr(json['customerId']),
        customerName: asStringOrNull(json['customerName']),
        mobileNumber: asStringOrNull(json['mobileNumber']),
        address: asStringOrNull(json['address']),
        productName: asStringOrNull(json['productName']),
        scheduledQuantity: asStringOr(json['scheduledQuantity'], '0'),
        extraQuantity: asStringOr(json['extraQuantity'], '0'),
        finalDeliveredQuantity: asStringOrNull(json['finalDeliveredQuantity']),
        status: asStringOr(json['status'], 'PENDING'),
        deliveredAt: parseDateTime(json['deliveredAt']),
        isEdited: asBool(json['isEdited']),
        editReviewStatus: asStringOr(json['editReviewStatus'], 'NOT_REQUIRED'),
      );
}

class DeliveryEditReviewDetail {
  const DeliveryEditReviewDetail({
    required this.delivery,
    this.customerName,
    this.customerPhone,
    this.staffName,
    this.staffPhone,
    this.previousQuantity,
    this.newQuantity,
    this.previousAmount,
    this.newAmount,
    this.editReason,
    this.editNote,
    required this.events,
  });

  final Map<String, dynamic> delivery;
  final String? customerName;
  final String? customerPhone;
  final String? staffName;
  final String? staffPhone;
  final String? previousQuantity;
  final String? newQuantity;
  final String? previousAmount;
  final String? newAmount;
  final String? editReason;
  final String? editNote;
  final List<Map<String, dynamic>> events;

  factory DeliveryEditReviewDetail.fromJson(Map<String, dynamic> json) {
    final delivery = Map<String, dynamic>.from(json['delivery'] as Map? ?? {});
    final customer = json['customer'] as Map?;
    final staff = json['deliveryStaff'] as Map?;
    final latest = json['latestEdit'] as Map?;
    final events = (json['events'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return DeliveryEditReviewDetail(
      delivery: delivery,
      customerName: asStringOrNull(customer?['name']),
      customerPhone: asStringOrNull(customer?['mobileNumber']),
      staffName: asStringOrNull(staff?['name']),
      staffPhone: asStringOrNull(staff?['mobileNumber']),
      previousQuantity: asStringOrNull(latest?['previousQuantity']),
      newQuantity: asStringOrNull(latest?['newQuantity']),
      previousAmount: asStringOrNull(latest?['previousAmount']),
      newAmount: asStringOrNull(latest?['newAmount']),
      editReason: asStringOrNull(latest?['editReason']),
      editNote: asStringOrNull(latest?['editNote']),
      events: events,
    );
  }
}
