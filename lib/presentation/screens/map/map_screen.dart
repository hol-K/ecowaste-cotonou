import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Écran de la carte des points de collecte avec OpenStreetMap
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  String _selectedFilter = 'Tous';
  LatLng? _userLocation;
  bool _isLoadingLocation = false;

  
  final LatLng _cotonouCenter = const LatLng(6.3654, 2.4183);

  final List<String> _filters = [
    'Tous',
    'Déchetterie',
    'Recyclage',
    'Verre',
    'Dangereux',
    'Électronique',
  ];

  // Points de collecte avec coordonnées réelles de Cotonou
  final List<CollectionPoint> _points = [
    CollectionPoint(
      name: 'Déchetterie Municipale d\'Akpakpa',
      address: 'Route de Porto-Novo, Akpakpa',
      types: ['Tous types'],
      location: const LatLng(6.3598, 2.4378),
      isOpen: true,
      color: const Color(0xFF4A9B7F),
      phone: '+229 97 00 00 01',
      hours: 'Lun-Sam: 08:00-18:00',
    ),
    CollectionPoint(
      name: 'Point de Collecte Recyclable Cadjèhoun',
      address: 'Avenue Steinmetz, Cadjèhoun',
      types: ['Recyclables', 'Papier'],
      location: const LatLng(6.3745, 2.4289),
      isOpen: true,
      color: const Color(0xFF42A5F5),
      phone: '+229 97 00 00 02',
      hours: 'Lun-Sam: 08:00-18:00',
    ),
    CollectionPoint(
      name: 'Centre de Tri de Godomey',
      address: 'Route de Ouidah, Godomey',
      types: ['Tous types'],
      location: const LatLng(6.3890, 2.3456),
      isOpen: false,
      color: const Color(0xFF4A9B7F),
      phone: '+229 97 00 00 03',
      hours: 'Lun-Sam: 08:00-18:00',
    ),
    CollectionPoint(
      name: 'Point de Collecte DEEE Fidjrossè',
      address: 'Boulevard de la Marina, Fidjrossè',
      types: ['Électronique', 'Dangereux'],
      location: const LatLng(6.3512, 2.4512),
      isOpen: true,
      color: const Color(0xFFAB47BC),
      phone: '+229 97 00 00 04',
      hours: 'Lun-Sam: 08:00-18:00',
    ),
    CollectionPoint(
      name: 'Recyclerie Communautaire de Vossa',
      address: 'Quartier Vossa',
      types: ['Recyclables', 'Verre'],
      location: const LatLng(6.3823, 2.4423),
      isOpen: true,
      color: const Color(0xFF42A5F5),
      phone: '+229 97 00 00 05',
      hours: 'Lun-Sam: 08:00-18:00',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Filtre les points selon le filtre sélectionné
  List<CollectionPoint> get _filteredPoints {
    if (_selectedFilter == 'Tous') return _points;
    return _points.where((point) {
      return point.types.any((type) =>
          type.toLowerCase().contains(_selectedFilter.toLowerCase()));
    }).toList();
  }

  /// Obtient la position GPS de l'utilisateur
  Future<void> _getUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Permission de localisation refusée');
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Permission de localisation refusée définitivement');
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Obtenir la position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Centrer la carte sur la position de l'utilisateur
      _mapController.move(_userLocation!, 13.0);
    } catch (e) {
      _showSnackBar('Erreur lors de la récupération de la position');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  /// Centre la carte sur la position de l'utilisateur
  void _centerOnUserLocation() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.0);
    } else {
      _getUserLocation();
    }
  }

  /// Affiche un message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Calcule la distance entre deux points
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  /// Formate la distance
  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3329),
      appBar: AppBar(
        title: const Text('Points de Collecte'),
        backgroundColor: const Color(0xFF2D5F4F),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Carte OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _cotonouCenter,
              initialZoom: 12.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              // Tuiles OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ecowaste_cotonou',
                tileBuilder: _darkModeTileBuilder,
              ),

              // Marqueurs des points de collecte
              MarkerLayer(
                markers: _filteredPoints.map((point) {
                  return Marker(
                    point: point.location,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showPointDetails(point),
                      child: Container(
                        decoration: BoxDecoration(
                          color: point.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
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

              // Marqueur de la position utilisateur
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A9B7F).withOpacity(0.3),
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFilters(),
          ),

          // Compteur de points
          Positioned(
            top: 70,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3329).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF4A9B7F),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF4A9B7F),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_filteredPoints.length} points',
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
          // Bouton centrer sur ma position
          FloatingActionButton(
            heroTag: 'my_location',
            onPressed: _centerOnUserLocation,
            backgroundColor: const Color(0xFF4A9B7F),
            child: _isLoadingLocation
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
          // Bouton liste
          FloatingActionButton(
            heroTag: 'list',
            onPressed: () => _showPointsList(),
            backgroundColor: const Color(0xFF2D5F4F),
            child: const Icon(Icons.list),
          ),
        ],
      ),
    );
  }

  /// Style sombre pour les tuiles (optionnel)
  Widget _darkModeTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
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
  Widget _buildFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D5F4F).withOpacity(0.95),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
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

  /// Affiche la liste des points en bottom sheet
  void _showPointsList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A3329),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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

            // Titre
            Text(
              'Points de collecte (${_filteredPoints.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Liste
            Expanded(
              child: ListView.builder(
                itemCount: _filteredPoints.length,
                itemBuilder: (context, index) {
                  final point = _filteredPoints[index];
                  final distance = _userLocation != null
                      ? _calculateDistance(_userLocation!, point.location)
                      : null;

                  return _buildPointListItem(point, distance);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Item de la liste
  Widget _buildPointListItem(CollectionPoint point, double? distance) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _mapController.move(point.location, 16.0);
        Future.delayed(const Duration(milliseconds: 500), () {
          _showPointDetails(point);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: point.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: point.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on,
                color: point.color,
                size: 24,
              ),
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
                  if (distance != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDistance(distance),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB8C5C0),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFB8C5C0),
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche les détails d'un point
  void _showPointDetails(CollectionPoint point) {
    final distance = _userLocation != null
        ? _calculateDistance(_userLocation!, point.location)
        : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF234037),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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

            // Nom et statut
            Row(
              children: [
                Expanded(
                  child: Text(
                    point.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: point.isOpen
                        ? const Color(0xFF66BB6A).withOpacity(0.2)
                        : const Color(0xFFEF5350).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    point.isOpen ? 'Ouvert' : 'Fermé',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: point.isOpen
                          ? const Color(0xFF66BB6A)
                          : const Color(0xFFEF5350),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Informations
            if (distance != null)
              _buildDetailRow(
                Icons.place,
                _formatDistance(distance),
                'de votre position',
              ),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.home_work_outlined, point.address, ''),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.access_time, point.hours, ''),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.phone, point.phone, 'Appeler'),

            const SizedBox(height: 16),

            // Types acceptés
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
              children: point.types.map((type) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: point.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 12,
                      color: point.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Bouton itinéraire
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showSnackBar('Fonctionnalité itinéraire à venir...');
                },
                icon: const Icon(Icons.directions),
                label: const Text('Itinéraire'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A9B7F),
                ),
              ),
            ),
          ],
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB8C5C0),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Modèle de données pour un point de collecte
class CollectionPoint {
  final String name;
  final String address;
  final List<String> types;
  final LatLng location;
  final bool isOpen;
  final Color color;
  final String phone;
  final String hours;

  CollectionPoint({
    required this.name,
    required this.address,
    required this.types,
    required this.location,
    required this.isOpen,
    required this.color,
    required this.phone,
    required this.hours,
  });
}