import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/custom_icons.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class LocationPickerWidget extends StatefulWidget {
  const LocationPickerWidget({super.key});

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<LocationData> _searchResults = [];
  List<LocationData> _nearbyLocations = [];
  bool _isLoading = false;
  bool _isSearching = false;
  LocationData? _currentLocation;

  final List<LocationData> _popularLocations = [
    LocationData(
      name: 'مكة المكرمة',
      address: 'المملكة العربية السعودية',
      latitude: 21.4225,
      longitude: 39.8262,
      type: 'city',
    ),
    LocationData(
      name: 'المدينة المنورة',
      address: 'المملكة العربية السعودية',
      latitude: 24.4697,
      longitude: 39.6146,
      type: 'city',
    ),
    LocationData(
      name: 'الرياض',
      address: 'المملكة العربية السعودية',
      latitude: 24.7136,
      longitude: 46.6753,
      type: 'city',
    ),
    LocationData(
      name: 'جدة',
      address: 'المملكة العربية السعودي��',
      latitude: 21.5433,
      longitude: 39.1724,
      type: 'city',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _searchLocations(query);
    } else {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _currentLocation = LocationData(
          name: placemark.name ?? 'الموقع الحالي',
          address: _formatAddress(placemark),
          latitude: position.latitude,
          longitude: position.longitude,
          type: 'current',
        );
      }

      // Get nearby locations (simulate with some dummy data)
      _nearbyLocations = [
        if (_currentLocation != null) _currentLocation!,
        ..._generateNearbyLocations(position.latitude, position.longitude),
      ];
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatAddress(Placemark placemark) {
    final parts = <String>[];
    
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }
    
    return parts.join(', ');
  }

  List<LocationData> _generateNearbyLocations(double lat, double lng) {
    // In a real app, this would call a places API
    return [
      LocationData(
        name: 'مسجد قريب',
        address: 'على بعد 500 متر',
        latitude: lat + 0.005,
        longitude: lng + 0.005,
        type: 'mosque',
      ),
      LocationData(
        name: 'مطعم الذواقة',
        address: 'على بعد 1 كيلومتر',
        latitude: lat - 0.01,
        longitude: lng + 0.01,
        type: 'restaurant',
      ),
      LocationData(
        name: 'مول التسوق',
        address: 'على بعد 2 كيلومتر',
        latitude: lat + 0.02,
        longitude: lng - 0.01,
        type: 'mall',
      ),
    ];
  }

  Future<void> _searchLocations(String query) async {
    setState(() => _isSearching = true);
    
    try {
      // Simulate search delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // In a real app, this would call a places search API
      final results = <LocationData>[];
      
      // Filter popular locations
      for (final location in _popularLocations) {
        if (location.name.toLowerCase().contains(query.toLowerCase()) ||
            location.address.toLowerCase().contains(query.toLowerCase())) {
          results.add(location);
        }
      }
      
      // Add some mock search results
      if (query.length > 2) {
        results.addAll([
          LocationData(
            name: '$query - نتيجة البحث 1',
            address: 'عنوان تجريبي',
            latitude: 24.7136,
            longitude: 46.6753,
            type: 'search',
          ),
          LocationData(
            name: '$query - نتيجة البحث 2',
            address: 'عنوان تجريبي آخر',
            latitude: 24.7136,
            longitude: 46.6753,
            type: 'search',
          ),
        ]);
      }
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'اختيار الموقع',
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن موقع',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _isSearching = false;
                          });
                        },
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isNotEmpty) {
      return _buildSearchResults();
    }

    return _buildLocationsList();
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return _buildEmptySearchState();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final location = _searchResults[index];
        return LocationListItem(
          location: location,
          onTap: () => _selectLocation(location),
        );
      },
    );
  }

  Widget _buildLocationsList() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current location
          if (_currentLocation != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                'الموقع الحالي',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            LocationListItem(
              location: _currentLocation!,
              onTap: () => _selectLocation(_currentLocation!),
              isCurrentLocation: true,
            ),
            SizedBox(height: 16.h),
          ],

          // Nearby locations
          if (_nearbyLocations.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                'أماكن قريبة',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            ..._nearbyLocations.skip(1).map((location) => LocationListItem(
              location: location,
              onTap: () => _selectLocation(location),
            )),
            SizedBox(height: 16.h),
          ],

          // Popular locations
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Text(
              'أماكن مشهورة',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          ..._popularLocations.map((location) => LocationListItem(
            location: location,
            onTap: () => _selectLocation(location),
          )),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'جرب البحث بكلمات مختلفة',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  void _selectLocation(LocationData location) {
    Navigator.pop(context, location.name);
  }
}

class LocationListItem extends StatelessWidget {
  final LocationData location;
  final VoidCallback onTap;
  final bool isCurrentLocation;

  const LocationListItem({
    super.key,
    required this.location,
    required this.onTap,
    this.isCurrentLocation = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: isCurrentLocation 
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.inputBackground,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                _getLocationIcon(),
                color: isCurrentLocation ? AppColors.primary : AppColors.textSecondary,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  if (location.address.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      location.address,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLocationIcon() {
    switch (location.type) {
      case 'current':
        return Icons.my_location;
      case 'mosque':
        return Icons.mosque;
      case 'restaurant':
        return Icons.restaurant;
      case 'mall':
        return CustomIcons.shoppingMall;
      case 'city':
        return Icons.location_city;
      default:
        return Icons.place;
    }
  }
}

class LocationData {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String type;

  LocationData({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  @override
  String toString() {
    return 'LocationData(name: $name, address: $address, lat: $latitude, lng: $longitude)';
  }
}
