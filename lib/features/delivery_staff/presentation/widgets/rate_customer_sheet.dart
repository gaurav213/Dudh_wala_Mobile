import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/delivery_staff_providers.dart';

/// Opens a bottom sheet letting delivery staff / farm owners rate a
/// customer (communication, address accuracy, payment reliability). Needs
/// `farmId` and `subscriptionId`, which live on the customer's subscriptions
/// — pass them in directly when already loaded (customer detail screen) or
/// via [subscriptions] (raw `MilkSubscription` maps) so this widget can pick
/// the first one itself.
Future<void> showRateCustomerSheet(
  BuildContext context,
  WidgetRef ref, {
  required String customerId,
  required String? customerUserId,
  required String customerName,
  required List<Map<String, dynamic>> subscriptions,
}) async {
  final sub = subscriptions.isNotEmpty ? subscriptions.first : null;
  final farmId = sub?['farmId'] as String?;
  final subscriptionId = sub?['id'] as String?;

  if (customerUserId == null || farmId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).noData)),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Dk.of(context).milkWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _RateCustomerForm(
      farmId: farmId,
      customerUserId: customerUserId,
      customerName: customerName,
      subscriptionId: subscriptionId,
    ),
  );
}

class _RateCustomerForm extends ConsumerStatefulWidget {
  const _RateCustomerForm({
    required this.farmId,
    required this.customerUserId,
    required this.customerName,
    this.subscriptionId,
  });

  final String farmId;
  final String customerUserId;
  final String customerName;
  final String? subscriptionId;

  @override
  ConsumerState<_RateCustomerForm> createState() => _RateCustomerFormState();
}

class _RateCustomerFormState extends ConsumerState<_RateCustomerForm> {
  int _rating = 5;
  int _communication = 5;
  int _addressAccuracy = 5;
  int _paymentReliability = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(deliveryStaffApiProvider).createReview(
            farmId: widget.farmId,
            customerUserId: widget.customerUserId,
            subscriptionId: widget.subscriptionId,
            rating: _rating,
            communicationRating: _communication,
            addressAccuracyRating: _addressAccuracy,
            paymentReliabilityRating: _paymentReliability,
            comment: _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).success)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _starRow(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(width: 140, child: Text(label)),
        for (var i = 1; i <= 5; i++)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              i <= value ? Icons.star : Icons.star_border,
              color: AppColors.warning,
            ),
            onPressed: () => onChanged(i),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${AppLocalizations.of(context).rate} ${widget.customerName}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Dk.of(context).ink, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _starRow(AppLocalizations.of(context).rate, _rating,
                (v) => setState(() => _rating = v)),
            _starRow(AppLocalizations.of(context).details, _communication,
                (v) => setState(() => _communication = v)),
            _starRow(
              AppLocalizations.of(context).address,
              _addressAccuracy,
              (v) => setState(() => _addressAccuracy = v),
            ),
            _starRow(
              AppLocalizations.of(context).payment,
              _paymentReliability,
              (v) => setState(() => _paymentReliability = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).notesOptional,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(AppLocalizations.of(context).submit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
