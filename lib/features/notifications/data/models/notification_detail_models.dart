import '../../../../core/utils/json_parsing.dart';

class NotificationDetailModel {
  const NotificationDetailModel({
    required this.recipientId,
    required this.readAt,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.context,
  });

  final String recipientId;
  final DateTime? readAt;
  final String type;
  final String title;
  final String body;
  final DateTime? createdAt;
  final NotificationContextModel? context;

  factory NotificationDetailModel.fromJson(Map<String, dynamic> json) {
    final notification =
        (json['notification'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rawContext = json['context'];
    return NotificationDetailModel(
      recipientId: asStringOr(json['recipientId']),
      readAt: parseDateTime(json['readAt']),
      type: asStringOr(notification['type'], 'GENERIC'),
      title: asStringOr(notification['title'], 'Notification'),
      body: asStringOr(notification['body']),
      createdAt: parseDateTime(notification['createdAt']),
      context: rawContext is Map<String, dynamic>
          ? NotificationContextModel.fromJson(rawContext)
          : null,
    );
  }
}

sealed class NotificationContextModel {
  const NotificationContextModel();

  factory NotificationContextModel.fromJson(Map<String, dynamic> json) {
    final kind = asStringOr(json['kind']);
    return switch (kind) {
      'PAYMENT' => PaymentNotificationContext.fromJson(json),
      'DELIVERY' => DeliveryNotificationContext.fromJson(json),
      _ => GenericNotificationContext.fromJson(json),
    };
  }
}

class GenericNotificationContext extends NotificationContextModel {
  const GenericNotificationContext();
  factory GenericNotificationContext.fromJson(Map<String, dynamic> json) =>
      const GenericNotificationContext();
}

class PaymentNotificationContext extends NotificationContextModel {
  const PaymentNotificationContext({
    required this.paymentId,
    required this.amount,
    required this.status,
    required this.paymentDate,
    required this.purpose,
    required this.paymentMethod,
    required this.customerName,
    required this.notes,
    required this.rejectionNote,
    required this.proofImageUrl,
    required this.canConfirmCash,
    required this.canRejectCash,
  });

  final String paymentId;
  final String amount;
  final String status;
  final String paymentDate;
  final String? purpose;
  final String paymentMethod;
  final String? customerName;
  final String? notes;
  final String? rejectionNote;
  final String? proofImageUrl;
  final bool canConfirmCash;
  final bool canRejectCash;

  factory PaymentNotificationContext.fromJson(Map<String, dynamic> json) {
    return PaymentNotificationContext(
      paymentId: asStringOr(json['paymentId']),
      amount: asStringOr(json['amount'], '0'),
      status: asStringOr(json['status'], '—'),
      paymentDate: asStringOr(json['paymentDate']),
      purpose: asStringOrNull(json['purpose']),
      paymentMethod: asStringOr(json['paymentMethod'], 'CASH'),
      customerName: asStringOrNull(json['customerName']),
      notes: asStringOrNull(json['notes']),
      rejectionNote: asStringOrNull(json['rejectionNote']),
      proofImageUrl: asStringOrNull(json['proofImageUrl']),
      canConfirmCash: json['canConfirmCash'] == true,
      canRejectCash: json['canRejectCash'] == true,
    );
  }
}

class DeliveryNotificationContext extends NotificationContextModel {
  const DeliveryNotificationContext({
    required this.deliveryId,
    required this.deliveryDate,
    required this.deliveryShift,
    required this.status,
    required this.confirmationStatus,
    required this.quantity,
    required this.amount,
    required this.customerName,
  });

  final String deliveryId;
  final String deliveryDate;
  final String deliveryShift;
  final String status;
  final String confirmationStatus;
  final String quantity;
  final String amount;
  final String? customerName;

  factory DeliveryNotificationContext.fromJson(Map<String, dynamic> json) {
    return DeliveryNotificationContext(
      deliveryId: asStringOr(json['deliveryId']),
      deliveryDate: asStringOr(json['deliveryDate']),
      deliveryShift: asStringOr(json['deliveryShift']),
      status: asStringOr(json['status'], '—'),
      confirmationStatus: asStringOr(json['confirmationStatus'], '—'),
      quantity: asStringOr(json['quantity'], '0'),
      amount: asStringOr(json['amount'], '0'),
      customerName: asStringOrNull(json['customerName']),
    );
  }
}
