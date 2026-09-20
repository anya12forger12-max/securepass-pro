import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/features/workspace/presentation/screens/workspace_screen.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/main.dart';
import 'package:securepass_pro/navigation/app_router.dart';
import 'package:securepass_pro/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({AppConstants.onboardingCompleteKey: true});
    await PreferencesStorage.instance.init();
  });

  testWidgets('workspace can add, favorite, and delete a credential',
      (tester) async {
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProviderScope(child: SecurePassApp()),
      ),
    );
    await tester.pumpAndSettle();

    container.read(goRouterProvider).go('/workspace');
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceScreen), findsOneWidget);

    expect(find.text('Your Workspace is empty'), findsOneWidget);

    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'GitHub');
    await tester.enterText(find.byType(TextFormField).at(1), 'hunter2');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('GitHub'), findsOneWidget);
    expect(find.textContaining('Please fill out this field'), findsNothing);
    expect(
      VaultService().getEntries().any((e) => e.title == 'GitHub'),
      isTrue,
    );

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pumpAndSettle();
    expect(
      VaultService().getEntries().firstWhere((e) => e.title == 'GitHub').isFavorite,
      isTrue,
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('GitHub'), findsNothing);
    expect(VaultService().getEntries(), isEmpty);
    container.dispose();
  });
}