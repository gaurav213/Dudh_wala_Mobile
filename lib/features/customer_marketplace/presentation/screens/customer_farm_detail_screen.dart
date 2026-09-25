import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/delivery_shift_helpers.dart';
import '../../../../core/utils/delivery_schedule_helpers.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/models/marketplace_models.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/customer_marketplace_models.dart';
import '../providers/customer_marketplace_providers.dart';

class CustomerFarmDetailScreen extends ConsumerStatefulWidget {
  const CustomerFarmDetailScreen({super.key, required this.farmId, this.args});

  final String farmId;
  final CustomerFarmDetailArgs? args;

  @override
  ConsumerState<CustomerFarmDetailScreen> createState() =>
      _CustomerFarmDetailScreenState();
}

class _CustomerFarmDetailScreenState
    extends ConsumerState<CustomerFarmDetailScreen> {
  FarmPublicDetailModel? _publicDetail;
  bool _loadingPublic = false;
  String? _publicError;

  @override
  void initState() {
    super.initState();
    // Always load public detail so products stay available even without search extras.
    _loadPublicDetail();
  }

  Future<void> _loadPublicDetail() async {
    setState(() {
      _loadingPublic = true;
      _publicError = null;
    });
    try {
      final farm = await ref
          .read(customerMarketplaceApiProvider)
          .publicFarm(widget.farmId);
      if (mounted) setState(() => _publicDetail = farm);
    } catch (e) {
      if (mounted) setState(() => _publicError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingPublic = false);
    }
  }

  Future<void> _openWriteReview() async {
    var rating = 5;
    final comment = TextEditingController();
    String? commentText;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.of(context).rateThisFarm,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                          onPressed: () => setSheet(() => rating = i),
                          icon: Icon(
                            i <= rating ? Icons.star : Icons.star_border,
                            color: AppColors.leaf,
                          ),
                        ),
                    ],
                  ),
                  TextField(
                    controller: comment,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).commentOptional,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      commentText = comment.text;
                      Navigator.of(ctx).pop(true);
                    },
                    child: Text(AppLocalizations.of(context).submitReview),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) => comment.dispose());
    });
    if (ok != true || !mounted) return;
    try {
      await ref.read(customerMarketplaceApiProvider).submitFarmReview(
            farmId: widget.farmId,
            rating: rating,
            comment: commentText,
          );
      await _loadPublicDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).thanksForReview)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  ServiceRequestModel? _activeRequestFor(
    FarmProductModel product,
    List<ServiceRequestModel> requests,
  ) {
    final matches = requests
        .where(
          (r) =>
              r.farmId == widget.farmId &&
              r.productId == product.id &&
              (r.isPending || r.isAccepted),
        )
        .toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bAt.compareTo(aAt);
    });
    return matches.first;
  }

  Future<void> _confirmCancelRequest(ServiceRequestModel request) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).cancelRequestTitle),
        content: Text(AppLocalizations.of(context).cancelRequestBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).keep),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).cancelRequest),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref
          .read(customerMarketplaceApiProvider)
          .cancelServiceRequest(request.id);
      ref.invalidate(customerServiceRequestsProvider);
      try {
        await ref.read(customerServiceRequestsProvider.future);
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).requestCancelled)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _openPendingActions(
    FarmProductModel product,
    ServiceRequestModel request,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Dk.of(context).milkWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                product.name,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context).statusPending,
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(AppLocalizations.of(context).editRequest),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openRequestDialog(product, existing: request);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.cancel_outlined, color: AppColors.danger),
                title: Text(AppLocalizations.of(context).cancelRequest),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmCancelRequest(request);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openRequestDialog(
    FarmProductModel product, {
    ServiceRequestModel? existing,
  }) async {
    final args = widget.args;
    final addresses = await ref.read(customerAddressesProvider.future);
    if (!mounted) return;
    if (addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).addAddressBeforeRequest),
        ),
      );
      await context.push(AppRoutes.customerAddresses);
      return;
    }

    final formKey = GlobalKey<FormState>();
    var addressId = existing?.addressId ??
        args?.addressId ??
        addresses
            .firstWhere((a) => a.isDefault, orElse: () => addresses.first)
            .id;
    if (!addresses.any((a) => a.id == addressId)) {
      addressId = addresses
          .firstWhere((a) => a.isDefault, orElse: () => addresses.first)
          .id;
    }
    final quantity = TextEditingController(
      text: formatQuantityString(
        existing?.quantity ?? product.minimumQuantity,
      ),
    );
    final availableShifts = productDeliveryShifts(product.availableShifts);
    var shift = existing?.deliveryShift ?? availableShifts.first;
    if (!availableShifts.contains(shift)) shift = availableShifts.first;
    var scheduleType = existing?.scheduleType ?? 'EVERY_DAY';
    var startDate = DateTime.tryParse(existing?.preferredStartDate ?? '') ??
        DateTime.now().add(const Duration(days: 1));
    final instructions = TextEditingController(
      text: existing?.deliveryInstructions ?? '',
    );
    var saving = false;
    final editing = existing != null;

    String dateLabel(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Dk.of(context).milkWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (dialogContext) {
          final viewInsets = MediaQuery.viewInsetsOf(dialogContext);
          final sheetHeight = MediaQuery.sizeOf(dialogContext).height * 0.92;
          final shifts = productDeliveryShifts(product.availableShifts);
          if (!shifts.contains(shift)) {
            shift = shifts.first;
          }

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final selectedAddress = addresses.firstWhere(
                (e) => e.id == addressId,
                orElse: () => addresses.first,
              );

              Future<void> send() async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => saving = true);
                try {
                  final api = ref.read(customerMarketplaceApiProvider);
                  if (editing) {
                    await api.updateServiceRequest(
                      existing.id,
                      quantity: quantity.text.trim(),
                      deliveryShift: shift,
                      scheduleType: scheduleType,
                      preferredStartDate: dateLabel(startDate),
                      deliveryInstructions: instructions.text.trim(),
                      addressId: addressId,
                    );
                  } else {
                    await api.createServiceRequest(
                      farmId: widget.farmId,
                      addressId: addressId,
                      productId: product.id,
                      quantity: quantity.text.trim(),
                      deliveryShift: shift,
                      scheduleType: scheduleType,
                      preferredStartDate: dateLabel(startDate),
                      deliveryInstructions: instructions.text.trim(),
                    );
                  }
                  ref.invalidate(customerServiceRequestsProvider);
                  try {
                    await ref.read(customerServiceRequestsProvider.future);
                  } catch (_) {}
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          editing
                              ? AppLocalizations.of(context).requestUpdated
                              : AppLocalizations.of(context).requestSentToFarm,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  setDialogState(() => saving = false);
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              }

              return Padding(
                padding: EdgeInsets.only(bottom: viewInsets.bottom),
                child: SizedBox(
                  height: sheetHeight,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Dk.of(context).muted.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                editing
                                    ? AppLocalizations.of(context).editRequest
                                    : AppLocalizations.of(context).requestMilk,
                                style: Theme.of(dialogContext)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Dk.of(context).ink,
                                    ),
                              ),
                            ),
                            IconButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              icon: const Icon(Icons.close),
                              tooltip: AppLocalizations.of(context).close,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Form(
                          key: formKey,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Dk.of(context).foam,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        AppColors.leaf.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.water_drop,
                                        color: Theme.of(dialogContext)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: Dk.of(context).ink,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${localizedMilkType(AppLocalizations.of(context), product.milkType)} · ${AppLocalizations.of(context).rateMinQty('${product.currentRatePerLitre}', formatLitresString(product.minimumQuantity))}",
                                              style: TextStyle(
                                                fontSize: 13,
                                                height: 1.35,
                                                color: Dk.of(context).muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                AppLocalizations.of(context).deliveryDetails,
                                style: Theme.of(dialogContext)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Dk.of(context).ink,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: saving
                                    ? null
                                    : () async {
                                        final picked =
                                            await showModalBottomSheet<String>(
                                          context: dialogContext,
                                          backgroundColor:
                                              Dk.of(context).milkWhite,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                          ),
                                          builder: (ctx) {
                                            return SafeArea(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                  8,
                                                  12,
                                                  8,
                                                  16,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Center(
                                                      child: Container(
                                                        width: 40,
                                                        height: 4,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Dk.of(context)
                                                              .muted
                                                              .withValues(
                                                                  alpha: 0.35),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      999),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .fromLTRB(
                                                        12,
                                                        16,
                                                        12,
                                                        8,
                                                      ),
                                                      child: Text(
                                                        AppLocalizations.of(context).deliverTo,
                                                        style: Theme.of(ctx)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color:
                                                                  Dk.of(context)
                                                                      .ink,
                                                            ),
                                                      ),
                                                    ),
                                                    ConstrainedBox(
                                                      constraints:
                                                          BoxConstraints(
                                                        maxHeight:
                                                            MediaQuery.sizeOf(
                                                                        ctx)
                                                                    .height *
                                                                0.5,
                                                      ),
                                                      child: ListView.separated(
                                                        shrinkWrap: true,
                                                        itemCount:
                                                            addresses.length,
                                                        separatorBuilder:
                                                            (_, __) => Divider(
                                                          height: 1,
                                                          color: Dk.of(context)
                                                              .muted
                                                              .withValues(
                                                                  alpha: 0.2),
                                                        ),
                                                        itemBuilder: (_, i) {
                                                          final a =
                                                              addresses[i];
                                                          final selected =
                                                              a.id == addressId;
                                                          return ListTile(
                                                            selected: selected,
                                                            selectedTileColor:
                                                                AppColors.teal
                                                                    .withValues(
                                                              alpha: 0.12,
                                                            ),
                                                            leading: Icon(
                                                              selected
                                                                  ? Icons
                                                                      .check_circle
                                                                  : Icons
                                                                      .location_on_outlined,
                                                              color: selected
                                                                  ? AppColors
                                                                      .teal
                                                                  : Dk.of(context)
                                                                      .muted,
                                                            ),
                                                            title: Text(
                                                              a.label,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Dk.of(
                                                                        context)
                                                                    .ink,
                                                              ),
                                                            ),
                                                            subtitle: Text(
                                                              a.shortLine,
                                                              style: TextStyle(
                                                                color: Dk.of(
                                                                        context)
                                                                    .muted,
                                                              ),
                                                            ),
                                                            trailing:
                                                                a.isDefault
                                                                    ? Chip(
                                                                        label:
                                                                            Text(AppLocalizations.of(context).defaultLabel,
                                                                        ),
                                                                        visualDensity:
                                                                            VisualDensity.compact,
                                                                        materialTapTargetSize:
                                                                            MaterialTapTargetSize.shrinkWrap,
                                                                        padding:
                                                                            EdgeInsets.zero,
                                                                        labelStyle:
                                                                            const TextStyle(
                                                                          fontSize:
                                                                              11,
                                                                        ),
                                                                        side: BorderSide
                                                                            .none,
                                                                        backgroundColor: AppColors
                                                                            .teal
                                                                            .withValues(
                                                                          alpha:
                                                                              0.12,
                                                                        ),
                                                                      )
                                                                    : null,
                                                            onTap: () =>
                                                                Navigator.of(
                                                                        ctx)
                                                                    .pop(a.id),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                        if (picked != null) {
                                          setDialogState(
                                              () => addressId = picked);
                                        }
                                      },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context).deliverTo,
                                    isDense: true,
                                    suffixIcon: Icon(Icons.keyboard_arrow_down),
                                  ),
                                  child: Text(
                                    "${selectedAddress.label} — ${selectedAddress.shortLine}",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.3,
                                      color: Dk.of(context).ink,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: quantity,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context).quantity,
                                  suffixText:
                                      AppLocalizations.of(context).litres,
                                  isDense: true,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (v) =>
                                    (double.tryParse(v ?? '') == null)
                                        ? AppLocalizations.of(context)
                                            .enterLitres
                                        : null,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                AppLocalizations.of(context).shift,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Dk.of(context).muted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (shifts.length == 1)
                                InputDecorator(
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    prefixIcon: Icon(Icons.schedule_outlined),
                                  ),
                                  child: Text(
                                    deliveryShiftLabel(
                                      shifts.first,
                                      AppLocalizations.of(context),
                                    ),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Dk.of(context).ink,
                                    ),
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: shifts.map((s) {
                                    final selected = shift == s;
                                    return ChoiceChip(
                                      label: Text(deliveryShiftLabel(
                                        s,
                                        AppLocalizations.of(context),
                                      )),
                                      avatar: Icon(
                                        deliveryShiftIcon(s),
                                        size: 18,
                                        color: selected
                                            ? Theme.of(dialogContext)
                                                .colorScheme
                                                .primary
                                            : Dk.of(context).muted,
                                      ),
                                      selected: selected,
                                      onSelected: saving
                                          ? null
                                          : (_) =>
                                              setDialogState(() => shift = s),
                                      selectedColor: AppColors.teal
                                          .withValues(alpha: 0.22),
                                      labelStyle: TextStyle(
                                        color: selected
                                            ? Theme.of(dialogContext)
                                                .colorScheme
                                                .primary
                                            : Dk.of(context).ink,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                      side: BorderSide(
                                        color: selected
                                            ? AppColors.teal
                                            : Dk.of(context)
                                                .muted
                                                .withValues(alpha: 0.3),
                                      ),
                                      backgroundColor: Dk.of(context).cream,
                                      showCheckmark: false,
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 14),
                              Text(
                                AppLocalizations.of(context).howOften,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Dk.of(context).muted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: customerScheduleOptions().map((s) {
                                  final selected = scheduleType == s;
                                  return ChoiceChip(
                                    label: Text(deliveryScheduleLabel(
                                        s, AppLocalizations.of(context))),
                                    selected: selected,
                                    onSelected: saving
                                        ? null
                                        : (_) => setDialogState(
                                              () => scheduleType = s,
                                            ),
                                    selectedColor:
                                        AppColors.teal.withValues(alpha: 0.22),
                                    labelStyle: TextStyle(
                                      color: selected
                                          ? Theme.of(dialogContext)
                                              .colorScheme
                                              .primary
                                          : Dk.of(context).ink,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                    side: BorderSide(
                                      color: selected
                                          ? AppColors.teal
                                          : Dk.of(context)
                                              .muted
                                              .withValues(alpha: 0.3),
                                    ),
                                    backgroundColor: Dk.of(context).cream,
                                    showCheckmark: false,
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                              if (scheduleType == 'WEEKLY') ...[
                                const SizedBox(height: 6),
                                Text(
                                  AppLocalizations.of(context).weeklyUsesStartWeekday,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Dk.of(context).muted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: saving
                                    ? null
                                    : () async {
                                        final picked = await showDatePicker(
                                          context: dialogContext,
                                          initialDate: startDate,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(
                                            const Duration(days: 365),
                                          ),
                                        );
                                        if (picked != null) {
                                          setDialogState(
                                              () => startDate = picked);
                                        }
                                      },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context).preferredStartDate,
                                    isDense: true,
                                    suffixIcon:
                                        Icon(Icons.calendar_today_outlined),
                                  ),
                                  child: Text(
                                    dateLabel(startDate),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Dk.of(context).ink,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: instructions,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context).deliveryNotes,
                                  hintText: AppLocalizations.of(context).deliveryNotesHint,
                                  isDense: true,
                                  alignLabelWithHint: true,
                                ),
                                maxLines: 3,
                                minLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: saving
                                      ? null
                                      : () => Navigator.of(dialogContext).pop(),
                                  child: Text(AppLocalizations.of(context).cancel),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  onPressed: saving ? null : send,
                                  child: Text(
                                    saving
                                        ? (editing
                                            ? AppLocalizations.of(context)
                                                .saving
                                            : AppLocalizations.of(context)
                                                .sending)
                                        : (editing
                                            ? AppLocalizations.of(context)
                                                .saveChanges
                                            : AppLocalizations.of(context)
                                                .sendRequest),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      // Sheet fields still detach during the pop frame — dispose next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        quantity.dispose();
        instructions.dispose();
      });
    }
  }

  List<FarmProductModel> get _products {
    final fromArgs = widget.args?.farm.products ?? const <FarmProductModel>[];
    if (fromArgs.isNotEmpty) return fromArgs;
    return _publicDetail?.products ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title =
        widget.args?.farm.name ?? _publicDetail?.name ?? l10n.farmProfile;
    final area = widget.args?.farm.area ?? _publicDetail?.area;
    final city = widget.args?.farm.city ?? _publicDetail?.city;
    final description =
        widget.args?.farm.description ?? _publicDetail?.description;
    final requestsAsync = ref.watch(customerServiceRequestsProvider);
    final requests =
        requestsAsync.asData?.value ?? const <ServiceRequestModel>[];
    final farmRequests =
        requests.where((r) => r.farmId == widget.farmId).toList();

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(title)),
      body: _loadingPublic && _publicDetail == null && widget.args == null
          ? const Center(child: CircularProgressIndicator())
          : _publicError != null && widget.args == null
              ? DkEmpty(
                  message: '${AppLocalizations.of(context).couldNotLoad}.\n$_publicError',
                  actionLabel: l10n.retry,
                  onAction: _loadPublicDetail,
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Dk.of(context).ink,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        area,
                        city,
                        _publicDetail?.state,
                        _publicDetail?.postalCode
                      ]
                          .whereType<String>()
                          .where((s) => s.isNotEmpty)
                          .join(', '),
                      style: TextStyle(color: Dk.of(context).muted),
                    ),
                    if ((description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(description!,
                          style: TextStyle(color: Dk.of(context).ink)),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      (_publicDetail?.reviewCount ?? 0) > 0
                          ? '${_publicDetail!.averageRating?.toStringAsFixed(1) ?? '—'} ★ · ${AppLocalizations.of(context).reviewsCount('${_publicDetail!.reviewCount}')}'
                          : AppLocalizations.of(context).noReviewsYet,
                      style: TextStyle(
                        color: Dk.of(context).muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((_publicDetail?.images ?? const []).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _publicDetail!.images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final img = _publicDetail!.images[i];
                            final url = mediaUrl(img.url) ?? img.url;
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                url,
                                width: 240,
                                height: 160,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 240,
                                  height: 160,
                                  color: Dk.of(context).foam,
                                  child:
                                      const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      l10n.products,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Dk.of(context).ink,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (_products.isEmpty)
                      DkEmpty(
                        message:
                            AppLocalizations.of(context).noMilkProductsAvailable,
                        actionLabel: AppLocalizations.of(context).backToSearch,
                        onAction: () => context.go(AppRoutes.customerFindFarms),
                      )
                    else
                      ..._products.map((p) {
                        final match = _activeRequestFor(p, requests);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            tileColor: Dk.of(context).milkWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: const Icon(
                              Icons.water_drop,
                              color: AppColors.teal,
                            ),
                            title: Text(
                              "${p.name} · ${localizedMilkType(AppLocalizations.of(context), p.milkType)}",
                              style: TextStyle(color: Dk.of(context).ink),
                            ),
                            subtitle: Text(
                              "${AppLocalizations.of(context).rateMinQty('${p.currentRatePerLitre}', formatLitresString(p.minimumQuantity))}${p.maximumQuantity != null ? ' · ${AppLocalizations.of(context).maxQtyShort(formatLitresString(p.maximumQuantity))}' : ''} · ${productDeliveryShifts(p.availableShifts).map((s) => deliveryShiftLabel(s, AppLocalizations.of(context))).join(', ')}",
                              style: TextStyle(color: Dk.of(context).muted),
                            ),
                            trailing: match == null
                                ? Icon(
                                    Icons.chevron_right,
                                    color: Dk.of(context).muted,
                                  )
                                : Chip(
                                    label: Text(
                                      match.isPending
                                          ? AppLocalizations.of(context).requestPending
                                          : l10n.connected,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: match.isPending
                                            ? AppColors.warning
                                            : AppColors.success,
                                      ),
                                    ),
                                    backgroundColor: (match.isPending
                                            ? AppColors.warning
                                            : AppColors.success)
                                        .withValues(alpha: 0.12),
                                    visualDensity: VisualDensity.compact,
                                    side: BorderSide.none,
                                  ),
                            onTap: () {
                              if (match == null) {
                                _openRequestDialog(p);
                              } else if (match.isPending) {
                                _openPendingActions(p, match);
                              } else {
                                context.push(
                                  '${AppRoutes.customerRequests}?focus=${match.id}',
                                );
                              }
                            },
                          ),
                        );
                      }),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (farmRequests.length == 1) {
                          context.push(
                            '${AppRoutes.customerRequests}?focus=${farmRequests.first.id}',
                          );
                        } else {
                          context.push(AppRoutes.customerRequests);
                        }
                      },
                      icon: const Icon(Icons.inbox_outlined),
                      label: Text(l10n.requests),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.reviews,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Dk.of(context).ink,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if ((_publicDetail?.reviews ?? const []).isEmpty)
                      Text(
                        AppLocalizations.of(context).noCustomerReviewsYet,
                        style: TextStyle(color: Dk.of(context).muted),
                      )
                    else
                      ..._publicDetail!.reviews.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            tileColor: Dk.of(context).milkWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(
                              "${'★' * r.rating}${'☆' * (5 - r.rating)}",
                              style: const TextStyle(letterSpacing: 1),
                            ),
                            subtitle: (r.comment ?? '').isEmpty
                                ? null
                                : Text(r.comment!),
                          ),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: _openWriteReview,
                      icon: const Icon(Icons.rate_review_outlined),
                      label: Text(AppLocalizations.of(context).writeAReview),
                    ),
                  ],
                ),
    );
  }
}
