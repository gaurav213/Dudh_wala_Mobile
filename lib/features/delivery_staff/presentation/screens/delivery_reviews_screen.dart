import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/delivery_staff_providers.dart';
import '../widgets/rate_customer_sheet.dart';

/// Lets delivery staff rate the customers on their route (communication,
/// address accuracy, payment reliability). There is no staff-facing "reviews
/// I've written" listing endpoint yet, so this is a rate-from-list screen.
class DeliveryReviewsScreen extends ConsumerWidget {
  const DeliveryReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(deliveryStaffCustomersProvider);

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(AppLocalizations.of(context).rate)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(deliveryStaffCustomersProvider),
        child: customersAsync.when(
          data: (customers) {
            if (customers.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: 80),
                  DkEmpty(message: AppLocalizations.of(context).emptyDefault),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: customers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = customers[i];
                return Material(
                  color: Dk.of(context).milkWhite,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    title: Text(c.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(c.addressSummary ?? c.mobileNumber ?? ''),
                    trailing: OutlinedButton.icon(
                      icon: const Icon(Icons.star_outline, size: 18),
                      label: Text(AppLocalizations.of(context).rate),
                      onPressed: () async {
                        final detail = await ref.read(
                            deliveryStaffCustomerDetailProvider(c.customerId)
                                .future);
                        if (!context.mounted) return;
                        await showRateCustomerSheet(
                          context,
                          ref,
                          customerId: c.customerId,
                          customerUserId:
                              c.customerUserId ?? detail.customerUserId,
                          customerName: c.name,
                          subscriptions: detail.subscriptions,
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              DkEmpty(
                message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
                actionLabel: AppLocalizations.of(context).retry,
                onAction: () => ref.invalidate(deliveryStaffCustomersProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
