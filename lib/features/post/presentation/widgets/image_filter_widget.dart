import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ImageFilterWidget extends StatelessWidget {
  final String filter;
  final double brightness;
  final double contrast;
  final double saturation;
  final double vignette;
  final Widget? child;

  const ImageFilterWidget({
    super.key,
    this.filter = 'original',
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.vignette = 0.0,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: _getImageFilter(),
        child: child ?? Container(
          decoration: BoxDecoration(
            gradient: vignette > 0 ? _getVignetteGradient() : null,
          ),
        ),
      ),
    );
  }

  ui.ImageFilter _getImageFilter() {
    // Start with the base filter
    ui.ImageFilter filter = _getPresetFilter();
    
    // Apply manual adjustments
    if (brightness != 0.0 || contrast != 0.0 || saturation != 0.0) {
      final colorMatrix = _createColorMatrix();
      filter = ui.ImageFilter.matrix(colorMatrix, filterQuality: FilterQuality.high);
    }
    
    return filter;
  }

  ui.ImageFilter _getPresetFilter() {
    switch (filter) {
      case 'vintage':
        return ui.ImageFilter.matrix(_vintageMatrix(), filterQuality: FilterQuality.high);
      case 'black_white':
        return ui.ImageFilter.matrix(_blackWhiteMatrix(), filterQuality: FilterQuality.high);
      case 'sepia':
        return ui.ImageFilter.matrix(_sepiaMatrix(), filterQuality: FilterQuality.high);
      case 'bright':
        return ui.ImageFilter.matrix(_brightMatrix(), filterQuality: FilterQuality.high);
      case 'contrast':
        return ui.ImageFilter.matrix(_contrastMatrix(), filterQuality: FilterQuality.high);
      default:
        return ui.ImageFilter.matrix(Float64List.fromList([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]), filterQuality: FilterQuality.high);
    }
  }

  Float64List _createColorMatrix() {
    // Normalize values
    final b = brightness / 100.0;
    final c = (contrast + 100) / 100.0;
    final s = (saturation + 100) / 100.0;
    
    // Create color matrix
    final lumR = 0.2126;
    final lumG = 0.7152;
    final lumB = 0.0722;
    
    return Float64List.fromList([
      // Red channel
      (lumR * (1 - s) + s) * c, lumG * (1 - s) * c, lumB * (1 - s) * c, 0, b,
      // Green channel
      lumR * (1 - s) * c, (lumG * (1 - s) + s) * c, lumB * (1 - s) * c, 0, b,
      // Blue channel
      lumR * (1 - s) * c, lumG * (1 - s) * c, (lumB * (1 - s) + s) * c, 0, b,
      // Alpha channel
      0, 0, 0, 1, 0,
    ]);
  }

  Float64List _vintageMatrix() {
    return Float64List.fromList([
      0.6, 0.5, 0.4, 0, 0,
      0.3, 0.8, 0.3, 0, 0,
      0.2, 0.3, 0.5, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }

  Float64List _blackWhiteMatrix() {
    return Float64List.fromList([
      0.299, 0.587, 0.114, 0, 0,
      0.299, 0.587, 0.114, 0, 0,
      0.299, 0.587, 0.114, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }

  Float64List _sepiaMatrix() {
    return Float64List.fromList([
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }

  Float64List _brightMatrix() {
    return Float64List.fromList([
      1.2, 0, 0, 0, 20,
      0, 1.2, 0, 0, 20,
      0, 0, 1.2, 0, 20,
      0, 0, 0, 1, 0,
    ]);
  }

  Float64List _contrastMatrix() {
    const contrast = 1.5;
    const offset = 128 * (1 - contrast);
    
    return Float64List.fromList([
      contrast, 0, 0, 0, offset,
      0, contrast, 0, 0, offset,
      0, 0, contrast, 0, offset,
      0, 0, 0, 1, 0,
    ]);
  }

  RadialGradient _getVignetteGradient() {
    final opacity = vignette / 100.0;
    return RadialGradient(
      radius: 1.2,
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(opacity * 0.3),
        Colors.black.withOpacity(opacity * 0.8),
      ],
      stops: const [0.0, 0.7, 1.0],
    );
  }
}

class FilterPreview extends StatelessWidget {
  final String filter;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterPreview({
    super.key,
    required this.filter,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              ImageFilterWidget(filter: filter),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const FilterSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: Colors.blue,
          inactiveColor: Colors.grey[300],
        ),
      ],
    );
  }
}

class AdvancedImageEditor extends StatefulWidget {
  final String imageUrl;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const AdvancedImageEditor({
    super.key,
    required this.imageUrl,
    required this.onFiltersChanged,
  });

  @override
  State<AdvancedImageEditor> createState() => _AdvancedImageEditorState();
}

class _AdvancedImageEditorState extends State<AdvancedImageEditor> {
  String _selectedFilter = 'original';
  double _brightness = 0.0;
  double _contrast = 0.0;
  double _saturation = 0.0;
  double _vignette = 0.0;
  double _blur = 0.0;
  double _sharpness = 0.0;

  final List<Map<String, String>> _filters = [
    {'id': 'original', 'name': 'الأصلي'},
    {'id': 'vintage', 'name': 'قديم'},
    {'id': 'black_white', 'name': 'أبيض وأسود'},
    {'id': 'sepia', 'name': 'بني'},
    {'id': 'bright', 'name': 'ساطع'},
    {'id': 'contrast', 'name': 'تباين عالي'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Preview
        Container(
          height: 200,
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(widget.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: ImageFilterWidget(
            filter: _selectedFilter,
            brightness: _brightness,
            contrast: _contrast,
            saturation: _saturation,
            vignette: _vignette,
          ),
        ),
        
        // Filter presets
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              return FilterPreview(
                filter: filter['id']!,
                imageUrl: widget.imageUrl,
                isSelected: _selectedFilter == filter['id'],
                onTap: () {
                  setState(() {
                    _selectedFilter = filter['id']!;
                  });
                  _notifyChanges();
                },
              );
            },
          ),
        ),
        
        // Manual adjustments
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FilterSlider(
                  label: 'السطوع',
                  value: _brightness,
                  min: -100,
                  max: 100,
                  onChanged: (value) {
                    setState(() => _brightness = value);
                    _notifyChanges();
                  },
                ),
                FilterSlider(
                  label: 'التباين',
                  value: _contrast,
                  min: -100,
                  max: 100,
                  onChanged: (value) {
                    setState(() => _contrast = value);
                    _notifyChanges();
                  },
                ),
                FilterSlider(
                  label: 'التشبع',
                  value: _saturation,
                  min: -100,
                  max: 100,
                  onChanged: (value) {
                    setState(() => _saturation = value);
                    _notifyChanges();
                  },
                ),
                FilterSlider(
                  label: 'التظليل',
                  value: _vignette,
                  min: 0,
                  max: 100,
                  onChanged: (value) {
                    setState(() => _vignette = value);
                    _notifyChanges();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _notifyChanges() {
    widget.onFiltersChanged({
      'filter': _selectedFilter,
      'brightness': _brightness,
      'contrast': _contrast,
      'saturation': _saturation,
      'vignette': _vignette,
      'blur': _blur,
      'sharpness': _sharpness,
    });
  }
}
