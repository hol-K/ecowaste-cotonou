import 'package:ecowaste_cotonou/data/models/waste_type.dart';
import 'package:ecowaste_cotonou/presentation/providers/guide_provider.dart';
import 'package:ecowaste_cotonou/presentation/providers/home_navigation_provider.dart';
import 'package:ecowaste_cotonou/presentation/providers/map_provider.dart';
import 'package:ecowaste_cotonou/presentation/screens/guide/guide_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeGuideRepository guideRepository;
  late MapProvider mapProvider;
  late HomeNavigationProvider navigation;

  // Thème Material par défaut : AppTheme charge Google Fonts via le réseau
  Widget app() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GuideProvider(repository: guideRepository),
        ),
        ChangeNotifierProvider.value(value: mapProvider),
        ChangeNotifierProvider.value(value: navigation),
      ],
      child: const MaterialApp(home: GuideScreen()),
    );
  }

  setUp(() {
    guideRepository = FakeGuideRepository();
    mapProvider = MapProvider(repository: FakePointsRepository(const []));
    navigation = HomeNavigationProvider();
  });

  testWidgets('affiche les items puis filtre par catégorie', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Bouteille en plastique'), findsOneWidget);
    expect(find.text('Bocal en verre'), findsOneWidget);
    expect(find.text('Pile usagée'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Verre'));
    await tester.pumpAndSettle();

    expect(find.text('Bocal en verre'), findsOneWidget);
    expect(find.text('Bouteille en plastique'), findsNothing);
    expect(find.text('Pile usagée'), findsNothing);
  });

  testWidgets('recherche et état vide', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'pile');
    await tester.pumpAndSettle();
    expect(find.text('Pile usagée'), findsOneWidget);
    expect(find.text('Bocal en verre'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Aucun résultat trouvé'), findsOneWidget);
  });

  testWidgets('la fiche affiche le contenu de la base et mène à la carte', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pile usagée'));
    await tester.pumpAndSettle();

    expect(guideRepository.viewed, ['Pile usagée']);
    expect(find.text('Impact de Pile usagée'), findsOneWidget);
    expect(find.text('Rincer'), findsOneWidget);

    final button = find.text('Trouver un point de collecte');
    // Le bouton est déjà construit en bas de la fiche : on le fait défiler à l'écran
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(navigation.current, HomeTab.map);
    expect(mapProvider.selectedFilter, WasteType.dangerous);
    expect(find.text('Guide de Tri'), findsOneWidget); // retour à la liste
  });
}
