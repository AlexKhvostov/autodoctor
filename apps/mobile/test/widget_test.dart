import 'package:autodoctor/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the AutoDoctor bootstrap screen', (tester) async {
    await tester.pumpWidget(const AutoDoctorApp());

    expect(find.text('AutoDoctor'), findsOneWidget);
    expect(
      find.text('Основа приложения готова к разработке'),
      findsOneWidget,
    );
  });
}
