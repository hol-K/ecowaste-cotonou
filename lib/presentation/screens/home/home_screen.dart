// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/collection_schedule.dart';
import '../../../data/models/user_statistics.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_navigation_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/waste_visuals.dart';
import '../calendar/calendar_screen.dart';
import '../guide/guide_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';

/// Écran principal : barre de navigation + onglets conservés en mémoire
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // IndexedStack : chaque onglet garde son état (scroll, carte, recherche…)
  static const List<Widget> _screens = [
    HomePage(),
    CalendarScreen(),
    GuideScreen(),
    MapScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<HomeNavigationProvider>().reset();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<HomeNavigationProvider>();
    final index = navigation.current.index;

    return Scaffold(
      backgroundColor: const Color(0xFF1A3329),
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => navigation.goTo(HomeTab.values[i]),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E4538),
        selectedItemColor: const Color(0xFF4A9B7F),
        unselectedItemColor: const Color(0xFFB8C5C0),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Calendrier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_rounded),
            label: 'Guide',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Carte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Page d'accueil (Dashboard)
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().userProfile;
    final schedules = context.watch<ScheduleProvider>();
    final navigation = context.read<HomeNavigationProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: schedules.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec salutation
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.getWelcomeMessage() ?? 'Bonjour 👋',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatToday(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFB8C5C0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline),
                    color: Colors.white,
                    tooltip: 'Mon profil',
                    onPressed: () => navigation.goTo(HomeTab.profile),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Card principale : Prochaine collecte
              GestureDetector(
                onTap: () => navigation.goTo(HomeTab.calendar),
                child: _buildNextCollectionCard(schedules),
              ),

              const SizedBox(height: 24),

              const Text(
                'Actions rapides',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              _buildQuickActionsGrid(navigation),

              const SizedBox(height: 24),

              const Text(
                'Votre impact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              _buildStatisticsCard(profile?.statistics),
            ],
          ),
        ),
      ),
    );
  }

  /// Card de la prochaine collecte
  Widget _buildNextCollectionCard(ScheduleProvider schedules) {
    final CollectionSchedule? next = schedules.nextSchedule;
    final color = next?.wasteType.uiColor ?? const Color(0xFF4A9B7F);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D5F4F), Color(0xFF234037)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  next?.wasteType.icon ?? Icons.event_busy,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prochaine collecte · ${schedules.currentDistrict}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB8C5C0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      next?.wasteType.displayName ??
                          (schedules.isLoading
                              ? 'Chargement…'
                              : 'Aucune collecte programmée'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 16),
            Divider(color: color, thickness: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        next.getFormattedDate(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        next.collectionTime,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFB8C5C0),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    next.getCountdownText(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Grid des actions rapides
  Widget _buildQuickActionsGrid(HomeNavigationProvider navigation) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildQuickActionCard(
          icon: Icons.calendar_today_rounded,
          title: 'Calendrier',
          color: const Color(0xFF42A5F5),
          onTap: () => navigation.goTo(HomeTab.calendar),
        ),
        _buildQuickActionCard(
          icon: Icons.book_rounded,
          title: 'Guide de Tri',
          color: const Color(0xFF66BB6A),
          onTap: () => navigation.goTo(HomeTab.guide),
        ),
        _buildQuickActionCard(
          icon: Icons.map_rounded,
          title: 'Points de collecte',
          color: const Color(0xFFFFA726),
          onTap: () => navigation.goTo(HomeTab.map),
        ),
        _buildQuickActionCard(
          icon: Icons.emoji_events_outlined,
          title: 'Mon impact',
          color: const Color(0xFFAB47BC),
          onTap: () => navigation.goTo(HomeTab.profile),
        ),
      ],
    );
  }

  /// Card d'action rapide individuelle
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0x14FFFFFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card des statistiques (profil connecté, sinon tirets)
  Widget _buildStatisticsCard(UserStatistics? stats) {
    final kg = NumberFormat('0.0', 'fr_FR');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            stats != null ? '${stats.consecutiveDays}' : '—',
            'jours 🔥',
          ),
          Container(width: 1, height: 40, color: const Color(0xFF4A9B7F)),
          _buildStatItem(
            stats != null ? '${kg.format(stats.totalWasteRecycled)} kg' : '—',
            'recyclés',
          ),
          Container(width: 1, height: 40, color: const Color(0xFF4A9B7F)),
          _buildStatItem(
            stats != null ? '${kg.format(stats.co2Avoided)} kg' : '—',
            'CO₂ évités',
          ),
        ],
      ),
    );
  }

  /// Item de statistique individuel
  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A9B7F),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFFB8C5C0)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Date du jour en français, ex : « Lundi 28 septembre 2026 »
  String _formatToday() {
    final text = DateFormat('EEEE d MMMM y', 'fr_FR').format(DateTime.now());
    return text[0].toUpperCase() + text.substring(1);
  }
}
