import 'package:flutter/material.dart';

import '../../../common/constant/theme_config.dart';
import '../../../common/widget/app_dialog.dart';
import '../../../common/widget/app_notification.dart';
import '../../../common/widget/scaffold_key_scope.dart';

// ══════════════════════════════════════════════════════════════════════════
//  PAGE
// ══════════════════════════════════════════════════════════════════════════

class HotelsPage extends StatelessWidget {
  const HotelsPage({super.key});

  // ── Picsum placeholder images (seed-stable) ──────────────────────────
  static const _hotelImages = [
    'https://picsum.photos/seed/hotel1/600/400',
    'https://picsum.photos/seed/hotel2/600/400',
    'https://picsum.photos/seed/hotel3/600/400',
    'https://picsum.photos/seed/hotel4/600/400',
  ];

  static const _roomImages = [
    'https://picsum.photos/seed/room1/400/300',
    'https://picsum.photos/seed/room2/400/300',
    'https://picsum.photos/seed/room3/400/300',
    'https://picsum.photos/seed/room4/400/300',
  ];

  // ── Demo hotel data ───────────────────────────────────────────────────
  static const _hotels = [
    _HotelData(
      name: 'Grand Palace Hotel',
      location: 'Istanbul, Turkey',
      rating: 4.9,
      price: 320,
      tag: 'BEST DEAL',
      tagColor: Color(0xFF00D68F),
      imageIndex: 0,
      amenities: ['WiFi', 'Pool', 'Spa', 'Gym'],
    ),
    _HotelData(
      name: 'Azure Skyline Resort',
      location: 'Dubai, UAE',
      rating: 4.7,
      price: 480,
      tag: 'POPULAR',
      tagColor: Color(0xFF1B8EF8),
      imageIndex: 1,
      amenities: ['WiFi', 'Rooftop', 'Bar', 'Concierge'],
    ),
    _HotelData(
      name: 'Sakura Zen Retreat',
      location: 'Kyoto, Japan',
      rating: 4.8,
      price: 275,
      tag: 'EXCLUSIVE',
      tagColor: Color(0xFF7C6FF7),
      imageIndex: 2,
      amenities: ['WiFi', 'Onsen', 'Garden', 'Breakfast'],
    ),
  ];

  // ── Dialog triggers ───────────────────────────────────────────────────

  void _showSuccessDialog(BuildContext context) {
    AppDialog.show(
      context: context,
      type: AppDialogType.success,
      title: 'Booking Confirmed!',
      message:
          'Your reservation at Grand Palace Hotel has been successfully confirmed. '
          'Check your email for the full itinerary.',
      images: _roomImages,
      primaryAction: AppDialogAction(
        label: 'View Booking',
        onTap: () {},
      ),
      secondaryAction: const AppDialogAction(
        label: 'Close',
        onTap: _noop,
      ),
    );
  }

  void _showErrorDialog(BuildContext context) {
    AppDialog.show(
      context: context,
      type: AppDialogType.error,
      title: 'Payment Failed',
      message:
          'We couldn\'t process your payment for this reservation. '
          'Please check your card details and try again.',
      images: [_hotelImages[1], _hotelImages[3]],
      primaryAction: AppDialogAction(
        label: 'Retry Payment',
        onTap: () {},
      ),
      secondaryAction: const AppDialogAction(
        label: 'Cancel',
        onTap: _noop,
      ),
    );
  }

  void _showWarningDialog(BuildContext context) {
    AppDialog.show(
      context: context,
      type: AppDialogType.warning,
      title: 'Cancel Reservation?',
      message:
          'Cancelling less than 48 hours before check-in will incur a '
          '50% penalty charge. Are you sure you want to continue?',
      images: [_hotelImages[2]],
      primaryAction: AppDialogAction(
        label: 'Yes, Cancel',
        onTap: () {},
      ),
      secondaryAction: const AppDialogAction(
        label: 'Keep Booking',
        onTap: _noop,
      ),
    );
  }

  void _showInfoDialogNoImages(BuildContext context) {
    AppDialog.show(
      context: context,
      type: AppDialogType.success,
      title: 'Room Upgrade Available',
      message:
          'A junior suite is available for your stay at a small additional cost. '
          'Enjoy panoramic views and a private jacuzzi.',
      primaryAction: AppDialogAction(
        label: 'Upgrade — \$49/night',
        onTap: () {},
      ),
    );
  }

  // ── Notification triggers ─────────────────────────────────────────────

  void _showSuccessNotification(BuildContext context) {
    AppNotification.show(
      context: context,
      type: AppNotificationType.success,
      title: 'Check-in Complete',
      message: 'Welcome to Grand Palace Hotel, Room 412.',
      images: [_hotelImages[0]],
    );
  }

  void _showErrorNotification(BuildContext context) {
    AppNotification.show(
      context: context,
      type: AppNotificationType.error,
      title: 'Booking Failed',
      message:
          'No rooms available for selected dates. Please choose another period.',
    );
  }

  void _showWarningNotification(BuildContext context) {
    AppNotification.show(
      context: context,
      type: AppNotificationType.warning,
      title: 'Checkout Reminder',
      message: 'Your checkout time is in 2 hours. Late fee may apply.',
      images: [_hotelImages[2], _hotelImages[3]],
    );
  }

  void _showInfoNotification(BuildContext context) {
    AppNotification.show(
      context: context,
      type: AppNotificationType.info,
      title: 'Special Offer',
      message:
          '30% off for bookings this weekend. Use code DUONET30 at checkout.',
    );
  }

  static void _noop() {}

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () =>
              ScaffoldKeyScope.of(context).currentState?.openDrawer(),
        ),
        title: const Text('Hotels'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showInfoDialogNoImages(context),
            tooltip: 'Filters',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search bar ───────────────────────────────────────────
            _SearchBar(isDark: isDark),

            const SizedBox(height: 24),

            // ── Dialog demo section ──────────────────────────────────
            _SectionHeader(title: 'Dialog Examples', isDark: isDark),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _DemoButton(
                      label: 'Success',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.emerald,
                      onTap: () => _showSuccessDialog(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DemoButton(
                      label: 'Error',
                      icon: Icons.error_outline_rounded,
                      color: AppColors.coral,
                      onTap: () => _showErrorDialog(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DemoButton(
                      label: 'Warning',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.amber,
                      onTap: () => _showWarningDialog(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Notification demo section ────────────────────────────
            _SectionHeader(title: 'Notification Examples', isDark: isDark),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _DemoButton(
                      label: 'Success',
                      icon: Icons.check_rounded,
                      color: AppColors.emerald,
                      onTap: () => _showSuccessNotification(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DemoButton(
                      label: 'Error',
                      icon: Icons.close_rounded,
                      color: AppColors.coral,
                      onTap: () => _showErrorNotification(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DemoButton(
                      label: 'Warning',
                      icon: Icons.priority_high_rounded,
                      color: AppColors.amber,
                      onTap: () => _showWarningNotification(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DemoButton(
                      label: 'Info',
                      icon: Icons.info_outline_rounded,
                      color: AppColors.electricBlue,
                      onTap: () => _showInfoNotification(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Hotel cards ──────────────────────────────────────────
            _SectionHeader(title: 'Featured Hotels', isDark: isDark),
            const SizedBox(height: 12),
            ..._hotels.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _HotelCard(
                    data: e.value,
                    imageSeed: _hotelImages[e.value.imageIndex],
                    isDark: isDark,
                    onBook: () => _showSuccessDialog(context),
                    onCancel: () => _showWarningDialog(context),
                    onError: () => _showErrorDialog(context),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  DATA
// ══════════════════════════════════════════════════════════════════════════

class _HotelData {
  const _HotelData({
    required this.name,
    required this.location,
    required this.rating,
    required this.price,
    required this.tag,
    required this.tagColor,
    required this.imageIndex,
    required this.amenities,
  });

  final String name;
  final String location;
  final double rating;
  final int price;
  final String tag;
  final Color tagColor;
  final int imageIndex;
  final List<String> amenities;
}

// ══════════════════════════════════════════════════════════════════════════
//  SEARCH BAR
// ══════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded,
                size: 20,
                color: isDark ? Colors.white38 : Colors.grey.shade400),
            const SizedBox(width: 10),
            Text(
              'Search hotels, cities…',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white30 : Colors.grey.shade400,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune_rounded,
                  size: 16, color: AppColors.electricBlue),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  SECTION HEADER
// ══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F1629),
              fontFamily: 'Poppins',
            ),
          ),
          const Spacer(),
          Text(
            'See all',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.electricBlue,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  DEMO BUTTON
// ══════════════════════════════════════════════════════════════════════════

class _DemoButton extends StatefulWidget {
  const _DemoButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_DemoButton> createState() => _DemoButtonState();
}

class _DemoButtonState extends State<_DemoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 130));
    _scale = Tween(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, _) => Transform.scale(
          scale: _scale.value,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.28),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: widget.color, size: 20),
                const SizedBox(height: 5),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                    fontFamily: 'Poppins',
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  HOTEL CARD
// ══════════════════════════════════════════════════════════════════════════

class _HotelCard extends StatefulWidget {
  const _HotelCard({
    required this.data,
    required this.imageSeed,
    required this.isDark,
    required this.onBook,
    required this.onCancel,
    required this.onError,
  });

  final _HotelData data;
  final String imageSeed;
  final bool isDark;
  final VoidCallback onBook;
  final VoidCallback onCancel;
  final VoidCallback onError;

  @override
  State<_HotelCard> createState() => _HotelCardState();
}

class _HotelCardState extends State<_HotelCard> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final isDark = widget.isDark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.07),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image ─────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    widget.imageSeed,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 190,
                      color: d.tagColor.withValues(alpha: 0.12),
                      child: Icon(Icons.hotel_rounded,
                          color: d.tagColor.withValues(alpha: 0.4), size: 48),
                    ),
                  ),
                ),
                // Tag badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: d.tagColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: d.tagColor.withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      d.tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                // Save button
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => setState(() => _saved = !_saved),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.50)
                            : Colors.white.withValues(alpha: 0.90),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        _saved
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                        color:
                            _saved ? AppColors.coral : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Info section ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          d.name,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F1629),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 3),
                          Text(
                            d.rating.toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF59E0B),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14,
                          color: isDark
                              ? Colors.white38
                              : Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text(
                        d.location,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? Colors.white38
                              : Colors.grey.shade500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Amenity chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: d.amenities
                        .map((a) => _AmenityChip(label: a, isDark: isDark))
                        .toList(),
                  ),

                  const SizedBox(height: 14),

                  // Price + action buttons
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${d.price}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F1629),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            'per night',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Cancel button
                      GestureDetector(
                        onTap: widget.onCancel,
                        child: Container(
                          height: 42,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.coral.withValues(
                                alpha: isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  AppColors.coral.withValues(alpha: 0.30),
                              width: 1.2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.coral,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Book button
                      GestureDetector(
                        onTap: widget.onBook,
                        child: Container(
                          height: 42,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.electricBlue,
                                AppColors.deepIndigo,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.electricBlue
                                    .withValues(alpha: 0.40),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Book Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  AMENITY CHIP
// ══════════════════════════════════════════════════════════════════════════

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  static IconData _amenityIcon(String label) => switch (label.toLowerCase()) {
        'wifi'       => Icons.wifi_rounded,
        'pool'       => Icons.pool_rounded,
        'spa'        => Icons.spa_rounded,
        'gym'        => Icons.fitness_center_rounded,
        'bar'        => Icons.local_bar_rounded,
        'breakfast'  => Icons.free_breakfast_rounded,
        'rooftop'    => Icons.roofing_rounded,
        'garden'     => Icons.park_rounded,
        'concierge'  => Icons.room_service_rounded,
        'onsen'      => Icons.hot_tub_rounded,
        _            => Icons.check_circle_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_amenityIcon(label),
              size: 11,
              color: isDark ? Colors.white54 : Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}