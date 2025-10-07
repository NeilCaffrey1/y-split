import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/ocr_review_models.dart';

/// A zoomable and pannable image viewer for receipt images in the OCR review dialog
class ImageViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final List<DetectedRegion>? highlightedRegions;
  final VoidCallback? onImageTap;
  final String? errorMessage;

  const ImageViewer({
    super.key,
    required this.imageBytes,
    this.highlightedRegions,
    this.onImageTap,
    this.errorMessage,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  final TransformationController _transformationController =
      TransformationController();

  // Zoom constraints
  static const double _minScale = 0.5;
  static const double _maxScale = 4.0;

  // Image state
  bool _imageLoaded = false;
  bool _imageError = false;
  Size? _imageSize;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildImageContent()),
        ],
      ),
    );
  }

  /// Build toolbar with zoom controls and reset button
  Widget _buildToolbar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          const Icon(Icons.image, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Receipt Image',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          _buildZoomControls(),
        ],
      ),
    );
  }

  /// Build zoom control buttons
  Widget _buildZoomControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _zoomOut,
          icon: const Icon(Icons.zoom_out),
          tooltip: 'Zoom Out',
          iconSize: 20,
        ),
        IconButton(
          onPressed: _resetZoom,
          icon: const Icon(Icons.fit_screen),
          tooltip: 'Fit to Screen',
          iconSize: 20,
        ),
        IconButton(
          onPressed: _zoomIn,
          icon: const Icon(Icons.zoom_in),
          tooltip: 'Zoom In',
          iconSize: 20,
        ),
      ],
    );
  }

  /// Build the main image content area
  Widget _buildImageContent() {
    if (widget.errorMessage != null || _imageError) {
      return _buildErrorState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: _minScale,
          maxScale: _platformMaxScale,
          constrained: false,
          boundaryMargin: _platformBoundaryMargin,
          onInteractionStart: (_) => _onInteractionStart(),
          onInteractionEnd: (_) => _onInteractionEnd(),
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            alignment: Alignment.center,
            child: _buildImageWithOverlays(constraints),
          ),
        );
      },
    );
  }

  /// Build image with optional region overlays
  Widget _buildImageWithOverlays(BoxConstraints constraints) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main image
        Image.memory(
          widget.imageBytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _imageError = true;
                });
              }
            });
            return const SizedBox.shrink();
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame != null && !_imageLoaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _imageLoaded = true;
                  });
                  _calculateImageSize(child, constraints);
                }
              });
            }

            return child;
          },
        ),

        // Region overlays (if provided and image is loaded)
        if (widget.highlightedRegions != null &&
            _imageLoaded &&
            _imageSize != null)
          ..._buildRegionOverlays(),
      ],
    );
  }

  /// Build overlay widgets for detected regions
  List<Widget> _buildRegionOverlays() {
    if (widget.highlightedRegions == null || _imageSize == null) {
      return [];
    }

    return widget.highlightedRegions!.map((region) {
      return Positioned(
        left: region.boundingBox.left,
        top: region.boundingBox.top,
        width: region.boundingBox.width,
        height: region.boundingBox.height,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: region.highlightColor, width: 2),
            color: region.highlightColor.withValues(alpha: 0.1),
          ),
          child: Tooltip(
            message: '${region.category.toUpperCase()}: ${region.text}',
            child: const SizedBox.expand(),
          ),
        ),
      );
    }).toList();
  }

  /// Build error state widget
  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              widget.errorMessage ?? 'Failed to load image',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please try uploading the image again.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // Zoom control methods

  void _zoomIn() {
    final Matrix4 matrix = _transformationController.value.clone();
    const double scaleFactor = 1.2;

    // Get current scale
    final double currentScale = matrix.getMaxScaleOnAxis();
    final double newScale = (currentScale * scaleFactor).clamp(
      _minScale,
      _platformMaxScale,
    );

    if (newScale != currentScale) {
      final double scaleChange = newScale / currentScale;
      final Matrix4 scaleMatrix = Matrix4.diagonal3Values(
        scaleChange,
        scaleChange,
        1.0,
      );
      _transformationController.value = matrix * scaleMatrix;
    }
  }

  void _zoomOut() {
    final Matrix4 matrix = _transformationController.value.clone();
    const double scaleFactor = 0.8;

    // Get current scale
    final double currentScale = matrix.getMaxScaleOnAxis();
    final double newScale = (currentScale * scaleFactor).clamp(
      _minScale,
      _platformMaxScale,
    );

    if (newScale != currentScale) {
      final double scaleChange = newScale / currentScale;
      final Matrix4 scaleMatrix = Matrix4.diagonal3Values(
        scaleChange,
        scaleChange,
        1.0,
      );
      _transformationController.value = matrix * scaleMatrix;
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  // Interaction handlers

  void _onInteractionStart() {
    // Provide haptic feedback on mobile
    // HapticFeedback.selectionClick();
  }

  void _onInteractionEnd() {
    // Could add snap-to-bounds logic here if needed
  }

  void _calculateImageSize(Widget imageWidget, BoxConstraints constraints) {
    // This is a simplified calculation - in a real implementation,
    // you might want to get the actual image dimensions
    _imageSize = Size(constraints.maxWidth, constraints.maxHeight);
  }

  // Mobile-optimized helper methods

  /// Check if the current platform is mobile
  bool get _isMobile {
    return Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android;
  }

  /// Get appropriate boundary margin for the platform
  EdgeInsets get _platformBoundaryMargin {
    return _isMobile
        ? const EdgeInsets.all(10) // Smaller margin on mobile
        : const EdgeInsets.all(20); // Larger margin on desktop
  }

  /// Get appropriate zoom constraints for the platform
  double get _platformMaxScale {
    return _isMobile ? 3.0 : _maxScale; // Slightly less zoom on mobile
  }
}

// Mobile-optimized helper methods moved into the main state class
