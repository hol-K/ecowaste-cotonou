import 'package:ecowaste_cotonou/data/models/recycling_guide_item.dart';
import 'package:ecowaste_cotonou/data/models/waste_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final item = RecyclingGuideItem(
    id: 'abc',
    name: 'Pile usagée',
    category: RecyclingCategory.dangerous,
    wasteType: WasteType.dangerous,
    imageUrl: '',
    description: 'Piles alcalines',
    instructions: ['Ne pas jeter'],
    environmentalImpact: 'Pollue les sols',
    keywords: ['pile'],
  );

  test('toMap/fromMap conserve catégorie et type de déchet', () {
    final map = item.toMap();
    expect(map['category'], 'dangerous');
    expect(map['wasteType'], 'dangerous');

    final back = RecyclingGuideItem.fromMap(map, 'abc');
    expect(back.category, RecyclingCategory.dangerous);
    expect(back.wasteType, WasteType.dangerous);
  });

  test('fromMap relit les anciens documents stockés avec le libellé', () {
    final legacy = item.toMap()
      ..['category'] = 'Papier & Carton'
      ..['wasteType'] = 'Recyclables';

    final back = RecyclingGuideItem.fromMap(legacy, 'abc');
    expect(back.category, RecyclingCategory.paper);
    expect(back.wasteType, WasteType.recyclable);
  });

  test('belongsToCategory compare bien des enums', () {
    expect(item.belongsToCategory(RecyclingCategory.dangerous), isTrue);
    expect(item.belongsToCategory(RecyclingCategory.plastic), isFalse);
  });
}
