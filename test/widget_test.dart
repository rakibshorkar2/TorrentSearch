import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torrentflow/app.dart';

void main() {
  testWidgets('App renders with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TorrentFlowApp(),
      ),
    );
    expect(find.text('Search'), findsWidgets);
    expect(find.text('Downloads'), findsWidgets);
    expect(find.text('Seedr'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });
}
