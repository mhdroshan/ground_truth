import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/app_state.dart';
import '../providers/location_service.dart';
import '../services/google_places_service.dart';
import '../theme/app_colors.dart';
import '../utils/geofence_math.dart';
import '../widgets/map/tactical_radar_map.dart';
import '../widgets/common/glass_card.dart';
import 'event_detail_screen.dart';

class CreateTagScreen extends StatefulWidget {
  const CreateTagScreen({super.key});

  @override
  State<CreateTagScreen> createState() => _CreateTagScreenState();
}

class _CreateTagScreenState extends State<CreateTagScreen> {
  final _tagNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationSearchController = TextEditingController();

  // Google Places Selection State
  GeoPoint? _selectedLocation;
  List<PlacePrediction> _placeSuggestions = [];
  bool _isSearchingPlaces = false;
  Timer? _searchDebounce;

  EventCategory _selectedCategory = EventCategory.protest;
  EventScope _selectedScope = EventScope.cityWide;
  String _selectedUnit = 'km'; // 'km' or 'mi'
  double _radiusValue = 2.0;

  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _resetRadiusForScope();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tagNameController.dispose();
    _descriptionController.dispose();
    _locationSearchController.dispose();
    super.dispose();
  }

  void _onLocationQueryChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _placeSuggestions = [];
        _isSearchingPlaces = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearchingPlaces = true);
      final results = await GooglePlacesService.getAutocomplete(query);
      if (mounted) {
        setState(() {
          _placeSuggestions = results;
          _isSearchingPlaces = false;
        });
      }
    });
  }

  Future<void> _selectPlace(PlacePrediction prediction) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearchingPlaces = true;
      _placeSuggestions = [];
      _locationSearchController.text = prediction.mainText;
    });

    final details = await GooglePlacesService.getPlaceDetails(prediction.placeId);
    if (!mounted) return;

    if (details != null) {
      setState(() {
        _selectedLocation = details;
        _isSearchingPlaces = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryNavy,
          content: Text('📍 Geofence anchor set to: ${details.label ?? prediction.mainText}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() => _isSearchingPlaces = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.alertRed,
          content: Text('Could not fetch coordinates for this location'),
        ),
      );
    }
  }

  void _resetRadiusForScope() {
    if (_selectedUnit == 'km') {
      switch (_selectedScope) {
        case EventScope.cityWide:
          _radiusValue = 2.5;
          break;
        case EventScope.stateWide:
          _radiusValue = 50.0;
          break;
        case EventScope.nationWide:
          _radiusValue = 500.0;
          break;
      }
    } else {
      switch (_selectedScope) {
        case EventScope.cityWide:
          _radiusValue = 1.5;
          break;
        case EventScope.stateWide:
          _radiusValue = 30.0;
          break;
        case EventScope.nationWide:
          _radiusValue = 300.0;
          break;
      }
    }
  }

  double get _minRadius {
    return _selectedUnit == 'km' ? _selectedScope.minKm : _selectedScope.minMi;
  }

  double get _maxRadius {
    return _selectedUnit == 'km' ? _selectedScope.maxKm : _selectedScope.maxMi;
  }

  void _onScopeChanged(EventScope scope) {
    setState(() {
      _selectedScope = scope;
      _resetRadiusForScope();
    });
  }

  void _onUnitChanged(String unit) {
    if (_selectedUnit == unit) return;
    setState(() {
      if (unit == 'mi') {
        // km to mi
        _radiusValue = (_radiusValue * 0.621371).clamp(_selectedScope.minMi, _selectedScope.maxMi);
      } else {
        // mi to km
        _radiusValue = (_radiusValue * 1.60934).clamp(_selectedScope.minKm, _selectedScope.maxKm);
      }
      _selectedUnit = unit;
    });
  }

  void _submitTag() {
    final rawName = _tagNameController.text.trim();
    if (rawName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.alertRed,
          content: Text('Please enter an event or tag name'),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    final appState = context.read<AppState>();
    final locationService = context.read<LocationService>();

    // Anchor: Use Google Place selected location, or fallback to current GPS
    final anchorPoint = _selectedLocation ?? locationService.currentLocation;

    final labelParts = (anchorPoint.label ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final tagCity = labelParts.isNotEmpty ? labelParts.first : 'Metro District';
    final tagCountry = labelParts.length > 1 ? labelParts.last : '';

    final createdEvent = appState.createTag(
      title: rawName,
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      scope: _selectedScope,
      radiusValue: _radiusValue,
      radiusUnit: _selectedUnit,
      center: anchorPoint,
      city: tagCity,
      country: tagCountry,
      riskLevel: _selectedCategory == EventCategory.naturalDisaster || _selectedCategory == EventCategory.fire
          ? RiskLevel.critical
          : RiskLevel.high,
    );

    setState(() => _isCreating = false);

    Navigator.pop(context);

    // Open detail screen for newly created tag
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(eventId: createdEvent.id),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0D652D),
        content: Text(
          'Tag "${createdEvent.tagName}" anchored at ${anchorPoint.label ?? 'selected location'} with ${_radiusValue.toStringAsFixed(1)} $_selectedUnit radius!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();
    final userLoc = locationService.currentLocation;
    final activeAnchor = _selectedLocation ?? userLoc;

    // Radius in meters for the map preview
    final double radiusInMeters = _selectedUnit == 'mi'
        ? _radiusValue * 1609.344
        : _radiusValue * 1000.0;

    final previewEvent = EventModel(
      id: 'tag_geo_preview',
      title: _tagNameController.text.isNotEmpty ? _tagNameController.text : 'New Event Tag',
      description: '',
      category: _selectedCategory,
      scope: _selectedScope,
      riskLevel: RiskLevel.high,
      status: EventStatus.active,
      city: activeAnchor.label ?? 'Selected Location',
      country: 'Live',
      center: activeAnchor,
      radiusMeters: radiusInMeters,
      radiusUnit: _selectedUnit,
      bannerImageUrl: '',
      startTime: DateTime.now(),
      activeContributors: 1,
      totalPosts: 0,
      totalVideos: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Event Tag',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // STEP 1: Select Location using Google Places API
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 24,
              borderColor: _selectedLocation != null ? AppColors.primaryNavy : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.place_rounded, color: Color(0xFFEA4335), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Step 1: Event Location',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_rounded, size: 12, color: Color(0xFF1D4ED8)),
                            SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Search any city, landmark, or venue. The radius measurement will be centered here.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Search input field
                  TextField(
                    controller: _locationSearchController,
                    onChanged: _onLocationQueryChanged,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryNavy, size: 20),
                      suffixIcon: _isSearchingPlaces
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy),
                              ),
                            )
                          : (_locationSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _locationSearchController.clear();
                                    setState(() {
                                      _selectedLocation = null;
                                      _placeSuggestions = [];
                                    });
                                  },
                                )
                              : null),
                      hintText: 'Search place (e.g. Times Square, Connaught Place)...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
                      ),
                    ),
                  ),

                  // Autocomplete Suggestions Dropdown
                  if (_placeSuggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _placeSuggestions.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final suggestion = _placeSuggestions[index];
                          return ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF2563EB)),
                            ),
                            title: Text(
                              suggestion.mainText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: suggestion.secondaryText.isNotEmpty
                                ? Text(
                                    suggestion.secondaryText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  )
                                : null,
                            onTap: () => _selectPlace(suggestion),
                          );
                        },
                      ),
                    ),
                  ],

                  // Selected Place Confirmation Badge
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: _selectedLocation != null
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedLocation != null
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedLocation != null ? Icons.check_circle_rounded : Icons.my_location_rounded,
                          size: 16,
                          color: _selectedLocation != null ? const Color(0xFF16A34A) : AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedLocation != null
                                ? 'Anchored to: ${_selectedLocation!.label} (${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)})'
                                : 'Default: Current GPS Location (${userLoc.label ?? 'Live Coordinates'})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _selectedLocation != null ? FontWeight.w800 : FontWeight.w500,
                              color: _selectedLocation != null ? const Color(0xFF15803D) : AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedLocation != null)
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedLocation = null;
                                _locationSearchController.clear();
                              });
                            },
                            child: const Text(
                              'Reset to GPS',
                              style: TextStyle(fontSize: 11, color: AppColors.primaryNavy, fontWeight: FontWeight.w800),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 2: Tag Identity & Category
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tag_rounded, color: AppColors.primaryNavy, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Tag & Event Identity',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tag Name Field
                  const Text(
                    'EVENT / TAG NAME',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _tagNameController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      prefixText: '# ',
                      prefixStyle: const TextStyle(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      hintText: 'e.g. FarmersProtest, FloodRescue, ClimateStrike',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Selection
                  const Text(
                    'EVENT CATEGORY',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EventCategory.values.map((cat) {
                      final isSelected = cat == _selectedCategory;
                      return ChoiceChip(
                        label: Text(cat.label),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                        selectedColor: AppColors.primaryNavy,
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryNavy : const Color(0xFFE2E8F0),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  const Text(
                    'DESCRIPTION & CONTEXT',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Describe what is happening on the ground and what eyewitnesses should report...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primaryNavy),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 3: Event Scope & Dynamic Range Slider
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune_rounded, color: AppColors.primaryNavy, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Geofence Radius',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      // Unit Switcher (km vs mi)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildUnitOption('km', 'Kilometers'),
                            _buildUnitOption('mi', 'Miles'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Scope Selection Tabs
                  const Text(
                    'SELECT EVENT TYPE',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: EventScope.values.map((scope) {
                      final isSelected = scope == _selectedScope;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () => _onScopeChanged(scope),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryNavy.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryNavy : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    scope == EventScope.cityWide
                                        ? Icons.location_city_rounded
                                        : (scope == EventScope.stateWide
                                            ? Icons.map_rounded
                                            : Icons.public_rounded),
                                    size: 20,
                                    color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    scope.label,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.primaryNavy : AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedUnit == 'km'
                                        ? '${scope.minKm.toInt()}-${scope.maxKm.toInt()} km'
                                        : '${scope.minMi.toInt()}-${scope.maxMi.toInt()} mi',
                                    style: TextStyle(
                                      color: isSelected ? AppColors.primaryNavy : AppColors.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedScope.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Dynamic Range Slider Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ALLOWED POSTING RADIUS',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Only users inside this boundary can post & verify news',
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryNavy,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_radiusValue.toStringAsFixed(_radiusValue < 10 ? 1 : 0)} $_selectedUnit',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Interactive Range Slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 6,
                            activeTrackColor: AppColors.primaryNavy,
                            inactiveTrackColor: const Color(0xFFCBD5E1),
                            thumbColor: AppColors.primaryNavy,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                            overlayColor: AppColors.primaryNavy.withValues(alpha: 0.15),
                          ),
                          child: Slider(
                            value: _radiusValue.clamp(_minRadius, _maxRadius),
                            min: _minRadius,
                            max: _maxRadius,
                            onChanged: (val) {
                              setState(() => _radiusValue = val);
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Min: ${_minRadius.toStringAsFixed(1)} $_selectedUnit',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Scope: ${_selectedScope.label}',
                              style: const TextStyle(color: AppColors.primaryNavy, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Max: ${_maxRadius.toStringAsFixed(0)} $_selectedUnit',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 4: Live Radar Map Geofence Preview
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.radar_rounded, color: AppColors.primaryNavy, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Geofence Boundary Map',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _selectedLocation != null ? const Color(0xFFEFF6FF) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _selectedLocation != null ? const Color(0xFF2563EB) : const Color(0xFF15803D),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedLocation != null ? 'GOOGLE PLACE ANCHOR' : 'GPS ANCHOR',
                              style: TextStyle(
                                color: _selectedLocation != null ? const Color(0xFF1D4ED8) : const Color(0xFF15803D),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anchored to: ${activeAnchor.label ?? 'Current Location'} (${activeAnchor.latitude.toStringAsFixed(4)}, ${activeAnchor.longitude.toStringAsFixed(4)})',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  // Embedded Map View with Radar Circle
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        TacticalRadarMap(
                          event: previewEvent,
                          userLocation: userLoc,
                          customCenter: activeAnchor,
                          height: 250,
                          isInteractive: true,
                          onLocationSelected: (newPoint) {
                            setState(() {
                              _selectedLocation = newPoint;
                              _locationSearchController.text =
                                  '${newPoint.latitude.toStringAsFixed(4)}, ${newPoint.longitude.toStringAsFixed(4)}';
                            });
                          },
                        ),
                        // Overlay Indicator
                        Positioned(
                          top: 10,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, size: 8, color: Color(0xFF22C55E)),
                                const SizedBox(width: 6),
                                Text(
                                  'Radius: ${_radiusValue.toStringAsFixed(1)} $_selectedUnit (${GeofenceMath.formatDistance(radiusInMeters)})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isCreating ? null : _submitTag,
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_location_alt_rounded, size: 19),
                          const SizedBox(width: 8),
                          Text(
                            'Activate Tag "${_tagNameController.text.isNotEmpty ? (_tagNameController.text.startsWith('#') ? _tagNameController.text : '#${_tagNameController.text}') : '#NewTag'}"',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitOption(String unit, String tooltip) {
    final isSelected = _selectedUnit == unit;
    return InkWell(
      onTap: () => _onUnitChanged(unit),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          unit.toUpperCase(),
          style: TextStyle(
            color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
