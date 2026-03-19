# Tests - EcoWaste Cotonou

Ce répertoire contient les tests unitaires, de widget et d'intégration pour l'application EcoWaste Cotonou.

## Structure des tests

```
test/
├── widget_test.dart          # Tests de base Material App
├── unit/
│   └── example_test.dart     # Tests unitaires (logique métier)
├── widget/
│   └── material_widgets_test.dart  # Tests des widgets Flutter
└── integration/
    └── user_flow_test.dart   # Tests d'intégration (flux utilisateur)
```

## Exécution des tests

### Tous les tests
```bash
flutter test
```

### Tests unitaires uniquement
```bash
flutter test test/unit
```

### Tests de widget uniquement
```bash
flutter test test/widget
```

### Tests d'intégration uniquement
```bash
flutter test test/integration
```

### Test spécifique
```bash
flutter test test/unit/example_test.dart
```

### Avec couverture de code
```bash
flutter test --coverage
```

## Écriture de tests

### Test unitaire (logic)
```dart
test('Description du test', () {
  // Arrange
  final input = 5;
  
  // Act
  final result = divide(input, 2);
  
  // Assert
  expect(result, equals(2.5));
});
```

### Test de widget
```dart
testWidgets('Description du test', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MyWidget(),
    ),
  );
  
  expect(find.byType(MyWidget), findsOneWidget);
  expect(find.text('Expected Text'), findsOneWidget);
});
```

### Test d'intégration
```dart
testWidgets('Full app flow', (WidgetTester tester) async {
  // Lancer l'app
  await tester.pumpWidget(const MyApp());
  
  // Interagir avec l'app
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  
  // Vérifier les résultats
  expect(find.text('Result'), findsOneWidget);
});
```

## Bonnes pratiques

1. **Nommage** : Utilisez des noms descriptifs pour les tests
2. **AAA Pattern** : Arrange, Act, Assert
3. **Isolation** : Chaque test doit être indépendant
4. **Mocking** : Mock les services externes (Firebase, API)
5. **Couverture** : Viser 80%+ de couverture de code

## Mocking Firebase (pour les tests)

Pour les tests avec Firebase, utilisez `mockito` ou `fake_cloud_firestore`:

```dart
import 'package:mockito/mockito.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

setUp(() {
  final mockAuth = MockFirebaseAuth();
  // Configurer les mocks...
});
```

## Ressources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Unit Testing](https://flutter.dev/docs/cookbook/testing/unit)
- [Widget Testing](https://flutter.dev/docs/cookbook/testing/widget)
- [Integration Testing](https://flutter.dev/docs/docs/testing/integration-tests)
