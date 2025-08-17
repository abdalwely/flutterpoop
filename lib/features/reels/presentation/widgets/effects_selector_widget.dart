import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class EffectsSelectorWidget extends StatefulWidget {
  final List<Effect> selectedEffects;
  final Function(List<Effect>) onEffectsChanged;

  const EffectsSelectorWidget({
    super.key,
    required this.selectedEffects,
    required this.onEffectsChanged,
  });

  @override
  State<EffectsSelectorWidget> createState() => _EffectsSelectorWidgetState();
}

class _EffectsSelectorWidgetState extends State<EffectsSelectorWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Effect> _selectedEffects = [];

  final List<Effect> _faceEffects = [
    Effect(
      id: 'beauty',
      name: 'تجميل',
      category: 'face',
      icon: Icons.face_retouching_natural,
      parameters: {'intensity': 0.5},
    ),
    Effect(
      id: 'smooth',
      name: 'نعومة',
      category: 'face',
      icon: Icons.auto_fix_high,
      parameters: {'intensity': 0.3},
    ),
    Effect(
      id: 'whitening',
      name: 'تبييض',
      category: 'face',
      icon: Icons.brightness_high,
      parameters: {'intensity': 0.2},
    ),
  ];

  final List<Effect> _filterEffects = [
    Effect(
      id: 'vintage',
      name: 'كلاسيكي',
      category: 'filter',
      icon: Icons.camera_alt,
      parameters: {'intensity': 0.7},
    ),
    Effect(
      id: 'warm',
      name: 'دافئ',
      category: 'filter',
      icon: Icons.wb_sunny,
      parameters: {'temperature': 0.3},
    ),
    Effect(
      id: 'cool',
      name: 'بارد',
      category: 'filter',
      icon: Icons.ac_unit,
      parameters: {'temperature': -0.3},
    ),
    Effect(
      id: 'dramatic',
      name: 'دراماتيكي',
      category: 'filter',
      icon: Icons.contrast,
      parameters: {'contrast': 0.5},
    ),
  ];

  final List<Effect> _arEffects = [
    Effect(
      id: 'glasses',
      name: 'نظارات',
      category: 'ar',
      icon: Icons.visibility,
      parameters: {},
    ),
    Effect(
      id: 'hat',
      name: 'قبعة',
      category: 'ar',
      icon: Icons.sports_baseball,
      parameters: {},
    ),
    Effect(
      id: 'mustache',
      name: 'شارب',
      category: 'ar',
      icon: Icons.face,
      parameters: {},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedEffects = List.from(widget.selectedEffects);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
            'التأثيرات',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
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
              Tab(text: 'تجميل الوجه'),
              Tab(text: 'فلاتر'),
              Tab(text: 'الواقع المعزز'),
            ],
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEffectsGrid(_faceEffects),
                _buildEffectsGrid(_filterEffects),
                _buildEffectsGrid(_arEffects),
              ],
            ),
          ),
          
          // Selected effects
          if (_selectedEffects.isNotEmpty) _buildSelectedEffects(),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildEffectsGrid(List<Effect> effects) {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.8,
      ),
      itemCount: effects.length + 1, // +1 for "no effect" option
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildNoEffectOption();
        }
        
        final effect = effects[index - 1];
        final isSelected = _selectedEffects.any((e) => e.id == effect.id);
        
        return _buildEffectItem(effect, isSelected);
      },
    );
  }

  Widget _buildNoEffectOption() {
    final isSelected = _selectedEffects.isEmpty;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedEffects.clear());
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 32.sp,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(height: 8.h),
            Text(
              'بدون تأثير',
              style: TextStyle(
                fontSize: 12.sp,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectItem(Effect effect, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleEffect(effect),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              effect.icon,
              size: 32.sp,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(height: 8.h),
            Text(
              effect.name,
              style: TextStyle(
                fontSize: 12.sp,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            
            // Intensity slider for selected effects
            if (isSelected && effect.parameters.containsKey('intensity'))
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: _buildIntensitySlider(effect),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensitySlider(Effect effect) {
    final intensity = effect.parameters['intensity'] ?? 0.5;
    
    return SizedBox(
      width: 60.w,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2.h,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
        ),
        child: Slider(
          value: intensity,
          onChanged: (value) {
            setState(() {
              final index = _selectedEffects.indexWhere((e) => e.id == effect.id);
              if (index != -1) {
                _selectedEffects[index].parameters['intensity'] = value;
              }
            });
          },
          activeColor: AppColors.primary,
          inactiveColor: AppColors.border,
        ),
      ),
    );
  }

  Widget _buildSelectedEffects() {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Text(
            'التأثيرات المحددة:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedEffects.length,
              itemBuilder: (context, index) {
                final effect = _selectedEffects[index];
                return Container(
                  margin: EdgeInsets.only(left: 8.w),
                  child: Chip(
                    label: Text(
                      effect.name,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    deleteIcon: Icon(Icons.close, size: 16.sp),
                    onDeleted: () => _removeEffect(effect),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    deleteIconColor: AppColors.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
              onPressed: _confirmSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'تطبيق',
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

  void _toggleEffect(Effect effect) {
    setState(() {
      final existingIndex = _selectedEffects.indexWhere((e) => e.id == effect.id);
      if (existingIndex != -1) {
        _selectedEffects.removeAt(existingIndex);
      } else {
        _selectedEffects.add(Effect(
          id: effect.id,
          name: effect.name,
          category: effect.category,
          icon: effect.icon,
          parameters: Map.from(effect.parameters),
        ));
      }
    });
  }

  void _removeEffect(Effect effect) {
    setState(() {
      _selectedEffects.removeWhere((e) => e.id == effect.id);
    });
  }

  void _confirmSelection() {
    widget.onEffectsChanged(_selectedEffects);
    Navigator.pop(context);
  }
}

class Effect {
  final String id;
  final String name;
  final String category;
  final IconData icon;
  final Map<String, dynamic> parameters;

  Effect({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.parameters,
  });
}
