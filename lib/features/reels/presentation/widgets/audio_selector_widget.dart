import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class AudioSelectorWidget extends StatefulWidget {
  final String? selectedAudio;
  final Function(String?) onAudioSelected;

  const AudioSelectorWidget({
    super.key,
    required this.selectedAudio,
    required this.onAudioSelected,
  });

  @override
  State<AudioSelectorWidget> createState() => _AudioSelectorWidgetState();
}

class _AudioSelectorWidgetState extends State<AudioSelectorWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String? _selectedAudio;

  final List<AudioTrack> _trendingTracks = [
    AudioTrack(
      id: '1',
      title: 'أغنية شعبية',
      artist: 'فنان مشهور',
      duration: 30,
      isOriginal: false,
    ),
    AudioTrack(
      id: '2',
      title: 'موسيقى هادئة',
      artist: 'مؤلف موسيقي',
      duration: 45,
      isOriginal: false,
    ),
    AudioTrack(
      id: '3',
      title: 'أغنية حماسية',
      artist: 'مطرب شاب',
      duration: 60,
      isOriginal: false,
    ),
  ];

  final List<AudioTrack> _favoriteTracks = [
    AudioTrack(
      id: '4',
      title: 'أغنية مفضلة 1',
      artist: 'فنان مفضل',
      duration: 30,
      isOriginal: false,
    ),
    AudioTrack(
      id: '5',
      title: 'أغنية مفضلة 2',
      artist: 'فنان آخر',
      duration: 35,
      isOriginal: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedAudio = widget.selectedAudio;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(top: 12.h),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          
          // Title
          Text(
            'اختيار الصوت',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 16.h),
          
          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن الأصوات والموسيقى',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          SizedBox(height: 16.h),
          
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
            tabs: const [
              Tab(text: 'الأصوات الأصلية'),
              Tab(text: 'الأصوات الشائعة'),
              Tab(text: 'المفضلة'),
            ],
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOriginalSoundsTab(),
                _buildTrendingTab(),
                _buildFavoritesTab(),
              ],
            ),
          ),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildOriginalSoundsTab() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Record original sound
          GestureDetector(
            onTap: _recordOriginalSound,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mic,
                      color: AppColors.white,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تسجيل صوت أصلي',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          'سجل صوتك الخاص للريل',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // No original sound option
          AudioTrackItem(
            track: AudioTrack(
              id: 'original',
              title: 'بدون موسيقى',
              artist: 'الصوت الأصلي',
              duration: 0,
              isOriginal: true,
            ),
            isSelected: _selectedAudio == 'original',
            onTap: () {
              setState(() => _selectedAudio = 'original');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingTab() {
    final filteredTracks = _searchQuery.isEmpty
        ? _trendingTracks
        : _trendingTracks.where((track) {
            return track.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   track.artist.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: filteredTracks.length,
      itemBuilder: (context, index) {
        final track = filteredTracks[index];
        return AudioTrackItem(
          track: track,
          isSelected: _selectedAudio == track.id,
          onTap: () {
            setState(() => _selectedAudio = track.id);
          },
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    if (_favoriteTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد أصوات مفضلة',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _favoriteTracks.length,
      itemBuilder: (context, index) {
        final track = _favoriteTracks[index];
        return AudioTrackItem(
          track: track,
          isSelected: _selectedAudio == track.id,
          onTap: () {
            setState(() => _selectedAudio = track.id);
          },
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _selectedAudio != null ? _confirmSelection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'تأكيد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _recordOriginalSound() {
    // Implementation for recording original sound
    Navigator.pop(context);
    // Show recording interface
  }

  void _confirmSelection() {
    widget.onAudioSelected(_selectedAudio);
    Navigator.pop(context);
  }
}

class AudioTrackItem extends StatelessWidget {
  final AudioTrack track;
  final bool isSelected;
  final VoidCallback onTap;

  const AudioTrackItem({
    super.key,
    required this.track,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Play button
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: track.isOriginal ? AppColors.inputBackground : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                track.isOriginal ? Icons.mic : Icons.play_arrow,
                color: track.isOriginal ? AppColors.textSecondary : AppColors.white,
                size: 20.sp,
              ),
            ),
            
            SizedBox(width: 12.w),
            
            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (track.duration > 0)
                    Text(
                      '${track.duration} ثانية',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                ],
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }
}

class AudioTrack {
  final String id;
  final String title;
  final String artist;
  final int duration; // in seconds
  final bool isOriginal;

  AudioTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.isOriginal,
  });
}
