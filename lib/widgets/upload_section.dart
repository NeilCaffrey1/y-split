import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class UploadSection extends StatefulWidget {
  final Function(Uint8List, String) onImageUploaded;
  final VoidCallback onManualEntry;

  const UploadSection({
    super.key,
    required this.onImageUploaded,
    required this.onManualEntry,
  });

  @override
  State<UploadSection> createState() => _UploadSectionState();
}

class _UploadSectionState extends State<UploadSection>
    with SingleTickerProviderStateMixin {
  bool _isDragOver = false;
  bool _isProcessing = false;
  Uint8List? _uploadedImageBytes;
  String? _uploadedFileName;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Drop zone with drag and drop support
          GestureDetector(
            onTap: _pickFile,
            child: MouseRegion(
              onEnter: (_) {
                setState(() => _isDragOver = true);
                _pulseController.repeat(reverse: true);
              },
              onExit: (_) {
                setState(() => _isDragOver = false);
                _pulseController.stop();
                _pulseController.reset();
              },
              child: DragTarget<String>(
                onWillAcceptWithDetails: (details) => true,
                onAcceptWithDetails: (details) => _handleDrop(),
                builder: (context, candidateData, rejectedData) {
                  final isActive = _isDragOver || candidateData.isNotEmpty;

                  return AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isActive ? _pulseAnimation.value : 1.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: _uploadedImageBytes != null ? 200 : 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isActive ? Colors.blue : Colors.grey[300]!,
                              width: isActive ? 3 : 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isActive ? Colors.blue[50] : Colors.grey[50],
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: _buildDropZoneContent(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Center(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _processImage,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isProcessing ? 'Processing...' : 'Extract Items'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropZoneContent() {
    if (_uploadedImageBytes != null) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _uploadedImageBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _uploadedFileName ?? 'Receipt image',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to change image',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        },
      );
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: _isDragOver ? Colors.blue[400] : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 18,
                    color: _isDragOver ? Colors.blue[700] : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  child: const Text('Drop receipt here'),
                ),
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 14,
                    color: _isDragOver ? Colors.blue[600] : Colors.grey[500],
                  ),
                  child: const Text('or tap to select file'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          // Validate file
          if (!_validateImageFile(file)) {
            return;
          }

          setState(() {
            _uploadedImageBytes = file.bytes;
            _uploadedFileName = file.name;
          });

          // Show success feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image uploaded: ${file.name}'),
                backgroundColor: Colors.green[600],
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  bool _validateImageFile(PlatformFile file) {
    // Check file size (max 10MB)
    const maxSizeBytes = 10 * 1024 * 1024;
    if (file.size > maxSizeBytes) {
      _showError('File too large. Please select an image under 10MB.');
      return false;
    }

    // Check file extension
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    final extension = file.extension?.toLowerCase();
    if (extension == null || !allowedExtensions.contains(extension)) {
      _showError('Invalid file type. Please select a valid image file.');
      return false;
    }

    return true;
  }

  void _handleDrop() {
    // For web drag-and-drop, we would need to use HTML5 drag and drop APIs
    // For now, we'll just trigger the file picker as a fallback
    _pickFile();
  }

  Future<void> _processImage() async {
    if (_uploadedImageBytes == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await widget.onImageUploaded(
        _uploadedImageBytes!,
        _uploadedFileName ?? 'receipt.jpg',
      );
    } catch (e) {
      _showError('Failed to process image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
