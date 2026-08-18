import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:client/main.dart';
import 'package:client/providers/app_state.dart';

void main() {
  testWidgets('Alternea app loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const AlterneaApp(),
      ),
    );

    expect(find.text('Alternea'), findsWidgets);
  });
}
