import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/l10n/delivery_labels.dart';
import '../../../../core/utils/launch_helpers.dart';
import '../../../../core/utils/location_helpers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/delivery_staff_models.dart';

Color deliveryStatusColor(String status) {
  switch (status) {
    case 'DELIVERED':
      return AppColors.success;
    case 'OUT_FOR_DELIVERY':
      return AppColors.teal;
    case 'SKIPPED':
    case 'CANCELLED':
    case 'FAILED':
    case 'DISPUTED':
      return AppColors.danger;
    default:
      return AppColors.warning;
  }
}

String deliveryStatusLabel(BuildContext context, String status) {
  return localizedDeliveryStatus(AppLocalizations.of(context), status);
}

/// A single delivery row for the Today / History lists, with quick call &
/// map actions so staff rarely need to open the full detail screen.
class DeliveryTile extends StatelessWidget {
  const DeliveryTile({
    super.key,
    required this.delivery,
    this.stopNumber,
    this.distanceKm,
    this.onChanged,
  });

  final DeliveryModel delivery;
  final int? stopNumber;
  final double? distanceKm;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final color = deliveryStatusColor(delivery.status);
    final hasPin = delivery.hasExactPin;
    final qty = formatLitres(num.tryParse(delivery.expectedQuantity) ?? 0);
    final amount = formatRupees(num.tryParse(delivery.amount) ?? 0);

    return Material(
      color: Dk.of(context).milkWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(
          AppRoutes.deliveryDeliveryDetail(delivery.id),
          extra: delivery,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: delivery.isOutForDelivery
                  ? AppColors.teal.withValues(alpha: 0.45)
                  : AppColors.leaf.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StopBadge(
                    stopNumber: stopNumber,
                    status: delivery.status,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                delivery.customerName ??
                                    AppLocalizations.of(context).customer,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Dk.of(context).ink,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                deliveryStatusLabel(context, delivery.status),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                            if (delivery.isEdited) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  AppLocalizations.of(context).edit,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$qty · ${delivery.deliveryShift} · $amount",
                          style: TextStyle(
                            color: Dk.of(context).muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if ((delivery.address ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Icon(
                                  Icons.place_outlined,
                                  size: 15,
                                  color: Dk.of(context).muted,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  delivery.address!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Dk.of(context).muted,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          hasPin
                              ? '${AppLocalizations.of(context).map} · '
                                  '${distanceKm == null ? AppLocalizations.of(context).done : LocationHelpers.formatDistance(distanceKm! * 1000)}'
                              : AppLocalizations.of(context).noData,
                          style: TextStyle(
                            color: hasPin ? AppColors.teal : AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          LaunchHelpers.call(context, delivery.mobileNumber),
                      icon: const Icon(Icons.call_outlined, size: 18),
                      label: Text(AppLocalizations.of(context).call),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => LaunchHelpers.openMap(
                        context,
                        address: delivery.address,
                        latitude: delivery.latitudeValue,
                        longitude: delivery.longitudeValue,
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: Text(hasPin
                          ? AppLocalizations.of(context).map
                          : AppLocalizations.of(context).address),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                  if (delivery.isOpen) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => context.push(
                          AppRoutes.deliveryDeliveryDetail(delivery.id),
                          extra: delivery,
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: Text(AppLocalizations.of(context).update),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopBadge extends StatelessWidget {
  const _StopBadge({
    required this.stopNumber,
    required this.status,
    required this.color,
  });

  final int? stopNumber;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = status == 'DELIVERED'
        ? Icons.check_rounded
        : status == 'OUT_FOR_DELIVERY'
            ? Icons.local_shipping_rounded
            : null;

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: icon != null
          ? Icon(icon, color: Colors.white, size: 20)
          : Text(
              "${stopNumber ?? ''}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
    );
  }
}
