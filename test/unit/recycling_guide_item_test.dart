import 'package:ecowaste_cotonou/data/models/recycling_guide_item.dart';
import 'package:ecowaste_cotonou/data/models/waste_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Ligne telle que renvoyée par Supabase (table recycling_guide_items)
  final row = <String, dynamic>{
    'id': '7f1c0e5a-0000-4000-8000-000000000001',
    'name': 'Pile usagée',
    'category': 'dangerous',
    'waste_type': 'dangerous',
    'image_url': '',
    'description': 'Piles alcalines',
    'instructions': ['Ne pas jeter'],
    'environmental_impact': 'Pollue les sols',
    'keywords': ['pile'],
    'alternatives': null,
    'view_count': 3,
  };

  test('fromMap lit les enums et les tableaux Postgres', () {
    final item = RecyclingGuideItem.fromMap(row);
    expect(item.id, row['id']);
    expect(item.category, RecyclingCategory.dangerous);
    expect(item.wasteType, WasteType.dangerous);
    expect(item.instructions, ['Ne pas jeter']);
    expect(item.hasAlternatives, isFalse);
  });

  test('toMap/fromMap conserve catégorie et type de déchet', () {
    final item = RecyclingGuideItem.fromMap(row);
    final map = item.toMap();
    expect(map['category'], 'dangerous');
    expect(map['waste_type'], 'dangerous');

    final back = RecyclingGuideItem.fromMap({...map, 'id': item.id});
    expect(back.category, RecyclingCategory.dangerous);
    expect(back.wasteType, WasteType.dangerous);
  });

  test('belongsToCategory compare bien des enums', () {
    final item = RecyclingGuideItem.fromMap(row);
    expect(item.belongsToCategory(RecyclingCategory.dangerous), isTrue);
    expect(item.belongsToCategory(RecyclingCategory.plastic), isFalse);
  });
}
