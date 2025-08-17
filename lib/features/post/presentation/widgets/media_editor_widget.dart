import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class MediaEditorWidget extends StatefulWidget {
  final File imageFile;
  final Function(Map<String, dynamic>) onEdited;

  const MediaEditorWidget({
    super.key,
    required this.imageFile,
    required this.onEdited,
  });

  @override
  State<MediaEditorWidget> createState() => _MediaEditorWidgetState();
}

class _MediaEditorWidgetState extends State<MediaEditorWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Transform properties
  double _rotation = 0.0;
  double _scale = 1.0;
  Offset _translation = Offset.zero;
  
  // Crop properties
  Rect _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
  String _aspectRatio = 'free';
  
  // Drawing properties
  bool _isDrawing = false;
  Color _drawingColor = Colors.red;
  double _brushSize = 3.0;
  List<DrawingPath> _drawingPaths = [];
  
  // Text properties
  List<TextOverlay> _textOverlays = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close, color: AppColors.white),
        ),
        title: Text(
          'تحرير الصورة',
          style: TextStyle(
            color: AppColors.white,
            fontFamily: 'Cairo',
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: Text(
              'حفظ',
              style: TextStyle(
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview
          Expanded(
            flex: 3,
            child: _buildImagePreview(),
          ),
          
          // Tools tabs
          Container(
            color: AppColors.black,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.white.withOpacity(0.7),
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.transform), text: 'تحويل'),
                Tab(icon: Icon(Icons.crop), text: 'قص'),
                Tab(icon: Icon(Icons.brush), text: 'رسم'),
                Tab(icon: Icon(Icons.text_fields), text: 'نص'),
              ],
            ),
          ),
          
          // Tools content
          Container(
            height: 200.h,
            color: AppColors.black,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransformTab(),
                _buildCropTab(),
                _buildDrawingTab(),
                _buildTextTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      child: InteractiveViewer(
        boundaryMargin: EdgeInsets.all(20.w),
        minScale: 0.5,
        maxScale: 3.0,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(_translation.dx, _translation.dy)
            ..rotateZ(_rotation)
            ..scale(_scale),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: FileImage(widget.imageFile),
                fit: BoxFit.contain,
              ),
            ),
            child: CustomPaint(
              painter: OverlayPainter(
                drawingPaths: _drawingPaths,
                textOverlays: _textOverlays,
                cropRect: _cropRect,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransformTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          _buildSlider(
            'دوران',
            _rotation,
            -180,
            180,
            (value) => setState(() => _rotation = value * (3.14159 / 180)),
          ),
          _buildSlider(
            'تكبير',
            _scale,
            0.5,
            2.0,
            (value) => setState(() => _scale = value),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                'انعكاس أفقي',
                Icons.flip,
                () => setState(() => _scale = -_scale),
              ),
              _buildActionButton(
                'انعكاس عمودي',
                Icons.flip,
                () => setState(() => _rotation = -_rotation),
              ),
              _buildActionButton(
                'إعادة تعيين',
                Icons.refresh,
                () => setState(() {
                  _rotation = 0.0;
                  _scale = 1.0;
                  _translation = Offset.zero;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Text(
            'نسبة العرض للارتفاع',
            style: TextStyle(
              color: AppColors.white,
              fontFamily: 'Cairo',
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            children: [
              _buildAspectRatioButton('free', 'حر'),
              _buildAspectRatioButton('1:1', '1:1'),
              _buildAspectRatioButton('4:3', '4:3'),
              _buildAspectRatioButton('16:9', '16:9'),
              _buildAspectRatioButton('3:4', '3:4'),
              _buildAspectRatioButton('9:16', '9:16'),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                'إعادة تعيين',
                Icons.crop_free,
                () => setState(() => _cropRect = const Rect.fromLTWH(0, 0, 1, 1)),
              ),
              _buildActionButton(
                'تطبيق',
                Icons.check,
                _applyCrop,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Brush size
          _buildSlider(
            'حج�� الفرشاة',
            _brushSize,
            1.0,
            10.0,
            (value) => setState(() => _brushSize = value),
          ),
          
          SizedBox(height: 16.h),
          
          // Color palette
          Text(
            'اللون',
            style: TextStyle(
              color: AppColors.white,
              fontFamily: 'Cairo',
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            children: [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.yellow,
              Colors.purple,
              Colors.orange,
              Colors.pink,
              Colors.white,
              Colors.black,
            ].map((color) => _buildColorButton(color)).toList(),
          ),
          
          SizedBox(height: 16.h),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                'تراجع',
                Icons.undo,
                _undoDrawing,
              ),
              _buildActionButton(
                'محو الكل',
                Icons.clear,
                () => setState(() => _drawingPaths.clear()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          _buildActionButton(
            'إضافة نص',
            Icons.add_text,
            _addTextOverlay,
          ),
          SizedBox(height: 16.h),
          if (_textOverlays.isNotEmpty) ...[
            Text(
              'النصوص المضافة',
              style: TextStyle(
                color: AppColors.white,
                fontFamily: 'Cairo',
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 8.h),
            ..._textOverlays.asMap().entries.map((entry) {
              final index = entry.key;
              final textOverlay = entry.value;
              return ListTile(
                title: Text(
                  textOverlay.text,
                  style: TextStyle(color: AppColors.white),
                ),
                trailing: IconButton(
                  onPressed: () => _removeTextOverlay(index),
                  icon: Icon(Icons.delete, color: AppColors.white),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.white,
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                color: AppColors.white.withOpacity(0.7),
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.white.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return Column(
      children: [
        Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: AppColors.white),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 10.sp,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildAspectRatioButton(String ratio, String label) {
    final isSelected = _aspectRatio == ratio;
    return GestureDetector(
      onTap: () => setState(() => _aspectRatio = ratio),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.white,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _drawingColor == color;
    return GestureDetector(
      onTap: () => setState(() => _drawingColor = color),
      child: Container(
        width: 30.w,
        height: 30.h,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected 
              ? Border.all(color: AppColors.white, width: 2)
              : null,
        ),
      ),
    );
  }

  void _undoDrawing() {
    if (_drawingPaths.isNotEmpty) {
      setState(() => _drawingPaths.removeLast());
    }
  }

  void _applyCrop() {
    // Apply crop logic here
  }

  void _addTextOverlay() async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => _TextInputDialog(),
    );
    
    if (text != null && text.isNotEmpty) {
      setState(() {
        _textOverlays.add(TextOverlay(
          text: text,
          position: const Offset(0.5, 0.5),
          color: Colors.white,
          fontSize: 24,
        ));
      });
    }
  }

  void _removeTextOverlay(int index) {
    setState(() => _textOverlays.removeAt(index));
  }

  void _saveChanges() {
    final editData = {
      'rotation': _rotation,
      'scale': _scale,
      'translation': _translation,
      'cropRect': _cropRect,
      'drawingPaths': _drawingPaths,
      'textOverlays': _textOverlays,
    };
    
    widget.onEdited(editData);
    Navigator.pop(context);
  }
}

class _TextInputDialog extends StatefulWidget {
  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة نص'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'اكتب النص هنا...',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text('إضافة'),
        ),
      ],
    );
  }
}

class OverlayPainter extends CustomPainter {
  final List<DrawingPath> drawingPaths;
  final List<TextOverlay> textOverlays;
  final Rect cropRect;

  OverlayPainter({
    required this.drawingPaths,
    required this.textOverlays,
    required this.cropRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw paths
    for (final path in drawingPaths) {
      final paint = Paint()
        ..color = path.color
        ..strokeWidth = path.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      canvas.drawPath(path.path, paint);
    }

    // Draw text overlays
    for (final textOverlay in textOverlays) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: textOverlay.text,
          style: TextStyle(
            color: textOverlay.color,
            fontSize: textOverlay.fontSize,
          ),
        ),
        textDirection: TextDirection.rtl,
      );
      
      textPainter.layout();
      
      final offset = Offset(
        textOverlay.position.dx * size.width - textPainter.width / 2,
        textOverlay.position.dy * size.height - textPainter.height / 2,
      );
      
      textPainter.paint(canvas, offset);
    }

    // Draw crop overlay
    if (cropRect != const Rect.fromLTWH(0, 0, 1, 1)) {
      final paint = Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      
      // Draw dark overlay outside crop area
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, cropRect.top * size.height), paint);
      canvas.drawRect(Rect.fromLTWH(0, cropRect.bottom * size.height, size.width, size.height - cropRect.bottom * size.height), paint);
      canvas.drawRect(Rect.fromLTWH(0, cropRect.top * size.height, cropRect.left * size.width, (cropRect.bottom - cropRect.top) * size.height), paint);
      canvas.drawRect(Rect.fromLTWH(cropRect.right * size.width, cropRect.top * size.height, size.width - cropRect.right * size.width, (cropRect.bottom - cropRect.top) * size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawingPath {
  final Path path;
  final Color color;
  final double strokeWidth;

  DrawingPath({
    required this.path,
    required this.color,
    required this.strokeWidth,
  });
}

class TextOverlay {
  final String text;
  final Offset position;
  final Color color;
  final double fontSize;

  TextOverlay({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
  });
}
