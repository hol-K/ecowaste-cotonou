import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/collection_point.dart';
import '../../../data/models/waste_type.dart';
import '../../providers/map_provider.dart';
import '../../widgets/waste_visuals.dart';

/// Écran de la carte des points de collecte (OpenStreetMap + Firestore)
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  static const LatLng _cotonouCenter = LatLng(6.3654, 2.4183);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().ensureLoaded();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Centre la carte sur la position de l'utilisateur (la demande si besoin)
  Future<void> _centerOnUserLocation() async {
    final provider = context.read<MapProvider>();
    if (!provider.hasUserLocation) {
      await provider.getUserLocation();
      if (!mounted) return;
    }

    if (provider.userLocation != null) {
      _mapController.move(provider.userLocation!, 15.0);
    } else if (provider.errorMessage != null) {
      _showSnackBar(provider.errorMessage!);
    }
  }

  /// Affiche un message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// Ouvre une URL externe (itinéraire, appel)
  Future<void> _launch(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) _showSnackBar('Impossible d\'ouvrir $url');
  }

  /// Couleur d'un point : celle de son type si spécialisé, sinon l'accent
  Color _pointColor(CollectionPoint point) {
    if (point.acceptedWasteTypes.isEmpty ||
        point.acceptedWasteTypes.length > 3 ||
        point.acceptsWasteType(WasteType.general)) {
      return const Color(0xFF4A9B7F);
    }
    return point.acceptedWasteTypes.first.uiColor;
  }

  LatLng _latLng(CollectionPoint point) => LatLng(point.latitude, point.longitude);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapProvider>();
    final points = provider.getPointsSortedByDistance();

    return Scaffold(
      backgroundColor: const Color(0xFF1A3329),
      appBar: AppBar(
        title: const Text('Points de Collecte'),
        backgroundColor: const Color(0xFF2D5F4F),
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _cotonouCenter,
              initialZoom: 12.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ecowaste_cotonou',
                tileBuilder: _darkModeTileBuilder,
              ),

              // Marqueurs des points de collecte
              MarkerLayer(
                markers: points.map((point) {
                  final color = _pointColor(point);
                  return Marker(
                    point: _latLng(point),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showPointDetails(point),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Position de l'utilisateur
              if (provider.userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: provider.userLocation!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A9B7F).withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A9B7F),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Filtres en haut
          Positioned(top: 0, left: 0, right: 0, child: _buildFilters(provider)),

          // Compteur de points
          Positioned(
            top: 70,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3329).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4A9B7F), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.isLoadingPoints)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF4A9B7F),
                      size: 18,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    '${points.length} points',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'my_location',
            onPressed: _centerOnUserLocation,
            backgroundColor: const Color(0xFF4A9B7F),
            child: provider.isLoadingLocation
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'list',
            onPressed: _showPointsList,
            backgroundColor: const Color(0xFF2D5F4F),
            child: const Icon(Icons.list),
          ),
        ],
      ),
    );
  }

  /// Style sombre pour les tuiles
  Widget _darkModeTileBuilder(
    BuildContext context,
    Widget tileWidget,
    TileImage tile,
  ) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }

  /// Filtres par type de déchet
  Widget _buildFilters(MapProvider provider) {
    final filters = <WasteType?>[null, ...WasteType.values];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF2D5F4F).withValues(alpha: 0.95),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == provider.selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter?.displayName ?? 'Tous'),
              selected: isSelected,
              onSelected: (_) => provider.filterByWasteType(filter),
              backgroundColor: const Color(0xFF234037),
              selectedColor: const Color(0xFF4A9B7F),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFFB8C5C0),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              checkmarkColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  /// Affiche la liste des points (triés par distance si position connue)
  void _showPointsList() {
    final provider = context.read<MapProvider>();
    final points = provider.getPointsSortedByDistance();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A3329),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFB8C5C0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Points de collecte (${points.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: points.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun point pour ce filtre',
                        style: TextStyle(color: Color(0xFFB8C5C0)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: points.length,
                      itemBuilder: (context, index) =>
                          _buildPointListItem(sheetContext, points[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Item de la liste
  Widget _buildPointListItem(BuildContext sheetContext, CollectionPoint point) {
    final provider = context.read<MapProvider>();
    final color = _pointColor(point);
    final distance = provider.userLocation != null
        ? provider.calculateDistance(provider.userLocation!, _latLng(point))
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.pop(sheetContext);
        _mapController.move(_latLng(point), 16.0);
        _showPointDetails(point);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_on, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    distance != null
                        ? provider.formatDistance(distance)
                        : point.address,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB8C5C0),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFB8C5C0)),
          ],
        ),
      ),
    );
  }

  /// Affiche les détails d'un point
  void _showPointDetails(CollectionPoint point) {
    final provider = context.read<MapProvider>();
    final color = _pointColor(point);
    final distance = provider.userLocation != null
        ? provider.calculateDistance(provider.userLocation!, _latLng(point))
        : null;
    final phoneUrl = point.getPhoneUrl();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF234037),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8C5C0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                point.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              if (point.description != null && point.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  point.description!,
                  style: const TextStyle(color: Color(0xFFB8C5C0)),
                ),
              ],

              const SizedBox(height: 16),

              if (distance != null) ...[
                _buildDetailRow(
                  Icons.place,
                  provider.formatDistance(distance),
                  'de votre position',
                ),
                const SizedBox(height: 12),
              ],
              _buildDetailRow(Icons.home_work_outlined, point.address, ''),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.access_time, point.openingHours, ''),
              if (phoneUrl != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _launch(phoneUrl),
                  child: _buildDetailRow(Icons.phone, point.phone!, 'Appeler'),
                ),
              ],

              const SizedBox(height: 16),

              const Text(
                'Déchets acceptés :',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: point.acceptedWasteTypes.map((type) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: type.uiColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      type.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: type.uiColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _launch(point.getNavigationUrl()),
                  icon: const Icon(Icons.directions),
                  label: const Text('Itinéraire'),
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ligne de détail
  Widget _buildDetailRow(IconData icon, String text, String subText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF4A9B7F), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subText,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFB8C5C0)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
