import 'package:ecowaste_cotonou/data/models/collection_point.dart';
import 'package:ecowaste_cotonou/data/models/collection_schedule.dart';
import 'package:ecowaste_cotonou/data/models/waste_type.dart';
import 'package:ecowaste_cotonou/presentation/providers/guide_provider.dart';
import 'package:ecowaste_cotonou/presentation/providers/map_provider.dart';
import 'package:ecowaste_cotonou/presentation/providers/schedule_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  group('GuideProvider', () {
    late FakeGuideRepository repository;
    late GuideProvider provider;

    setUp(() async {
      repository = FakeGuideRepository();
      provider = GuideProvider(repository: repository);
      await provider.loadAllItems();
      await pumpEventQueue();
    });

    tearDown(() => provider.dispose());

    test('charge les items et arrête le chargement', () {
      expect(provider.isLoading, isFalse);
      expect(provider.filteredItemsCount, 3);
    });

    test('filtre par catégorie (bug : liste toujours vide)', () {
      provider.filterByCategory(RecyclingCategory.glass);
      expect(provider.filteredItems.map((i) => i.name), ['Bocal en verre']);

      provider.filterByCategory(null);
      expect(provider.filteredItemsCount, 3);
    });

    test('recherche sur les mots-clés, combinée au filtre', () {
      provider.search('pet');
      expect(provider.filteredItems.single.name, 'Bouteille en plastique');

      provider.filterByCategory(RecyclingCategory.glass);
      expect(provider.filteredItems, isEmpty);

      provider.resetFilters();
      expect(provider.filteredItemsCount, 3);
    });

    test('catégories disponibles (bug : TypeError sur un cast)', () {
      expect(provider.getAvailableCategories(), [
        RecyclingCategory.plastic,
        RecyclingCategory.glass,
        RecyclingCategory.dangerous,
      ]);
    });

    test('recharger ne cumule pas les abonnements au flux', () async {
      await provider.loadAllItems();
      await provider.loadAllItems();
      await pumpEventQueue();
      expect(repository.subscriptions, 3);
      expect(repository.controller.hasListener, isTrue);

      provider.dispose();
      expect(repository.controller.hasListener, isFalse);
      // Évite le double dispose du tearDown
      provider = GuideProvider(repository: repository);
    });

    test('suit les mises à jour temps réel', () async {
      repository.controller.add(demoGuideItems.take(1).toList());
      await pumpEventQueue();
      expect(provider.totalItemsCount, 1);
    });
  });

  group('ScheduleProvider', () {
    final today = DateTime.now();
    CollectionSchedule collecte(String district, DateTime date) =>
        CollectionSchedule(
          id: '$district-${date.day}',
          district: district,
          wasteType: WasteType.general,
          collectionDate: DateTime(date.year, date.month, date.day),
          collectionTime: '06:00 - 10:00',
          instructions: '',
        );

    test('suit le quartier du profil et recharge', () async {
      final repository = FakeScheduleRepository([
        collecte('Akpakpa', today),
        collecte('Zongo', today),
      ]);
      final provider = ScheduleProvider(repository: repository);
      await provider.ensureLoaded();
      expect(repository.requestedDistricts, ['Akpakpa']);

      provider.syncDistrict('Zongo');
      await pumpEventQueue();
      expect(provider.currentDistrict, 'Zongo');
      expect(repository.requestedDistricts.last, 'Zongo');
      expect(provider.nextSchedule?.district, 'Zongo');

      // Même quartier : pas de rechargement inutile
      provider.syncDistrict('Zongo');
      await pumpEventQueue();
      expect(repository.requestedDistricts.length, 2);
    });

    test('collectes d\'un jour donné', () async {
      final provider = ScheduleProvider(
        repository: FakeScheduleRepository([collecte('Akpakpa', today)]),
      );
      await provider.ensureLoaded();
      expect(provider.getSchedulesForDate(today), hasLength(1));
      expect(
        provider.getSchedulesForDate(today.add(const Duration(days: 40))),
        isEmpty,
      );
    });
  });

  group('MapProvider', () {
    CollectionPoint point(String name, List<WasteType> types) =>
        CollectionPoint(
          id: name,
          name: name,
          latitude: 6.36,
          longitude: 2.41,
          address: 'Cotonou',
          acceptedWasteTypes: types,
          openingHours: 'Lun-Sam',
        );

    test('filtre les points par type de déchet', () async {
      final provider = MapProvider(
        repository: FakePointsRepository([
          point('Déchetterie', WasteType.values),
          point('DEEE', [WasteType.electronic]),
        ]),
      );
      await provider.ensureLoaded();
      await pumpEventQueue();
      expect(provider.filteredPointsCount, 2);

      provider.filterByWasteType(WasteType.electronic);
      expect(provider.filteredPointsCount, 2);

      provider.filterByWasteType(WasteType.organic);
      expect(provider.filteredPoints.single.name, 'Déchetterie');

      provider.resetFilter();
      expect(provider.filterText, 'Tous');
      provider.dispose();
    });
  });
}
