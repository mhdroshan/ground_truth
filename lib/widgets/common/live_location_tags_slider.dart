import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../theme/app_colors.dart';
import '../../screens/create_post_screen.dart';
import '../../screens/event_detail_screen.dart';

/// A sleek, modern auto-sliding carousel displaying all events/tags
/// matching the user's current physical location.
class LiveLocationTagsSlider extends StatefulWidget {
  final List<EventModel> events;

  const LiveLocationTagsSlider({
    super.key,
    required this.events,
  });

  @override
  State<LiveLocationTagsSlider> createState() => _LiveLocationTagsSliderState();
}

class _LiveLocationTagsSliderState extends State<LiveLocationTagsSlider> {
  static const int _kLoopFactor = 400;
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  bool _isInteracting = false;

  int get _itemCount => widget.events.length;
  bool get _isMulti => _itemCount > 1;
  int get _initialVirtualPage => _isMulti ? _itemCount * (_kLoopFactor ~/ 2) : 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialVirtualPage);
    _startAutoSlide();
  }

  @override
  void didUpdateWidget(covariant LiveLocationTagsSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events.length != widget.events.length) {
      _stopAutoSlide();
      if (_currentPage >= widget.events.length) {
        _currentPage = 0;
      }
      if (_isMulti) {
        _startAutoSlide();
      }
    }
  }

  @override
  void dispose() {
    _stopAutoSlide();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _stopAutoSlide();
    if (!_isMulti) return;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4, milliseconds: 500), (timer) {
      if (!mounted || !_pageController.hasClients || _isInteracting) return;
      final currentVirtual = _pageController.page?.round() ?? _initialVirtualPage;
      _pageController.animateToPage(
        currentVirtual + 1,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _stopAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
  }

  void _goToPage(int targetIndex) {
    if (!_isMulti || !_pageController.hasClients) return;
    _stopAutoSlide();
    final currentVirtual = _pageController.page?.round() ?? _initialVirtualPage;
    final currentActual = currentVirtual % _itemCount;
    final diff = targetIndex - currentActual;
    _pageController.animateToPage(
      currentVirtual + diff,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
    // Restart auto-slide after brief pause
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isInteracting) {
        _startAutoSlide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 248,
          child: Listener(
            onPointerDown: (_) {
              _isInteracting = true;
              _stopAutoSlide();
            },
            onPointerUp: (_) {
              _isInteracting = false;
              _startAutoSlide();
            },
            onPointerCancel: (_) {
              _isInteracting = false;
              _startAutoSlide();
            },
            child: PageView.builder(
              controller: _pageController,
              physics: _isMulti
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: _isMulti ? _itemCount * _kLoopFactor : 1,
              onPageChanged: (vIndex) {
                final actual = vIndex % _itemCount;
                if (actual != _currentPage) {
                  setState(() {
                    _currentPage = actual;
                  });
                }
              },
              itemBuilder: (context, index) {
                final actualIndex = index % _itemCount;
                final event = widget.events[actualIndex];
                return _buildHeroCard(context, event, actualIndex, _itemCount);
              },
            ),
          ),
        ),

        // Animated Dots Indicator (only if multiple matching tags)
        if (_isMulti) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_itemCount, (i) {
              final isSelected = i == _currentPage;
              return GestureDetector(
                onTap: () => _goToPage(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: isSelected ? 22 : 6,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryNavy
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    EventModel event,
    int index,
    int totalCount,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF091427),
            Color(0xFF132B52),
            Color(0xFF1A3D73),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0038A8).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Header Row: Live Badge, Tag Name, Slide Counter
          Row(
            children: [
              // Live in your location badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7.5,
                      height: 7.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5.5),
                    const Text(
                      'LIVE IN YOUR LOCATION',
                      style: TextStyle(
                        color: Color(0xFFFECACA),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Tag Name Pill
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    event.tagName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Slide Counter (if multi) or Radius badge (if single)
              if (totalCount > 1) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_motion_rounded,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${index + 1}/$totalCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        size: 11,
                        color: Color(0xFF38BDF8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.formattedRadius,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1.25,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Eyewitness Verification Needed Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.campaign_rounded,
                  color: Color(0xFFFBBF24),
                  size: 22,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Eyewitness Verification Needed!',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2.5),
                      Text(
                        'There is an event happening in your location (${event.formattedRadius} radius). Please write something about what is happening around you!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreatePostScreen(event: event),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    size: 20,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'Write Post Now',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailScreen(eventId: event.id),
                      ),
                    );
                  },
                  child: const Text(
                    'View Tag',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
