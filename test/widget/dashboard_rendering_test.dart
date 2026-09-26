import 'dart:async';

import 'package:doodh_khata_mobile/app/theme/app_theme.dart';
import 'package:doodh_khata_mobile/core/database/app_database.dart';
import 'package:doodh_khata_mobile/core/database/database_provider.dart';
import 'package:doodh_khata_mobile/core/sync/sync_service.dart';
import 'package:doodh_khata_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:doodh_khata_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:doodh_khata_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:doodh_khata_mobile/features/dashboard/presentation/screens/supplier_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('supplier dashboard renders brand and stats', (tester) async {
    final db = await AppDatabase.memory();
    addTearDown(db.close);

    await db.insertCustomer(
      supplierId: 's1',
      name: 'Asha',
      phone: '9999999999',
      defaultRatePerLitre: 60,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authControllerProvider.overrideWith(
            (ref) => _FakeAuth(
              const UserEntity(
                id: 's1',
                name: 'Gaurav Dairy',
                phone: '9000000000',
                role: UserRole.farmOwner,
              ),
            ),
          ),
          syncStateProvider.overrideWith(
            (ref) => Stream.value(const SyncState()),
          ),
          syncServiceProvider.overrideWithValue(_FakeSyncService()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SupplierDashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Doodh Wala'), findsOneWidget);
    expect(find.text('Customers'), findsWidgets);
    expect(find.text('Today litres'), findsOneWidget);
  });
}

class _FakeAuth extends AuthController {
  _FakeAuth(UserEntity user) : super(_NoopRepo()) {
    state = AuthState(user: user, initialized: true);
  }
}

class _NoopRepo implements AuthRepository {
  @override
  Future<void> logout() async {}

  @override
  Future<void> clearLocalSession() async {}

  @override
  Future<UserEntity> login({required String phone, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> refreshSession() async => false;

  @override
  Future<UserEntity> registerFarmOwner({
    required String name,
    required String phone,
    required String password,
    required String farmName,
    required String addressLine1,
    required String area,
    required String city,
    required String state,
    required String postalCode,
    String? businessName,
    String? email,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> registerCustomer({
    required String name,
    required String phone,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity?> restoreSession() async => null;

  @override
  Future<UserEntity?> restoreCachedUser() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSyncService implements SyncService {
  @override
  Future<void> syncNow() async {}

  @override
  void startConnectivityListener() {}

  @override
  SyncState get state => const SyncState();

  @override
  Stream<SyncState> get stream => Stream.value(const SyncState());

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
