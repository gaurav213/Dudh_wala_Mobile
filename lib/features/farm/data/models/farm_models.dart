import '../../../../core/utils/json_parsing.dart';

class FarmModel {
  const FarmModel({
    required this.id,
    required this.name,
    this.businessName,
    this.description,
    this.email,
    required this.addressLine1,
    this.addressLine2,
    required this.area,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.status,
    this.createdAt,
    this.spokenLanguages = const [],
  });

  final String id;
  final String name;
  final String? businessName;
  final String? description;
  final String? email;
  final String addressLine1;
  final String? addressLine2;
  final String area;
  final String city;
  final String state;
  final String postalCode;
  final String status;
  final DateTime? createdAt;
  final List<String> spokenLanguages;

  bool get isActive => status == 'ACTIVE';
  bool get isPendingApproval => status == 'PENDING_APPROVAL';

  factory FarmModel.fromJson(Map<String, dynamic> json) => FarmModel(
        id: asStringOr(json['id']),
        name: asStringOr(json['name']),
        businessName: asStringOrNull(json['businessName']),
        description: asStringOrNull(json['description']),
        email: asStringOrNull(json['email']),
        addressLine1: asStringOr(json['addressLine1']),
        addressLine2: asStringOrNull(json['addressLine2']),
        area: asStringOr(json['area']),
        city: asStringOr(json['city']),
        state: asStringOr(json['state']),
        postalCode: asStringOr(json['postalCode']),
        status: asStringOr(json['status'], 'PENDING_APPROVAL'),
        createdAt: parseDateTime(json['createdAt']),
        spokenLanguages: asStringList(json['spokenLanguages']),
      );
}

class FarmImageItem {
  const FarmImageItem({
    required this.id,
    required this.url,
    this.sortOrder = 0,
  });

  final String id;
  final String url;
  final int sortOrder;

  factory FarmImageItem.fromJson(Map<String, dynamic> json) => FarmImageItem(
        id: asStringOr(json['id']),
        url: asStringOr(json['url']),
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );
}

class FarmSummary {
  const FarmSummary({
    required this.id,
    required this.name,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String name;
  final String status;
  final DateTime? createdAt;

  bool get isActive => status == 'ACTIVE';
  bool get isPendingApproval => status == 'PENDING_APPROVAL';

  factory FarmSummary.fromJson(Map<String, dynamic> json) => FarmSummary(
        id: asStringOr(json['id']),
        name: asStringOr(json['name']),
        status: asStringOr(json['status'], 'PENDING_APPROVAL'),
        createdAt: parseDateTime(json['createdAt']),
      );
}

class FarmDashboardCounts {
  const FarmDashboardCounts({
    required this.serviceAreas,
    required this.activeServiceAreas,
    required this.products,
    required this.availableProducts,
    required this.staff,
    required this.connections,
    required this.pendingServiceRequests,
    required this.pendingCustomerInvitations,
    required this.pendingMemberInvitations,
    required this.todayDeliveries,
    required this.outstandingBalance,
    this.advanceBalance = '0',
  });

  final int serviceAreas;
  final int activeServiceAreas;
  final int products;
  final int availableProducts;
  final int staff;
  final int connections;
  final int pendingServiceRequests;
  final int pendingCustomerInvitations;
  final int pendingMemberInvitations;
  final int todayDeliveries;
  final String outstandingBalance;
  final String advanceBalance;

  factory FarmDashboardCounts.fromJson(Map<String, dynamic> json) =>
      FarmDashboardCounts(
        serviceAreas: asInt(json['serviceAreas']),
        activeServiceAreas: asInt(json['activeServiceAreas']),
        products: asInt(json['products']),
        availableProducts: asInt(json['availableProducts']),
        staff: asInt(json['staff']),
        connections: asInt(json['connections']),
        pendingServiceRequests: asInt(json['pendingServiceRequests']),
        pendingCustomerInvitations: asInt(json['pendingCustomerInvitations']),
        pendingMemberInvitations: asInt(json['pendingMemberInvitations']),
        todayDeliveries: asInt(json['todayDeliveries']),
        outstandingBalance: asStringOr(json['outstandingBalance'], '0'),
        advanceBalance: asStringOr(json['advanceBalance'], '0'),
      );
}

class FarmOnboardingChecklist {
  const FarmOnboardingChecklist({
    required this.isApproved,
    required this.hasServiceArea,
    required this.hasProduct,
    required this.hasStaff,
    required this.profileComplete,
  });

  final bool isApproved;
  final bool hasServiceArea;
  final bool hasProduct;
  final bool hasStaff;
  final bool profileComplete;

  factory FarmOnboardingChecklist.fromJson(Map<String, dynamic> json) =>
      FarmOnboardingChecklist(
        isApproved: asBool(json['isApproved']),
        hasServiceArea: asBool(json['hasServiceArea']),
        hasProduct: asBool(json['hasProduct']),
        hasStaff: asBool(json['hasStaff']),
        profileComplete: asBool(json['profileComplete']),
      );
}

class FarmMoneySummary {
  const FarmMoneySummary({
    this.fromDate,
    this.toDate,
    this.asOfDate,
    required this.madeInRange,
    required this.collectedInRange,
    required this.madeToday,
    required this.madeThisWeek,
    required this.madeThisMonth,
    required this.collectedToday,
    required this.collectedThisWeek,
    required this.collectedThisMonth,
    required this.toCollect,
    this.advanceBalance = '0',
  });

  final String? fromDate;
  final String? toDate;
  final String? asOfDate;
  final String madeInRange;
  final String collectedInRange;
  final String madeToday;
  final String madeThisWeek;
  final String madeThisMonth;
  final String collectedToday;
  final String collectedThisWeek;
  final String collectedThisMonth;
  final String toCollect;
  final String advanceBalance;

  bool get isRange =>
      fromDate != null && toDate != null && fromDate != toDate;

  factory FarmMoneySummary.fromJson(Map<String, dynamic>? json) {
    final m = json ?? const {};
    final inRange = asStringOr(m['madeInRange'], asStringOr(m['madeToday'], '0'));
    final collected = asStringOr(
      m['collectedInRange'],
      asStringOr(m['collectedToday'], '0'),
    );
    return FarmMoneySummary(
      fromDate: asStringOrNull(m['fromDate']),
      toDate: asStringOrNull(m['toDate']),
      asOfDate: asStringOrNull(m['asOfDate']),
      madeInRange: inRange,
      collectedInRange: collected,
      madeToday: asStringOr(m['madeToday'], inRange),
      madeThisWeek: asStringOr(m['madeThisWeek'], '0'),
      madeThisMonth: asStringOr(m['madeThisMonth'], '0'),
      collectedToday: asStringOr(m['collectedToday'], collected),
      collectedThisWeek: asStringOr(m['collectedThisWeek'], '0'),
      collectedThisMonth: asStringOr(m['collectedThisMonth'], '0'),
      toCollect: asStringOr(m['toCollect'], '0'),
      advanceBalance: asStringOr(m['advanceBalance'], '0'),
    );
  }
}

class FarmDashboard {
  const FarmDashboard({
    required this.farm,
    required this.profileCompletionPercent,
    required this.counts,
    required this.money,
    required this.checklist,
  });

  final FarmSummary farm;
  final int profileCompletionPercent;
  final FarmDashboardCounts counts;
  final FarmMoneySummary money;
  final FarmOnboardingChecklist checklist;

  factory FarmDashboard.fromJson(Map<String, dynamic> json) => FarmDashboard(
        farm: FarmSummary.fromJson(
          (json['farm'] as Map<String, dynamic>?) ?? const {},
        ),
        profileCompletionPercent: asInt(json['profileCompletionPercent']),
        counts: FarmDashboardCounts.fromJson(
          (json['counts'] as Map<String, dynamic>?) ?? const {},
        ),
        money: FarmMoneySummary.fromJson(
          json['money'] as Map<String, dynamic>?,
        ),
        checklist: FarmOnboardingChecklist.fromJson(
          (json['onboardingChecklist'] as Map<String, dynamic>?) ?? const {},
        ),
      );
}

class FarmServiceAreaModel {
  const FarmServiceAreaModel({
    required this.id,
    required this.areaName,
    required this.city,
    required this.state,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.serviceRadiusKm,
    required this.status,
  });

  final String id;
  final String areaName;
  final String city;
  final String state;
  final String? postalCode;
  final String? latitude;
  final String? longitude;
  final String? serviceRadiusKm;
  final String status;

  bool get isActive => status == 'ACTIVE';

  factory FarmServiceAreaModel.fromJson(Map<String, dynamic> json) =>
      FarmServiceAreaModel(
        id: asStringOr(json['id']),
        areaName: asStringOr(json['areaName']),
        city: asStringOr(json['city']),
        state: asStringOr(json['state']),
        postalCode: asStringOrNull(json['postalCode']),
        latitude: asStringOrNull(json['latitude']),
        longitude: asStringOrNull(json['longitude']),
        serviceRadiusKm: asStringOrNull(json['serviceRadiusKm']),
        status: asStringOr(json['status'], 'ACTIVE'),
      );
}

class FarmMemberModel {
  const FarmMemberModel({
    required this.id,
    required this.userId,
    required this.memberRole,
    required this.status,
    this.userName,
    this.userMobile,
    this.joinedAt,
  });

  final String id;
  final String userId;
  final String memberRole;
  final String status;
  final String? userName;
  final String? userMobile;
  final DateTime? joinedAt;

  bool get isOwner => memberRole == 'OWNER';
  bool get isActive => status == 'ACTIVE';

  factory FarmMemberModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return FarmMemberModel(
      id: asStringOr(json['id']),
      userId: asStringOr(json['userId']),
      memberRole: asStringOr(json['memberRole']),
      status: asStringOr(json['status']),
      userName: asStringOrNull(user?['name']),
      userMobile: asStringOrNull(user?['mobileNumber']),
      joinedAt: parseDateTime(json['joinedAt']),
    );
  }
}

class FarmStaffInvitationModel {
  const FarmStaffInvitationModel({
    required this.id,
    required this.mobileNumber,
    this.name,
    required this.status,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String mobileNumber;
  final String? name;
  final String status;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  bool get isPending => status == 'PENDING';

  factory FarmStaffInvitationModel.fromJson(Map<String, dynamic> json) =>
      FarmStaffInvitationModel(
        id: asStringOr(json['id']),
        mobileNumber: asStringOr(json['mobileNumber']),
        name: asStringOrNull(json['name']),
        status: asStringOr(json['status'], 'PENDING'),
        expiresAt: parseDateTime(json['expiresAt']),
        createdAt: parseDateTime(json['createdAt']),
      );
}

class ConnectedCustomerModel {
  const ConnectedCustomerModel({
    required this.id,
    this.customerUserId,
    required this.status,
    this.source = 'CONNECTION',
    this.ledgerCustomerId,
    this.connectedAt,
    this.name,
    this.mobileNumber,
    this.subscriptions = const [],
  });

  final String id;
  final String? customerUserId;
  final String status;
  /// CONNECTION | MANAGED
  final String source;
  final String? ledgerCustomerId;
  final DateTime? connectedAt;
  final String? name;
  final String? mobileNumber;
  final List<ConnectionSubscriptionModel> subscriptions;

  bool get isManaged => source == 'MANAGED' || customerUserId == null;

  factory ConnectedCustomerModel.fromJson(Map<String, dynamic> json) {
    final user = json['customerUser'] as Map<String, dynamic>?;
    final subsRaw = json['subscriptions'];
    final subs = subsRaw is List
        ? subsRaw
            .whereType<Map>()
            .map((e) => ConnectionSubscriptionModel.fromJson(
                Map<String, dynamic>.from(e)))
            .toList()
        : <ConnectionSubscriptionModel>[];
    return ConnectedCustomerModel(
      id: asStringOr(json['id']),
      customerUserId: asStringOrNull(json['customerUserId']),
      status: asStringOr(json['status'], 'ACTIVE'),
      source: asStringOr(json['source'], 'CONNECTION'),
      ledgerCustomerId: asStringOrNull(json['ledgerCustomerId']),
      connectedAt: parseDateTime(json['connectedAt']),
      name: asStringOrNull(json['name']) ?? asStringOrNull(user?['name']),
      mobileNumber: asStringOrNull(json['mobileNumber']) ??
          asStringOrNull(user?['mobileNumber']),
      subscriptions: subs,
    );
  }
}

class ConnectionSubscriptionModel {
  const ConnectionSubscriptionModel({
    required this.id,
    required this.milkType,
    required this.defaultQuantity,
    required this.deliveryShift,
    required this.ratePerLitre,
    this.assignedDeliveryUserId,
    this.assignedDeliveryUserName,
    required this.status,
    required this.startDate,
  });

  final String id;
  final String milkType;
  final String defaultQuantity;
  final String deliveryShift;
  final String ratePerLitre;
  final String? assignedDeliveryUserId;
  final String? assignedDeliveryUserName;
  final String status;
  final String startDate;

  factory ConnectionSubscriptionModel.fromJson(Map<String, dynamic> json) =>
      ConnectionSubscriptionModel(
        id: asStringOr(json['id']),
        milkType: asStringOr(json['milkType']),
        defaultQuantity: asStringOr(json['defaultQuantity'], '0'),
        deliveryShift: asStringOr(json['deliveryShift']),
        ratePerLitre: asStringOr(json['ratePerLitre'], '0'),
        assignedDeliveryUserId: asStringOrNull(json['assignedDeliveryUserId']),
        assignedDeliveryUserName:
            asStringOrNull(json['assignedDeliveryUserName']),
        status: asStringOr(json['status']),
        startDate: asStringOr(json['startDate']),
      );
}
