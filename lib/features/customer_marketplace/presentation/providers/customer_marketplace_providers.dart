import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/models/marketplace_models.dart';
import '../../data/customer_marketplace_api.dart';
import '../../data/models/customer_marketplace_models.dart';

final customerMarketplaceApiProvider = Provider<CustomerMarketplaceApi>((ref) {
  return CustomerMarketplaceApi(ref.watch(apiClientProvider));
});

final customerAddressesProvider =
    FutureProvider.autoDispose<List<CustomerAddressModel>>((ref) {
  return ref.watch(customerMarketplaceApiProvider).listAddresses();
});

final customerServiceRequestsProvider =
    FutureProvider<List<ServiceRequestModel>>((ref) {
  return ref.watch(customerMarketplaceApiProvider).myServiceRequests();
});

final customerInvitationsProvider =
    FutureProvider<List<CustomerInvitationModel>>((ref) {
  return ref.watch(customerMarketplaceApiProvider).myInvitations();
});

class FarmSearchState {
  const FarmSearchState({
    this.result,
    this.isLoading = false,
    this.error,
    this.addressId,
    this.milkType,
    this.deliveryShift,
    this.hasSearched = false,
  });

  final FarmSearchResponse? result;
  final bool isLoading;
  final String? error;
  final String? addressId;
  final String? milkType;
  final String? deliveryShift;
  final bool hasSearched;

  FarmSearchState copyWith({
    FarmSearchResponse? result,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? addressId,
    String? milkType,
    bool clearMilkType = false,
    String? deliveryShift,
    bool clearDeliveryShift = false,
    bool? hasSearched,
  }) {
    return FarmSearchState(
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      addressId: addressId ?? this.addressId,
      milkType: clearMilkType ? null : (milkType ?? this.milkType),
      deliveryShift:
          clearDeliveryShift ? null : (deliveryShift ?? this.deliveryShift),
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }
}

class FarmSearchController extends StateNotifier<FarmSearchState> {
  FarmSearchController(this._api) : super(const FarmSearchState());

  final CustomerMarketplaceApi _api;

  Future<void> search({
    required String addressId,
    String? milkType,
    String? deliveryShift,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      addressId: addressId,
      milkType: milkType,
      clearMilkType: milkType == null,
      deliveryShift: deliveryShift,
      clearDeliveryShift: deliveryShift == null,
    );
    try {
      final result = await _api.searchFarms(
        addressId: addressId,
        milkType: milkType,
        deliveryShift: deliveryShift,
        includeDiagnostics: true,
      );
      state =
          state.copyWith(result: result, isLoading: false, hasSearched: true);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.toString(), hasSearched: true);
    }
  }
}

final farmSearchControllerProvider =
    StateNotifierProvider.autoDispose<FarmSearchController, FarmSearchState>(
        (ref) {
  return FarmSearchController(ref.watch(customerMarketplaceApiProvider));
});
