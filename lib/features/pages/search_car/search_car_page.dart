import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/util/responsive.dart';
import '../../../common/widget/app_dropdown.dart';
import '../../../common/widget/scaffold_key_scope.dart';

// ── Demo data ────────────────────────────────────────────────────────────────

const _kBrands = [
  'Toyota', 'BMW', 'Mercedes-Benz', 'Audi', 'Honda', 'Ford',
  'Volkswagen', 'Hyundai', 'Kia', 'Tesla', 'Nissan', 'Chevrolet',
  'Lexus', 'Porsche', 'Range Rover', 'Volvo', 'Subaru', 'Mazda',
];

const _kFuelTypes = [
  'Petrol', 'Diesel', 'Electric', 'Hybrid', 'Plug-in Hybrid', 'LPG / CNG',
];

const _kBodyTypes = [
  'Sedan', 'SUV', 'Hatchback', 'Coupe', 'Station Wagon',
  'Convertible', 'Minivan', 'Pickup Truck', 'Crossover',
];

const _kTransmissions = ['Automatic', 'Manual', 'CVT', 'Dual-Clutch (DCT)'];

const _kFeatures = [
  'Air Conditioning', 'GPS Navigation', 'Bluetooth Audio',
  'Sunroof / Moonroof', 'Leather Seats', 'Backup Camera',
  'Heated Seats', 'Cruise Control', 'Blind Spot Monitor',
  'Parking Sensors', 'Apple CarPlay', 'Android Auto',
  'Lane Assist', 'Adaptive Headlights', '360° Camera',
];

const _kColors = [
  'Pearl White', 'Jet Black', 'Metallic Silver', 'Flame Red',
  'Ocean Blue', 'Forest Green', 'Graphite Grey', 'Champagne Gold',
  'Midnight Navy', 'Burnt Orange', 'Sand Beige',
];

const _kPriceRanges = [
  'Under \$10,000', '\$10,000 – \$20,000', '\$20,000 – \$35,000',
  '\$35,000 – \$50,000', '\$50,000 – \$75,000', 'Above \$75,000',
];

// Years list 2005 → 2025
final _kYears = List.generate(21, (i) => '${2025 - i}');

// ── Purpose-driven accent colors ─────────────────────────────────────────────
const _kBrandColor = Color(0xFF1B8EF8);       // Electric Blue — trust
const _kYearColor = Color(0xFF4C5FD5);        // Indigo — time / history
const _kFuelColor = Color(0xFF00D68F);        // Emerald — eco / energy
const _kBodyColor = Color(0xFF00E5CC);        // Teal — form / shape
const _kTransColor = Color(0xFFF59E0B);       // Amber — power / mechanics
const _kPriceColor = Color(0xFF7C6FF7);       // Purple — value / premium
const _kFeaturesColor = Color(0xFF7C6FF7);    // Purple — extra / premium
const _kColorAccent = Color(0xFFFF4081);      // Pink — aesthetics

// ── Demo vehicles ─────────────────────────────────────────────────────────

class _Vehicle {
  const _Vehicle({
    required this.brand,
    required this.model,
    required this.year,
    required this.fuel,
    required this.body,
    required this.transmission,
    required this.price,
    required this.color,
    required this.features,
    required this.mileage,
    required this.accentColor,
  });

  final String brand;
  final String model;
  final String year;
  final String fuel;
  final String body;
  final String transmission;
  final int price;
  final String color;
  final List<String> features;
  final String mileage;
  final Color accentColor;
}

const _kVehicles = [
  _Vehicle(
    brand: 'BMW',
    model: '3 Series 330i',
    year: '2023',
    fuel: 'Petrol',
    body: 'Sedan',
    transmission: 'Automatic',
    price: 47500,
    color: 'Alpine White',
    mileage: '12,400 km',
    features: ['Sunroof', 'Leather Seats', 'GPS Navigation', 'Cruise Control'],
    accentColor: Color(0xFF1B8EF8),
  ),
  _Vehicle(
    brand: 'Tesla',
    model: 'Model Y Long Range',
    year: '2024',
    fuel: 'Electric',
    body: 'SUV',
    transmission: 'Automatic',
    price: 54990,
    color: 'Midnight Silver',
    mileage: '3,200 km',
    features: ['Autopilot', 'Heated Seats', 'Apple CarPlay', 'Backup Camera'],
    accentColor: Color(0xFF00D68F),
  ),
  _Vehicle(
    brand: 'Toyota',
    model: 'Camry Hybrid',
    year: '2023',
    fuel: 'Hybrid',
    body: 'Sedan',
    transmission: 'CVT',
    price: 31800,
    color: 'Midnight Blue',
    mileage: '22,100 km',
    features: ['Air Conditioning', 'Bluetooth Audio', 'Backup Camera', 'Lane Assist'],
    accentColor: Color(0xFF00E5CC),
  ),
  _Vehicle(
    brand: 'Porsche',
    model: 'Cayenne E-Hybrid',
    year: '2022',
    fuel: 'Plug-in Hybrid',
    body: 'SUV',
    transmission: 'Automatic',
    price: 89000,
    color: 'Jet Black',
    mileage: '18,700 km',
    features: ['Sunroof', 'Leather Seats', 'Adaptive Headlights', '360° Camera'],
    accentColor: Color(0xFF7C6FF7),
  ),
  _Vehicle(
    brand: 'Ford',
    model: 'Ranger Raptor',
    year: '2024',
    fuel: 'Diesel',
    body: 'Pickup Truck',
    transmission: 'Automatic',
    price: 62500,
    color: 'Flame Red',
    mileage: '4,800 km',
    features: ['GPS Navigation', 'Parking Sensors', 'Blind Spot Monitor', 'Cruise Control'],
    accentColor: Color(0xFFF59E0B),
  ),
];

// ═════════════════════════════════════════════════════════════════════════════
//  Page
// ═════════════════════════════════════════════════════════════════════════════

class SearchCarPage extends StatefulWidget {
  const SearchCarPage({super.key});

  @override
  State<SearchCarPage> createState() => _SearchCarPageState();
}

class _SearchCarPageState extends State<SearchCarPage> {
  // Single-select states
  String? _brand;
  String? _year;
  String? _fuel;
  String? _body;
  String? _transmission;
  String? _price;

  // Multi-select states
  List<String> _features = [];
  List<String> _selectedColors = [];

  void _onSearch() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.search_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _buildSearchSummary(),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _buildSearchSummary() {
    final parts = <String>[];
    if (_brand != null) parts.add(_brand!);
    if (_year != null) parts.add(_year!);
    if (_fuel != null) parts.add(_fuel!);
    if (_body != null) parts.add(_body!);
    if (_features.isNotEmpty) parts.add('${_features.length} features');
    if (_selectedColors.isNotEmpty) parts.add('${_selectedColors.length} colors');
    return parts.isEmpty
        ? 'Searching all vehicles…'
        : 'Searching: ${parts.join(' · ')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF07091A) : const Color(0xFFF4F6FB),
      appBar: _buildAppBar(isDark),
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHero(isDark, isTablet)),

          // ── Search form ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildSearchForm(isDark, isTablet, isLandscape),
          ),

          // ── Vehicles section ─────────────────────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader(isDark, isTablet)),

          // Vehicle list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _VehicleCard(
                vehicle: _kVehicles[i],
                isDark: isDark,
                isTablet: isTablet,
                index: i,
              ),
              childCount: _kVehicles.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF07091A) : const Color(0xFFF4F6FB),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () =>
            ScaffoldKeyScope.of(context).currentState?.openDrawer(),
      ),
      title: Text(
        'Vehicle Search',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 17,
          color: isDark ? Colors.white : const Color(0xFF0F1629),
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
                ),
              ),
              child: const Icon(Icons.tune_rounded,
                  size: 17, color: Color(0xFFF59E0B)),
            ),
            onPressed: () {},
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildHero(bool isDark, bool isTablet) {
    return Container(
      margin: EdgeInsets.fromLTRB(
          isTablet ? 20 : 16, 16, isTablet ? 20 : 16, 0),
      padding: EdgeInsets.all(isTablet ? 28 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFFF59E0B), Color(0xFFFFD166)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.40),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find Your Perfect\nVehicle',
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_kVehicles.length} vehicles available · Updated live',
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 12,
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: isTablet ? 80 : 64,
            height: isTablet ? 80 : 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_car_rounded,
                size: isTablet ? 42 : 34, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchForm(bool isDark, bool isTablet, bool isLandscape) {
    final pad = isTablet ? 20.0 : 16.0;
    final cardBg = isDark ? const Color(0xFF0D1225) : Colors.white;
    final twoCol = isTablet || isLandscape;

    return Container(
      margin: EdgeInsets.fromLTRB(pad, 16, pad, 0),
      padding: EdgeInsets.all(isTablet ? 24 : 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormSectionTitle(label: 'Vehicle Details', isDark: isDark),
          const SizedBox(height: 14),

          // Brand + Year
          twoCol
              ? Row(
                  children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Brand',
                        hint: 'Select brand',
                        prefixIcon: Icons.car_rental_rounded,
                        accentColor: _kBrandColor,
                        items: _kBrands,
                        value: _brand,
                        displayBuilder: (v) => v,
                        onChanged: (v) => setState(() => _brand = v),
                        searchHint: 'Search brands...',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Year',
                        hint: 'Select year',
                        prefixIcon: Icons.calendar_today_rounded,
                        accentColor: _kYearColor,
                        items: _kYears,
                        value: _year,
                        displayBuilder: (v) => v,
                        onChanged: (v) => setState(() => _year = v),
                        searchable: false,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    AppDropdown<String>(
                      label: 'Brand',
                      hint: 'Select brand',
                      prefixIcon: Icons.car_rental_rounded,
                      accentColor: _kBrandColor,
                      items: _kBrands,
                      value: _brand,
                      displayBuilder: (v) => v,
                      onChanged: (v) => setState(() => _brand = v),
                      searchHint: 'Search brands...',
                    ),
                    const SizedBox(height: 12),
                    AppDropdown<String>(
                      label: 'Year',
                      hint: 'Select year',
                      prefixIcon: Icons.calendar_today_rounded,
                      accentColor: _kYearColor,
                      items: _kYears,
                      value: _year,
                      displayBuilder: (v) => v,
                      onChanged: (v) => setState(() => _year = v),
                      searchable: false,
                    ),
                  ],
                ),

          const SizedBox(height: 12),

          // Fuel + Body
          twoCol
              ? Row(
                  children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Fuel Type',
                        hint: 'Select fuel',
                        prefixIcon: Icons.local_gas_station_rounded,
                        accentColor: _kFuelColor,
                        items: _kFuelTypes,
                        value: _fuel,
                        displayBuilder: (v) => v,
                        onChanged: (v) => setState(() => _fuel = v),
                        searchable: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Body Type',
                        hint: 'Select body',
                        prefixIcon: Icons.directions_car_filled_rounded,
                        accentColor: _kBodyColor,
                        items: _kBodyTypes,
                        value: _body,
                        displayBuilder: (v) => v,
                        onChanged: (v) => setState(() => _body = v),
                        searchable: false,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    AppDropdown<String>(
                      label: 'Fuel Type',
                      hint: 'Select fuel type',
                      prefixIcon: Icons.local_gas_station_rounded,
                      accentColor: _kFuelColor,
                      items: _kFuelTypes,
                      value: _fuel,
                      displayBuilder: (v) => v,
                      onChanged: (v) => setState(() => _fuel = v),
                      searchable: false,
                    ),
                    const SizedBox(height: 12),
                    AppDropdown<String>(
                      label: 'Body Type',
                      hint: 'Select body type',
                      prefixIcon: Icons.directions_car_filled_rounded,
                      accentColor: _kBodyColor,
                      items: _kBodyTypes,
                      value: _body,
                      displayBuilder: (v) => v,
                      onChanged: (v) => setState(() => _body = v),
                      searchable: false,
                    ),
                  ],
                ),

          const SizedBox(height: 12),

          // Transmission + Price
          twoCol
              ? Row(
                  children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Transmission',
                        hint: 'Select type',
                        prefixIcon: Icons.settings_rounded,
                        accentColor: _kTransColor,
                        items: _kTransmissions,
                        value: _transmission,
                        displayBuilder: (v) => v,
                        onChanged: (v) => setState(() => _transmission = v),
                        searchable: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Price Range',
                        hint: 'Select budget',
                        prefixIcon: Icons.attach_money_rounded,
                        accentColor: _kPriceColor,
                        items: _kPriceRanges,
                        value: _price,
                        displayBuilder: (v) => v,
                        onChanged: (v) => setState(() => _price = v),
                        searchable: false,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    AppDropdown<String>(
                      label: 'Transmission',
                      hint: 'Select transmission',
                      prefixIcon: Icons.settings_rounded,
                      accentColor: _kTransColor,
                      items: _kTransmissions,
                      value: _transmission,
                      displayBuilder: (v) => v,
                      onChanged: (v) => setState(() => _transmission = v),
                      searchable: false,
                    ),
                    const SizedBox(height: 12),
                    AppDropdown<String>(
                      label: 'Price Range',
                      hint: 'Select budget',
                      prefixIcon: Icons.attach_money_rounded,
                      accentColor: _kPriceColor,
                      items: _kPriceRanges,
                      value: _price,
                      displayBuilder: (v) => v,
                      onChanged: (v) => setState(() => _price = v),
                      searchable: false,
                    ),
                  ],
                ),

          const SizedBox(height: 20),
          _FormSectionTitle(label: 'Features & Appearance', isDark: isDark),
          const SizedBox(height: 14),

          // Features multi-select
          AppMultiDropdown<String>(
            label: 'Required Features',
            hint: 'Select features...',
            prefixIcon: Icons.stars_rounded,
            accentColor: _kFeaturesColor,
            items: _kFeatures,
            selectedItems: _features,
            displayBuilder: (v) => v,
            searchHint: 'Search features...',
            onChanged: (v) => setState(() => _features = v),
          ),

          const SizedBox(height: 12),

          // Color multi-select
          AppMultiDropdown<String>(
            label: 'Preferred Colors',
            hint: 'Select colors...',
            prefixIcon: Icons.palette_rounded,
            accentColor: _kColorAccent,
            items: _kColors,
            selectedItems: _selectedColors,
            displayBuilder: (v) => v,
            searchable: false,
            onChanged: (v) => setState(() => _selectedColors = v),
          ),

          const SizedBox(height: 22),

          // Search button
          _SearchButton(onTap: _onSearch),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(bool isDark, bool isTablet) {
    final pad = isTablet ? 20.0 : 16.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad + 4, 24, pad + 4, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Available Vehicles',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F1629),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.28)),
            ),
            child: Text(
              '${_kVehicles.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Form helpers ──────────────────────────────────────────────────────────────

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : const Color(0xFF0F1629),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.grey.shade200,
          ),
        ),
      ],
    );
  }
}

class _SearchButton extends StatefulWidget {
  const _SearchButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SearchButton> createState() => _SearchButtonState();
}

class _SearchButtonState extends State<_SearchButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0,
      upperBound: 0.04,
    );
    _scale = Tween(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB45309), Color(0xFFF59E0B), Color(0xFFFFD166)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.42),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Search Vehicles',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Vehicle card ──────────────────────────────────────────────────────────────

class _VehicleCard extends StatefulWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.isDark,
    required this.isTablet,
    required this.index,
  });

  final _Vehicle vehicle;
  final bool isDark;
  final bool isTablet;
  final int index;

  @override
  State<_VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<_VehicleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 80 + widget.index * 70), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final isDark = widget.isDark;
    final isTablet = widget.isTablet;
    final color = v.accentColor;
    final cardBg = isDark ? const Color(0xFF0D1225) : Colors.white;
    final pad = isTablet ? 20.0 : 16.0;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: EdgeInsets.symmetric(
              horizontal: pad, vertical: isTablet ? 8 : 6),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border(left: BorderSide(color: color, width: 4)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.14 : 0.12),
                blurRadius: 20,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 18 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Car icon bubble
                    Container(
                      width: isTablet ? 56 : 48,
                      height: isTablet ? 56 : 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.65)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.directions_car_rounded,
                          color: Colors.white, size: isTablet ? 28 : 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${v.brand} ${v.model}',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 15,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F1629),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _SpecBadge(label: v.year, color: _kYearColor),
                              const SizedBox(width: 5),
                              _SpecBadge(label: v.fuel, color: _kFuelColor),
                              const SizedBox(width: 5),
                              _SpecBadge(label: v.body, color: _kBodyColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${_formatPrice(v.price)}',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        Text(
                          v.mileage,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Details row
                Row(
                  children: [
                    _DetailChip(
                      icon: Icons.settings_rounded,
                      label: v.transmission,
                      color: _kTransColor,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _DetailChip(
                      icon: Icons.palette_rounded,
                      label: v.color,
                      color: _kColorAccent,
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Features chips
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: v.features
                      .map((f) => _FeatureTag(
                          label: f, color: color, isDark: isDark))
                      .toList(),
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _CardActionBtn(
                        icon: Icons.visibility_rounded,
                        label: 'View Details',
                        color: color,
                        isDark: isDark,
                        filled: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CardActionBtn(
                      icon: Icons.bookmark_border_rounded,
                      label: '',
                      color: color,
                      isDark: isDark,
                      filled: false,
                    ),
                    const SizedBox(width: 8),
                    _CardActionBtn(
                      icon: Icons.compare_arrows_rounded,
                      label: '',
                      color: const Color(0xFF7C6FF7),
                      isDark: isDark,
                      filled: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      final k = price ~/ 1000;
      final rem = price % 1000;
      return rem == 0 ? '${k}K' : '$k,${rem.toString().padLeft(3, '0')}';
    }
    return price.toString();
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _SpecBadge extends StatelessWidget {
  const _SpecBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTag extends StatelessWidget {
  const _FeatureTag({
    required this.label,
    required this.color,
    required this.isDark,
  });
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.10 : 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white54 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _CardActionBtn extends StatelessWidget {
  const _CardActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.filled,
  });
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final hasLabel = label.isNotEmpty;
    return Container(
      height: 38,
      padding: EdgeInsets.symmetric(
          horizontal: hasLabel ? 14 : 10, vertical: 0),
      decoration: BoxDecoration(
        gradient: filled
            ? LinearGradient(
                colors: [color, color.withValues(alpha: 0.75)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: filled
            ? null
            : color.withValues(alpha: isDark ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(10),
        border: filled
            ? null
            : Border.all(color: color.withValues(alpha: isDark ? 0.28 : 0.20)),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: filled ? Colors.white : color),
          if (hasLabel) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}