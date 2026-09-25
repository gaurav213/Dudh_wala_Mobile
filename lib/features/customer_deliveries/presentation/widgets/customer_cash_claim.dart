import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../customer_marketplace/presentation/providers/customer_ledger_providers.dart';
import '../providers/customer_deliveries_providers.dart';

/// Desktop image_picker has no system camera UI unless a cameraDelegate is set.
bool get _supportsNativeCamera {
  if (kIsWeb) return true;
  return Platform.isAndroid || Platform.isIOS;
}

/// Month billing strip + "Report cash given" — shared by dashboard and billing.
class CustomerBillingMonthStrip extends ConsumerWidget {
  const CustomerBillingMonthStrip({
    super.key,
    required this.summary,
    this.leafStyle = false,
    this.onOpenBilling,
  });

  final Map<String, dynamic> summary;
  final bool leafStyle;
  final VoidCallback? onOpenBilling;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final todayAmount = num.tryParse('${summary['todaysAmount'] ?? 0}') ?? 0;
    final paid = num.tryParse('${summary['paymentsThisMonth'] ?? 0}') ?? 0;
    final remaining = num.tryParse('${summary['billTillToday'] ?? 0}') ?? 0;
    final advance = num.tryParse('${summary['advanceBalance'] ?? 0}') ?? 0;
    final pendingCash =
        num.tryParse('${summary['pendingCashThisMonth'] ?? 0}') ?? 0;
    final milkCharges =
        num.tryParse('${summary['monthMilkCharges'] ?? 0}') ?? 0;
    final previousDues =
        num.tryParse('${summary['previousBalance'] ?? 0}') ?? 0;
    final litres = '${summary['monthTotalQuantity'] ?? 0}';
    final extra = '${summary['monthExtraQuantity'] ?? 0}';
    final now = DateTime.now();
    final monthLabel = formatMonthYear(now);

    final labelColor = leafStyle ? Colors.white70 : Dk.of(context).muted;
    final valueColor = leafStyle ? Colors.white : Dk.of(context).ink;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).billMonthTillToday(monthLabel),
          style: TextStyle(
            color: labelColor,
            fontWeight: FontWeight.w700,
            fontSize: leafStyle ? 13 : 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context).payAnytimeCarryForward,
          style: TextStyle(color: labelColor, fontSize: 11),
        ),
        const SizedBox(height: 12),
        _AmountRow(
          label: l10n.milkTillToday,
          value: '${formatLitresString(litres)} · ${formatRupees(milkCharges)}',
          labelColor: labelColor,
          valueColor: valueColor,
          emphasize: true,
        ),
        if (previousDues > 0) ...[
          const SizedBox(height: 8),
          _AmountRow(
            label: l10n.previousDues,
            value: formatRupees(previousDues),
            labelColor: labelColor,
            valueColor: valueColor,
          ),
        ],
        const SizedBox(height: 10),
        _AmountRow(
          label: l10n.todaysAmount,
          value: formatRupees(todayAmount),
          labelColor: labelColor,
          valueColor: valueColor,
        ),
        const SizedBox(height: 10),
        _AmountRow(
          label: l10n.givenThisMonth,
          value: formatRupees(paid),
          labelColor: labelColor,
          valueColor: valueColor,
        ),
        const SizedBox(height: 10),
        _AmountRow(
          label: l10n.stillDue,
          value: formatRupees(remaining),
          labelColor: labelColor,
          valueColor: valueColor,
          emphasize: true,
        ),
        if (advance > 0) ...[
          const SizedBox(height: 10),
          _AmountRow(
            label: l10n.advance,
            value: formatRupees(advance),
            labelColor: labelColor,
            valueColor: valueColor,
            emphasize: true,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          l10n.extraMilkThisMonth(formatLitresString(extra)),
          style: TextStyle(color: labelColor, fontSize: 12),
        ),
        if (pendingCash > 0) ...[
          const SizedBox(height: 8),
          Text(
            l10n.cashAwaitingConfirm(formatRupees(pendingCash)),
            style: TextStyle(
              color: leafStyle ? Colors.white : AppColors.warning,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: leafStyle
              ? FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.leafDark,
                  ),
                  onPressed: () => showCustomerCashClaimDialog(context, ref),
                  child: Text(l10n.reportCashGiven),
                )
              : OutlinedButton.icon(
                  onPressed: () => showCustomerCashClaimDialog(context, ref),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: Text(l10n.reportCashGiven),
                ),
        ),
      ],
    );

    if (leafStyle) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.leaf,
          borderRadius: BorderRadius.circular(16),
        ),
        child: content,
      );
    }

    return Material(
      color: Dk.of(context).milkWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpenBilling,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.leaf.withValues(alpha: 0.08)),
          ),
          child: content,
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: emphasize ? 14 : 13,
              fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w800,
            fontSize: emphasize ? 20 : 16,
          ),
        ),
      ],
    );
  }
}

Future<void> showCustomerCashClaimDialog(
    BuildContext context, WidgetRef ref) async {
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  String? proofPath;
  var submitting = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      return StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> pick(ImageSource source) async {
            if (source == ImageSource.camera && !_supportsNativeCamera) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.desktopCameraHint)),
                );
              }
              source = ImageSource.gallery;
            }
            try {
              final file = await ImagePicker().pickImage(
                source: source,
                imageQuality: 85,
                maxWidth: 1600,
              );
              if (file == null) return;
              setState(() => proofPath = file.path);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).couldNotOpenPhotoPicker('$e'))),
                );
              }
            }
          }

          Future<void> submit() async {
            final amount = amountController.text.trim();
            if (double.tryParse(amount) == null || double.parse(amount) <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.enterValidAmount)),
              );
              return;
            }
            if (proofPath == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.addCashPhoto)),
              );
              return;
            }
            setState(() => submitting = true);
            try {
              await ref.read(customerDeliveriesApiProvider).claimCash(
                    amount: amount,
                    proofPath: proofPath!,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );
              final userId = ref.read(authControllerProvider).user?.id;
              ref.invalidate(customerBillTillTodayProvider);
              ref.invalidate(customerAwarePaymentsProvider(userId));
              try {
                await Future.wait([
                  ref.read(customerBillTillTodayProvider.future),
                  ref.read(customerAwarePaymentsProvider(userId).future),
                ]);
              } catch (_) {}
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.cashClaimSubmitted)),
                );
              }
            } catch (e) {
              setState(() => submitting = false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e')),
                );
              }
            }
          }

          return AlertDialog(
            title: Text(l10n.reportCashDialogTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.amountInr),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(labelText: l10n.notesOptional),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  if (proofPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(proofPath!),
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Text(
                      l10n.photoProofRequired,
                      style:
                          TextStyle(color: Dk.of(context).muted, fontSize: 12),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: submitting
                              ? null
                              : () => pick(ImageSource.camera),
                          icon:
                              const Icon(Icons.photo_camera_outlined, size: 18),
                          label: Text(l10n.camera),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: submitting
                              ? null
                              : () => pick(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined,
                              size: 18),
                          label: Text(l10n.gallery),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: submitting ? null : submit,
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.submit),
              ),
            ],
          );
        },
      );
    },
  );

  amountController.dispose();
  notesController.dispose();
}
