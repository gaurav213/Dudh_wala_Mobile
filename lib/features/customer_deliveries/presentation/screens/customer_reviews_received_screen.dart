import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/customer_review_model.dart';
import '../providers/customer_deliveries_providers.dart';

class CustomerReviewsReceivedScreen extends ConsumerWidget {
  const CustomerReviewsReceivedScreen({super.key});

  Widget _stars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star : Icons.star_border,
            size: 16,
            color: AppColors.warning,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reviewsAsync = ref.watch(customerMyReviewsProvider);

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(l10n.reviews)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(customerMyReviewsProvider),
        child: reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  DkEmpty(message: AppLocalizations.of(context).noReviewsFromDairyYet),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (context, i) =>
                  _ReviewCard(review: reviews[i], stars: _stars),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              DkEmpty(
                message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(customerMyReviewsProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.stars});

  final CustomerReviewModel review;
  final Widget Function(int) stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Dk.of(context).milkWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              stars(review.rating),
              const Spacer(),
              Text(
                formatDate(review.createdAt),
                style: TextStyle(color: Dk.of(context).muted, fontSize: 12),
              ),
            ],
          ),
          if ((review.comment ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: TextStyle(color: Dk.of(context).ink)),
          ],
          if (review.communicationRating != null ||
              review.addressAccuracyRating != null ||
              review.paymentReliabilityRating != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (review.communicationRating != null)
                  _MiniStat('Communication', review.communicationRating!),
                if (review.addressAccuracyRating != null)
                  _MiniStat('Address accuracy', review.addressAccuracyRating!),
                if (review.paymentReliabilityRating != null)
                  _MiniStat('Payments', review.paymentReliabilityRating!),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Text(
      "$label: $value/5",
      style: TextStyle(color: Dk.of(context).muted, fontSize: 12),
    );
  }
}
