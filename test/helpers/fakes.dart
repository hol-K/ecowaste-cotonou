// Repositories en mémoire pour tester providers et écrans sans Supabase.
// Ils implémentent (et n'héritent pas) des vrais repositories : aucun
// client Supabase n'est créé pendant les tests.

import 'dart:async';

import 'package:ecowaste_cotonou/data/models/collection_point.dart';
import 'package:ecowaste_cotonou/data/models/collection_schedule.dart';
import 'package:ecowaste_cotonou/data/models/recycling_guide_item.dart';
import 'package:ecowaste_cotonou/data/models/waste_type.dart';
import 'package:ecowaste_cotonou/data/repositories/guide_repository.dart';
import 'package:ecowaste_cotonou/data/repositories/points_repository.dart';
import 'package:ecowaste_cotonou/data/repositories/schedule_repository.dart';

RecyclingGuideItem guideItem(
  String name,
  RecyclingCategory category,
  WasteType wasteType, {
  List<String> keywords = const [],
}) {
  return RecyclingGuideItem(
    id: name,
    name: name,
    category: category,
    wasteType: wasteType,
    imageUrl: '',
    description: 'Description de $name',
    instructions: const ['Vider', 'Rincer'],
    environmentalImpact: 'Impact de $name',
    keywords: keywords,
  );
}

final demoGuideItems = [
  guideItem(
    'Bouteille en plastique',
    RecyclingCategory.plastic,
    WasteType.recyclable,
    keywords: ['pet', 'eau'],
  ),
  guideItem('Bocal en verre', RecyclingCategory.glass, WasteType.glass),
  guideItem('Pile usagée', RecyclingCategory.dangerous, WasteType.dangerous),
];

class FakeGuideRepository implements GuideRepository {
  FakeGuideRepository([List<RecyclingGuideItem>? items])
    : items = items ?? demoGuideItems;

  final List<RecyclingGuideItem> items;
  final List<String> viewed = [];
  final controller = StreamController<List<RecyclingGuideItem>>.broadcast();
  int subscriptions = 0;

  @override
  Stream<List<RecyclingGuideItem>> getAllItems() {
    subscriptions++;
    // Émet la liste initiale puis les mises à jour poussées par le test
    return Stream.multi((sink) {
      sink.add(items);
      final sub = controller.stream.listen(sink.add);
      sink.onCancel = sub.cancel;
    });
  }

  @override
  Future<RecyclingGuideItem?> getItemById(String id) async =>
      items.where((item) => item.id == id).firstOrNull;

  @override
  Future<void> incrementViewCount(String id) async => viewed.add(id);

  @override
  Future<Map<RecyclingCategory, int>> getItemsCountByCategory() async => {
    for (final category in RecyclingCategory.values)
      category: items.where((item) => item.category == category).length,
  };
}

class FakeScheduleRepository implements ScheduleRepository {
  FakeScheduleRepository(this.schedules);

  final List<CollectionSchedule> schedules;
  final List<String> requestedDistricts = [];

  @override
  Future<List<CollectionSchedule>> getSchedulesByDistrict({
    required String district,
    required DateTime month,
  }) async {
    requestedDistricts.add(district);
    return schedules
        .where(
          (s) =>
              s.district == district &&
              s.collectionDate.year == month.year &&
              s.collectionDate.month == month.month,
        )
        .toList();
  }

  @override
  Future<List<CollectionSchedule>> getUpcomingSchedules({
    required String district,
    int limit = 5,
  }) async => schedules
      .where((s) => s.district == district && !s.isPast())
      .take(limit)
      .toList();

  @override
  Future<CollectionSchedule?> getNextSchedule({required String district}) async {
    final upcoming = await getUpcomingSchedules(district: district, limit: 1);
    return upcoming.firstOrNull;
  }
}

class FakePointsRepository implements PointsRepository {
  FakePointsRepository(this.points);

  final List<CollectionPoint> points;

  @override
  Stream<List<CollectionPoint>> getAllPoints() => Stream.value(points);

  @override
  Future<CollectionPoint?> getPointById(String id) async =>
      points.where((p) => p.id == id).firstOrNull;
}
