import '../../../../core/utils/json_parsing.dart';

/// A milk delivery row. Backend returns raw `MilkDelivery` entity fields
/// (camelCase) from most endpoints; the `today` listings additionally join
/// customer name/mobile/address and an `expectedQuantity` total.
class DeliveryModel {
  const DeliveryModel({
    required this.id,
    required this.customerId,
    this.customerUserId,
    required this.subscriptionId,
    this.farmId,
    required this.deliveryDate,
    required this.deliveryShift,
    required this.status,
    required this.confirmationStatus,
    required this.scheduledQuantity,
    required this.customerExtraQuantity,
    required this.staffExtraQuantity,
    this.finalDeliveredQuantity,
    required this.quantity,
    required this.expectedQuantity,
    required this.ratePerLitre,
    required this.amount,
    this.productName,
    this.milkType,
    this.notes,
    this.deliveryNotes,
    this.deliveredAt,
    this.customerName,
    this.mobileNumber,
    this.address,
    this.latitude,
    this.longitude,
    this.hasMapPin = false,
    this.deliverySequence,
    this.isEdited = false,
    this.editReviewStatus = 'NOT_REQUIRED',
  });

  final String id;
  final String customerId;
  final String? customerUserId;
  final String subscriptionId;
  final String? farmId;
  final String deliveryDate;
  final String deliveryShift;
  final String status;
  final String confirmationStatus;
  final String scheduledQuantity;
  final String customerExtraQuantity;
  final String staffExtraQuantity;
  final String? finalDeliveredQuantity;
  final String quantity;
  final String expectedQuantity;
  final String ratePerLitre;
  final String amount;
  final String? productName;
  final String? milkType;
  final String? notes;
  final String? deliveryNotes;
  final DateTime? deliveredAt;
  final String? customerName;
  final String? mobileNumber;
  final String? address;
  final String? latitude;
  final String? longitude;
  final bool hasMapPin;
  final int? deliverySequence;
  final bool isEdited;
  final String editReviewStatus;

  bool get isPending => status == 'PENDING';
  bool get isOutForDelivery => status == 'OUT_FOR_DELIVERY';
  bool get isDelivered => status == 'DELIVERED';
  bool get isOpen => isPending || isOutForDelivery;
  bool get isClosed => !isOpen;
  bool get hasExactPin =>
      hasMapPin ||
      ((latitude != null && latitude!.isNotEmpty) &&
          (longitude != null && longitude!.isNotEmpty));

  double? get latitudeValue => double.tryParse(latitude ?? '');
  double? get longitudeValue => double.tryParse(longitude ?? '');

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    final scheduled = asStringOr(json['scheduledQuantity'], '0');
    final customerExtra = asStringOr(json['customerExtraQuantity'], '0');
    final staffExtra = asStringOr(json['staffExtraQuantity'], '0');
    final expected = asStringOrNull(json['expectedQuantity']) ??
        _sumQty(scheduled, customerExtra, staffExtra);
    return DeliveryModel(
      id: asStringOr(json['id']),
      customerId: asStringOr(json['customerId']),
      customerUserId: asStringOrNull(json['customerUserId']),
      subscriptionId: asStringOr(json['subscriptionId']),
      farmId: asStringOrNull(json['farmId']),
      deliveryDate: asStringOr(json['deliveryDate']),
      deliveryShift: asStringOr(json['deliveryShift'], 'MORNING'),
      status: asStringOr(json['status'], 'PENDING'),
      confirmationStatus:
          asStringOr(json['confirmationStatus'], 'NOT_CONFIRMED'),
      scheduledQuantity: scheduled,
      customerExtraQuantity: customerExtra,
      staffExtraQuantity: staffExtra,
      finalDeliveredQuantity: asStringOrNull(json['finalDeliveredQuantity']),
      quantity: asStringOr(json['quantity'], '0'),
      expectedQuantity: expected,
      ratePerLitre: asStringOr(json['ratePerLitre'], '0'),
      amount: asStringOr(json['amount'], '0'),
      productName: asStringOrNull(json['productName']) ??
          asStringOrNull(json['milkTypeLabel']),
      milkType: asStringOrNull(json['milkType']) ??
          asStringOrNull((json['subscription'] as Map?)?['milkType']),
      notes: asStringOrNull(json['notes']),
      deliveryNotes: asStringOrNull(json['deliveryNotes']),
      deliveredAt: parseDateTime(json['deliveredAt']),
      customerName: asStringOrNull(json['customerName']) ??
          asStringOrNull((json['customer'] as Map?)?['name']),
      mobileNumber: asStringOrNull(json['mobileNumber']) ??
          asStringOrNull((json['customer'] as Map?)?['mobileNumber']),
      address: asStringOrNull(json['address']) ??
          asStringOrNull((json['customer'] as Map?)?['address']),
      latitude: asStringOrNull(json['latitude']),
      longitude: asStringOrNull(json['longitude']),
      hasMapPin: asBool(json['hasMapPin']),
      deliverySequence: json['deliverySequence'] == null
          ? null
          : asInt(json['deliverySequence']),
      isEdited: asBool(json['isEdited']),
      editReviewStatus: asStringOr(json['editReviewStatus'], 'NOT_REQUIRED'),
    );
  }

  static String _sumQty(String a, String b, String c) {
    final total = (num.tryParse(a) ?? 0) +
        (num.tryParse(b) ?? 0) +
        (num.tryParse(c) ?? 0);
    return total.toString();
  }
}

class DeliveryEventModel {
  const DeliveryEventModel({
    required this.id,
    required this.eventType,
    this.actorRole,
    this.previousStatus,
    this.newStatus,
    this.quantity,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String eventType;
  final String? actorRole;
  final String? previousStatus;
  final String? newStatus;
  final String? quantity;
  final String? notes;
  final DateTime createdAt;

  factory DeliveryEventModel.fromJson(Map<String, dynamic> json) =>
      DeliveryEventModel(
        id: asStringOr(json['id']),
        eventType: asStringOr(json['eventType']),
        actorRole: asStringOrNull(json['actorRole']),
        previousStatus: asStringOrNull(json['previousStatus']),
        newStatus: asStringOrNull(json['newStatus']),
        quantity: asStringOrNull(json['quantity']),
        notes: asStringOrNull(json['notes']),
        createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      );
}

class StaffCustomerSummary {
  const StaffCustomerSummary({
    required this.customerId,
    this.customerUserId,
    required this.name,
    this.mobileNumber,
    this.addressSummary,
    required this.milkType,
    required this.regularQuantity,
    required this.deliveryShift,
    required this.subscriptionStatus,
    required this.subscriptionId,
    this.farmId,
    required this.scheduledToday,
    required this.extraQuantityRequested,
    required this.staffExtraQuantity,
    required this.todayTotalQuantity,
    required this.todayStatus,
    this.deliveryId,
    this.balance,
    this.canViewCustomerBalance = true,
  });

  final String customerId;
  final String? customerUserId;
  final String name;
  final String? mobileNumber;
  final String? addressSummary;
  final String milkType;
  final String regularQuantity;
  final String deliveryShift;
  final String subscriptionStatus;
  final String subscriptionId;
  final String? farmId;
  final bool scheduledToday;
  final String extraQuantityRequested;
  final String staffExtraQuantity;
  final String todayTotalQuantity;
  final String todayStatus;
  final String? deliveryId;
  final String? balance;
  final bool canViewCustomerBalance;

  bool get hasOpenDelivery =>
      deliveryId != null &&
      (todayStatus == 'PENDING' || todayStatus == 'OUT_FOR_DELIVERY');

  factory StaffCustomerSummary.fromJson(Map<String, dynamic> json) =>
      StaffCustomerSummary(
        customerId: asStringOr(json['customerId']),
        customerUserId: asStringOrNull(json['customerUserId']),
        name: asStringOr(json['name'], 'Customer'),
        mobileNumber: asStringOrNull(json['mobileNumber']),
        addressSummary: asStringOrNull(json['addressSummary']),
        milkType: asStringOr(json['milkType']),
        regularQuantity: asStringOr(json['regularQuantity'], '0'),
        deliveryShift: asStringOr(json['deliveryShift'], 'MORNING'),
        subscriptionStatus: asStringOr(json['subscriptionStatus']),
        subscriptionId: asStringOr(json['subscriptionId']),
        farmId: asStringOrNull(json['farmId']),
        scheduledToday: asBool(json['scheduledToday']),
        extraQuantityRequested: asStringOr(json['extraQuantityRequested'], '0'),
        staffExtraQuantity: asStringOr(json['staffExtraQuantity'], '0'),
        todayTotalQuantity: asStringOr(json['todayTotalQuantity'], '0'),
        todayStatus: asStringOr(json['todayStatus'], 'NONE'),
        deliveryId: asStringOrNull(json['deliveryId']),
        balance: asStringOrNull(json['balance']),
        canViewCustomerBalance:
            asBool(json['canViewCustomerBalance'], fallback: true),
      );
}

class FarmDeliveryPermissions {
  const FarmDeliveryPermissions({
    required this.canViewCustomerBalance,
    required this.canViewBillingSummary,
    required this.canRecordCashPayment,
    required this.canViewPaymentHistory,
    required this.deliveryStaffCanApproveExtraRequests,
  });

  final bool canViewCustomerBalance;
  final bool canViewBillingSummary;
  final bool canRecordCashPayment;
  final bool canViewPaymentHistory;
  final bool deliveryStaffCanApproveExtraRequests;

  factory FarmDeliveryPermissions.fromJson(Map<String, dynamic> json) =>
      FarmDeliveryPermissions(
        canViewCustomerBalance:
            asBool(json['canViewCustomerBalance'], fallback: true),
        canViewBillingSummary:
            asBool(json['canViewBillingSummary'], fallback: true),
        canRecordCashPayment: asBool(json['canRecordCashPayment']),
        canViewPaymentHistory: asBool(json['canViewPaymentHistory']),
        deliveryStaffCanApproveExtraRequests:
            asBool(json['deliveryStaffCanApproveExtraRequests']),
      );
}

class BillingSummaryModel {
  const BillingSummaryModel({
    required this.todaysAmount,
    required this.monthDeliveredDays,
    required this.monthRegularQuantity,
    required this.monthExtraQuantity,
    required this.monthTotalQuantity,
    required this.monthMilkCharges,
    required this.previousBalance,
    required this.paymentsThisMonth,
    required this.outstandingBalance,
    required this.billTillToday,
    required this.advanceBalance,
  });

  final String todaysAmount;
  final int monthDeliveredDays;
  final String monthRegularQuantity;
  final String monthExtraQuantity;
  final String monthTotalQuantity;
  final String monthMilkCharges;
  final String previousBalance;
  final String paymentsThisMonth;
  final String outstandingBalance;
  final String billTillToday;
  final String advanceBalance;

  factory BillingSummaryModel.fromJson(Map<String, dynamic> json) =>
      BillingSummaryModel(
        todaysAmount: asStringOr(json['todaysAmount'], '0'),
        monthDeliveredDays: asInt(json['monthDeliveredDays']),
        monthRegularQuantity: asStringOr(json['monthRegularQuantity'], '0'),
        monthExtraQuantity: asStringOr(json['monthExtraQuantity'], '0'),
        monthTotalQuantity: asStringOr(json['monthTotalQuantity'], '0'),
        monthMilkCharges: asStringOr(json['monthMilkCharges'], '0'),
        previousBalance: asStringOr(json['previousBalance'], '0'),
        paymentsThisMonth: asStringOr(json['paymentsThisMonth'], '0'),
        outstandingBalance: asStringOr(json['outstandingBalance'], '0'),
        billTillToday: asStringOr(json['billTillToday'], '0'),
        advanceBalance: asStringOr(json['advanceBalance'], '0'),
      );
}

class StaffCustomerDetail {
  const StaffCustomerDetail({
    required this.customerId,
    required this.name,
    this.mobileNumber,
    this.address,
    this.notes,
    this.customerUserId,
    this.permissions,
    required this.today,
    required this.subscriptions,
    this.billing,
  });

  final String customerId;
  final String name;
  final String? mobileNumber;
  final String? address;
  final String? notes;
  final String? customerUserId;
  final FarmDeliveryPermissions? permissions;
  final List<DeliveryModel> today;
  final List<Map<String, dynamic>> subscriptions;
  final BillingSummaryModel? billing;

  factory StaffCustomerDetail.fromJson(Map<String, dynamic> json) {
    final customer =
        (json['customer'] as Map?)?.cast<String, dynamic>() ?? const {};
    final permissionsJson =
        (json['permissions'] as Map?)?.cast<String, dynamic>();
    final billingJson = (json['billing'] as Map?)?.cast<String, dynamic>();
    return StaffCustomerDetail(
      customerId: asStringOr(customer['id']),
      name: asStringOr(customer['name'], 'Customer'),
      mobileNumber: asStringOrNull(customer['mobileNumber']),
      address: asStringOrNull(customer['address']),
      notes: asStringOrNull(customer['notes']),
      customerUserId: asStringOrNull(customer['customerUserId']),
      permissions: permissionsJson == null
          ? null
          : FarmDeliveryPermissions.fromJson(permissionsJson),
      today: asMapList(json['today']).map(DeliveryModel.fromJson).toList(),
      subscriptions: asMapList(json['subscriptions']),
      billing: billingJson == null
          ? null
          : BillingSummaryModel.fromJson(billingJson),
    );
  }
}

class DashboardNotificationItem {
  const DashboardNotificationItem({
    required this.recipientId,
    this.readAt,
    required this.title,
    required this.body,
    this.route,
    this.data = const {},
  });

  final String recipientId;
  final DateTime? readAt;
  final String title;
  final String body;
  final String? route;
  final Map<String, dynamic> data;

  factory DashboardNotificationItem.fromJson(Map<String, dynamic> json) {
    final notification =
        (json['notification'] as Map?)?.cast<String, dynamic>() ?? const {};
    return DashboardNotificationItem(
      recipientId: asStringOr(json['recipientId']),
      readAt: parseDateTime(json['readAt']),
      title: asStringOr(notification['title'], 'Notification'),
      body: asStringOr(notification['body']),
      route: asStringOrNull(notification['route']),
      data: (notification['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

class DeliveryStaffDashboard {
  const DeliveryStaffDashboard({
    required this.date,
    required this.todaysCustomers,
    required this.pending,
    required this.outForDelivery,
    required this.delivered,
    required this.skipped,
    required this.failed,
    required this.disputed,
    required this.extraRequests,
    required this.plannedLitres,
    required this.deliveredLitres,
    required this.cashToCollect,
    required this.paymentsCollectedToday,
    required this.recentNotifications,
    this.permissions,
  });

  final String date;
  final int todaysCustomers;
  final int pending;
  final int outForDelivery;
  final int delivered;
  final int skipped;
  final int failed;
  final int disputed;
  final int extraRequests;
  final String plannedLitres;
  final String deliveredLitres;
  final String cashToCollect;
  final String paymentsCollectedToday;
  final List<DashboardNotificationItem> recentNotifications;
  final FarmDeliveryPermissions? permissions;

  int get totalToday =>
      pending + outForDelivery + delivered + skipped + failed + disputed;

  factory DeliveryStaffDashboard.fromJson(Map<String, dynamic> json) {
    final permissionsJson =
        (json['permissions'] as Map?)?.cast<String, dynamic>();
    return DeliveryStaffDashboard(
      date: asStringOr(json['date']),
      todaysCustomers: asInt(json['todaysCustomers']),
      pending: asInt(json['pending']),
      outForDelivery: asInt(json['outForDelivery']),
      delivered: asInt(json['delivered']),
      skipped: asInt(json['skipped']),
      failed: asInt(json['failed']),
      disputed: asInt(json['disputed']),
      extraRequests: asInt(json['extraRequests']),
      plannedLitres: asStringOr(json['plannedLitres'], '0'),
      deliveredLitres: asStringOr(json['deliveredLitres'], '0'),
      cashToCollect: asStringOr(json['cashToCollect'], '0'),
      paymentsCollectedToday: asStringOr(json['paymentsCollectedToday'], '0'),
      permissions: permissionsJson == null
          ? null
          : FarmDeliveryPermissions.fromJson(permissionsJson),
      recentNotifications: asMapList(json['recentNotifications'])
          .map(DashboardNotificationItem.fromJson)
          .toList(),
    );
  }
}

class ExtraRequestModel {
  const ExtraRequestModel({
    required this.id,
    required this.farmId,
    required this.customerUserId,
    required this.subscriptionId,
    this.deliveryId,
    required this.deliveryDate,
    required this.requestedQuantity,
    required this.status,
    this.notes,
    required this.requestedAt,
    this.customerName,
  });

  final String id;
  final String farmId;
  final String customerUserId;
  final String subscriptionId;
  final String? deliveryId;
  final String deliveryDate;
  final String requestedQuantity;
  final String status;
  final String? notes;
  final DateTime requestedAt;
  final String? customerName;

  bool get isPending => status == 'PENDING';

  factory ExtraRequestModel.fromJson(Map<String, dynamic> json) {
    final sub = (json['subscription'] as Map?)?.cast<String, dynamic>();
    return ExtraRequestModel(
      id: asStringOr(json['id']),
      farmId: asStringOr(json['farmId']),
      customerUserId: asStringOr(json['customerUserId']),
      subscriptionId: asStringOr(json['subscriptionId']),
      deliveryId: asStringOrNull(json['deliveryId']),
      deliveryDate: asStringOr(json['deliveryDate']),
      requestedQuantity: asStringOr(json['requestedQuantity'], '0'),
      status: asStringOr(json['status'], 'PENDING'),
      notes: asStringOrNull(json['notes']),
      requestedAt: parseDateTime(json['requestedAt']) ?? DateTime.now(),
      customerName: asStringOrNull(sub?['customerName']),
    );
  }
}

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.customerId,
    this.billId,
    required this.amount,
    required this.paymentMethod,
    this.purpose,
    required this.paymentDate,
    this.notes,
    this.status,
    this.proofImageUrl,
    this.customerName,
    this.rejectionNote,
  });

  final String id;
  final String customerId;
  final String? billId;
  final String amount;
  final String paymentMethod;
  final String? purpose;
  final String paymentDate;
  final String? notes;
  final String? status;
  final String? proofImageUrl;
  final String? customerName;
  final String? rejectionNote;

  bool get isPendingConfirmation => status == 'PENDING_CONFIRMATION';

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: asStringOr(json['id']),
        customerId: asStringOr(json['customerId']),
        billId: asStringOrNull(json['billId']),
        amount: asStringOr(json['amount'], '0'),
        paymentMethod: asStringOr(json['paymentMethod'], 'CASH'),
        purpose: asStringOrNull(json['purpose']),
        paymentDate: asStringOr(json['paymentDate']),
        notes: asStringOrNull(json['notes']),
        status: asStringOrNull(json['status']),
        proofImageUrl: asStringOrNull(json['proofImageUrl']),
        customerName: asStringOrNull(json['customerName']) ??
            asStringOrNull((json['customer'] as Map?)?['name']),
        rejectionNote: asStringOrNull(json['rejectionNote']),
      );
}

class DeliveryRouteStop {
  const DeliveryRouteStop({
    required this.deliveryId,
    required this.customerId,
    required this.customerName,
    this.mobileNumber,
    this.addressId,
    this.address,
    this.area,
    this.latitude,
    this.longitude,
    required this.scheduledQuantity,
    required this.customerExtraQuantity,
    required this.staffExtraQuantity,
    required this.totalExpectedQuantity,
    required this.deliveryShift,
    required this.status,
    this.distanceMeters,
    this.distanceLabel,
    required this.locationAvailable,
    required this.locationVerified,
    required this.sequence,
  });

  final String deliveryId;
  final String customerId;
  final String customerName;
  final String? mobileNumber;
  final String? addressId;
  final String? address;
  final String? area;
  final String? latitude;
  final String? longitude;
  final String scheduledQuantity;
  final String customerExtraQuantity;
  final String staffExtraQuantity;
  final String totalExpectedQuantity;
  final String deliveryShift;
  final String status;
  final int? distanceMeters;
  final String? distanceLabel;
  final bool locationAvailable;
  final bool locationVerified;
  final int sequence;

  bool get isOpen => status == 'PENDING' || status == 'OUT_FOR_DELIVERY';
  bool get isDelivered => status == 'DELIVERED';
  double? get latitudeValue => double.tryParse(latitude ?? '');
  double? get longitudeValue => double.tryParse(longitude ?? '');

  factory DeliveryRouteStop.fromJson(Map<String, dynamic> json) =>
      DeliveryRouteStop(
        deliveryId: asStringOr(json['deliveryId']),
        customerId: asStringOr(json['customerId']),
        customerName: asStringOr(json['customerName'], 'Customer'),
        mobileNumber: asStringOrNull(json['mobileNumber']),
        addressId: asStringOrNull(json['addressId']),
        address: asStringOrNull(json['address']),
        area: asStringOrNull(json['area']),
        latitude: asStringOrNull(json['latitude']),
        longitude: asStringOrNull(json['longitude']),
        scheduledQuantity: asStringOr(json['scheduledQuantity'], '0'),
        customerExtraQuantity: asStringOr(json['customerExtraQuantity'], '0'),
        staffExtraQuantity: asStringOr(json['staffExtraQuantity'], '0'),
        totalExpectedQuantity: asStringOr(json['totalExpectedQuantity'], '0'),
        deliveryShift: asStringOr(json['deliveryShift'], 'MORNING'),
        status: asStringOr(json['status'], 'PENDING'),
        distanceMeters: json['distanceMeters'] == null
            ? null
            : asInt(json['distanceMeters']),
        distanceLabel: asStringOrNull(json['distanceLabel']),
        locationAvailable: asBool(json['locationAvailable']),
        locationVerified: asBool(json['locationVerified']),
        sequence: asInt(json['sequence'], fallback: 0),
      );
}

class DeliveryRouteToday {
  const DeliveryRouteToday({
    required this.date,
    required this.locationOrderingApplied,
    required this.pendingCount,
    required this.completedCount,
    required this.totalMilkRemaining,
    this.estimatedStraightLineLabel,
    this.nextStop,
    required this.stops,
  });

  final String date;
  final bool locationOrderingApplied;
  final int pendingCount;
  final int completedCount;
  final String totalMilkRemaining;
  final String? estimatedStraightLineLabel;
  final DeliveryRouteStop? nextStop;
  final List<DeliveryRouteStop> stops;

  factory DeliveryRouteToday.fromJson(Map<String, dynamic> json) {
    final next = (json['nextStop'] as Map?)?.cast<String, dynamic>();
    return DeliveryRouteToday(
      date: asStringOr(json['date']),
      locationOrderingApplied: asBool(json['locationOrderingApplied']),
      pendingCount: asInt(json['pendingCount']),
      completedCount: asInt(json['completedCount']),
      totalMilkRemaining: asStringOr(json['totalMilkRemaining'], '0'),
      estimatedStraightLineLabel:
          asStringOrNull(json['estimatedStraightLineLabel']),
      nextStop: next == null ? null : DeliveryRouteStop.fromJson(next),
      stops: asMapList(json['stops']).map(DeliveryRouteStop.fromJson).toList(),
    );
  }
}
