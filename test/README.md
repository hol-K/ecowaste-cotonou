# Tests - EcoWaste Cotonou

Ce répertoire contient les tests unitaires, de widget et d'intégration pour l'application EcoWaste Cotonou.

## Structure des tests

```
test/
├── helpers/
│   └── fakes.dart                        # Repositories en mémoire (sans Supabase)
├── unit/
│   ├── recycling_guide_item_test.dart    # Conversion du guide (enums Postgres)
│   ├── supabase_models_test.dart         # Conversion plannings / points / profils
│   ├── notification_reminders_test.dart  # Calcul des rappels de collecte
│   └── providers_test.dart               # Guide, calendrier, carte
└── widget/
    └── guide_screen_test.dart            # Écran du guide : filtres, recherche, fiche
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

### Test spécifique
```bash
flutter test test/unit/providers_test.dart
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
4. **Mocking** : Mock les services externes (Supabase, API)
5. **Couverture** : Viser 80%+ de couverture de code

## Tester sans Supabase

Les modèles se testent directement avec des lignes au format renvoyé par
Supabase (voir `unit/supabase_models_test.dart`).

Les repositories acceptent un `SupabaseClient` dans leur constructeur, et
`AuthProvider` accepte un `UserRepository` : dans un test, passez un client
pointé vers un faux serveur HTTP, ou une sous-classe de repository qui
renvoie des données en mémoire.

```dart
class FakeGuideRepository extends GuideRepository {
  FakeGuideRepository() : super(client: SupabaseClient('http://localhost', 'test'));

  @override
  Stream<List<RecyclingGuideItem>> getAllItems() => Stream.value([/* ... */]);
}
```

## Ressources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Unit Testing](https://flutter.dev/docs/cookbook/testing/unit)
- [Widget Testing](https://flutter.dev/docs/cookbook/testing/widget)
- [Integration Testing](https://flutter.dev/docs/docs/testing/integration-tests)
