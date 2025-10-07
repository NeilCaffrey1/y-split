import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/receipt_item.dart';
import '../models/person.dart';
import '../models/assignment_matrix.dart';
import '../services/ocr_service.dart';
import '../services/data_management_service.dart';
import '../widgets/upload_section.dart';
import '../widgets/items_section.dart';
import '../widgets/people_section.dart';
import '../widgets/totals_section.dart';
import '../widgets/ocr_review_dialog.dart';

class ReceiptSplitterPage extends StatefulWidget {
  const ReceiptSplitterPage({super.key});

  @override
  State<ReceiptSplitterPage> createState() => _ReceiptSplitterPageState();
}

class _ReceiptSplitterPageState extends State<ReceiptSplitterPage>
    with TickerProviderStateMixin {
  final AssignmentMatrix _matrix = AssignmentMatrix();
  final OCRService _ocrService = OCRService();
  final DataManagementService _dataService = DataManagementService();
  double _taxAmount = 0.0;
  double _serviceAmount = 0.0;
  double _deliveryAmount = 0.0;
  bool _isProcessingOCR = false;

  // Animation controllers for smooth transitions
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Performance optimization: cache expensive calculations
  Map<Person, double>? _cachedTotals;
  int _lastItemsHash = 0;
  int _lastPeopleHash = 0;
  double _lastFeesTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Fade animation for overall page
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    // Slide animation for sections
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
        );

    // Scale animation for interactive elements
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Start animations with staggered timing
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _cleanupServices();
    super.dispose();
  }

  /// Initialize privacy and data management services
  Future<void> _initializeServices() async {
    await _dataService.initialize();

    // Register data clearing callback
    _dataService.registerClearDataCallback(_clearAllAppData);

    // Verify privacy compliance in debug mode
    _dataService.verifyNoExternalCalls();
  }

  /// Cleanup services and clear data
  void _cleanupServices() {
    // Clear all application data before disposal
    _clearAllAppData();

    // Unregister callbacks and dispose services
    _dataService.unregisterClearDataCallback(_clearAllAppData);
    _dataService.dispose();
  }

  /// Clear all application data (privacy compliance)
  void _clearAllAppData() {
    // Clear all receipt items
    _matrix.items.clear();

    // Clear all people
    _matrix.people.clear();

    // Reset fee amounts
    _taxAmount = 0.0;
    _serviceAmount = 0.0;
    _deliveryAmount = 0.0;

    // Clear cached calculations
    _cachedTotals = null;
    _lastItemsHash = 0;
    _lastPeopleHash = 0;
    _lastFeesTotal = 0.0;

    // Clear OCR service data for privacy compliance
    _cleanupOCRData();
    
    // Note: No setState needed during disposal
  }

  /// Performance optimization: Get cached totals or calculate if needed
  Map<Person, double> _getOptimizedTotals() {
    final currentFeesTotal = _taxAmount + _serviceAmount + _deliveryAmount;
    final currentItemsHash = _matrix.items
        .map(
          (item) =>
              '${item.name}_${item.price}_${item.assignedPeople.join(',')}',
        )
        .join('|')
        .hashCode;
    final currentPeopleHash = _matrix.people
        .map((person) => '${person.name}_${person.color.toString()}')
        .join('|')
        .hashCode;

    // Check if we can use cached results
    if (_cachedTotals != null &&
        _lastItemsHash == currentItemsHash &&
        _lastPeopleHash == currentPeopleHash &&
        _lastFeesTotal == currentFeesTotal) {
      return _cachedTotals!;
    }

    // Calculate new totals and cache them
    final totals = _matrix.calculateTotalsWithTip(currentFeesTotal);
    _cachedTotals = totals;
    _lastItemsHash = currentItemsHash;
    _lastPeopleHash = currentPeopleHash;
    _lastFeesTotal = currentFeesTotal;

    return totals;
  }

  /// Performance optimization: Invalidate cache when data changes
  void _invalidateCache() {
    _cachedTotals = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            'Receipt Splitter',
            key: ValueKey(_matrix.items.length),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: IconButton(
              icon: const Icon(Icons.privacy_tip_outlined, color: Colors.green),
              tooltip: 'Privacy: All data stays local',
              onPressed: _showPrivacyInfo,
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: MasonryGridView(
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            gridDelegate: SliverSimpleGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 600,
            ),
            children: [
              _buildSection(
                title: 'Upload Receipts',
                child: _buildUploadSectionWithLoading(),
              ),
              _buildSection(
                title: 'Items',
                child: ItemsSection(
                  key: ValueKey('items_${_matrix.items.length}'),
                  items: _matrix.items,
                  onItemAdded: _handleItemAdded,
                  onItemUpdated: _handleItemUpdated,
                  onItemRemoved: _handleItemRemoved,
                ),
              ),
              _buildSection(
                title: 'People',
                child: PeopleSection(
                  key: ValueKey('people_${_matrix.people.length}'),
                  people: _matrix.people,
                  items: _matrix.items,
                  onPersonAdded: _handlePersonAdded,
                  onPersonRemoved: _handlePersonRemoved,
                  onAssignmentToggled: _handleAssignmentToggled,
                  onAssignToEveryone: _handleAssignToEveryone,
                  onAssignRemainingEqually: _handleAssignRemainingEqually,
                ),
              ),
              _buildSection(
                title: 'Totals',
                child: TotalsSection(
                  key: const ValueKey('totals_section'),
                  totals: _getOptimizedTotals(),
                  taxAmount: _taxAmount,
                  serviceAmount: _serviceAmount,
                  deliveryAmount: _deliveryAmount,
                  onFeesChanged: _handleFeesChanged,
                  onShare: _handleShare,
                ),
              ),
            ],
          ),
        ),
      ),
      // Add floating action button for quick actions when there are many items
      floatingActionButton: _matrix.items.length > 5
          ? ScaleTransition(
              scale: _scaleAnimation,
              child: FloatingActionButton.extended(
                onPressed: _scrollToTop,
                icon: const Icon(Icons.keyboard_arrow_up),
                label: const Text('Top'),
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            )
          : null,
    );
  }

  void _scrollToTop() {
    // This would scroll to top if we had a scroll controller
    // For now, we'll just show a helpful message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scroll to top'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildUploadSectionWithLoading() {
    return Stack(
      children: [
        UploadSection(
          onImageUploaded: _handleImageUpload,
          onManualEntry: _handleManualEntry,
        ),
        if (_isProcessingOCR)
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue[600]!,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.document_scanner,
                                size: 24,
                                color: Colors.blue[600],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Processing receipt...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Extracting items and prices',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          // Animated dots
                          _buildLoadingDots(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingDots() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animValue = ((value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = (sin(animValue * pi) * 0.5 + 0.5).clamp(0.3, 1.0);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.blue[600]!.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: (isDesktop ? 0.08 : 0.05) * value,
                    ),
                    blurRadius: (isDesktop ? 20 : 10) * value,
                    offset: Offset(0, 2 * value),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: EdgeInsets.all(isDesktop ? 20.0 : 16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isDesktop ? 16 : 12),
                        topRight: Radius.circular(isDesktop ? 16 : 12),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: isDesktop ? 20 : 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (_getSectionProgress(title) != null)
                          _buildProgressIndicator(_getSectionProgress(title)!),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Get progress for each section to show completion status
  double? _getSectionProgress(String title) {
    switch (title) {
      case 'Upload Receipt':
        return null; // No progress indicator needed
      case 'Items':
        return _matrix.items.isEmpty ? 0.0 : 1.0;
      case 'People':
        if (_matrix.people.isEmpty) return 0.0;
        if (_matrix.items.isEmpty) return 0.5;
        final assignedItems = _matrix.items
            .where((item) => item.assignedPeople.isNotEmpty)
            .length;
        return assignedItems / _matrix.items.length;
      case 'Totals':
        final totals = _getOptimizedTotals();
        final nonZeroTotals = totals.values
            .where((amount) => amount > 0)
            .length;
        return nonZeroTotals > 0 ? 1.0 : 0.0;
      default:
        return null;
    }
  }

  Widget _buildProgressIndicator(double progress) {
    return Container(
      width: 40,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: progress == 1.0 ? Colors.green : Colors.blue,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  // Event Handlers
  Future<void> _handleImageUpload(Uint8List imageBytes, String fileName) async {
    if (!mounted) return;

    setState(() {
      _isProcessingOCR = true;
    });

    try {
      // Show loading indicator with better styling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Processing receipt with OCR...'),
            ],
          ),
          backgroundColor: Colors.blue[600],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 30),
        ),
      );

      // Process image with OCR
      final extractedItems = await _ocrService.processReceiptImage(imageBytes);
      final extractedFees = _ocrService.lastExtractedFees;

      if (!mounted) return;

      // Hide loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      setState(() {
        _isProcessingOCR = false;
      });

      // Show OCR Review Dialog
      final shouldApply = await _showOCRReviewDialog(
        imageBytes,
        extractedItems,
        extractedFees,
      );

      if (shouldApply == true && mounted) {
        // Changes were applied through the dialog callback
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied ${extractedItems.length} items from receipt!'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessingOCR = false;
      });

      // Hide loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Handle OCR fallback gracefully
      if (e.toString().contains('OCRFallbackException')) {
        // Show helpful fallback message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not read receipt automatically. Add items manually below.',
            ),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Add Items',
              textColor: Colors.white,
              onPressed: _handleManualEntry,
            ),
          ),
        );
      } else {
        // Show error with fallback option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR failed: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Add Manually',
              textColor: Colors.white,
              onPressed: _handleManualEntry,
            ),
          ),
        );
      }
    }
  }

  /// Show OCR Review Dialog and handle results
  Future<bool?> _showOCRReviewDialog(
    Uint8List imageBytes,
    List<ReceiptItem> extractedItems,
    Map<String, double> extractedFees,
  ) async {
    // Extract unmapped numbers from OCR service
    final unmappedNumbers = _ocrService.lastUnmappedNumbers;
    
    // Extract detected total (placeholder - would come from OCR service)
    final detectedTotal = extractedFees['total'];

    try {
      // Show dialog with proper error handling for privacy compliance
      final result = await OCRReviewDialog.show(
        context,
        imageBytes: imageBytes,
        detectedItems: extractedItems,
        detectedFees: extractedFees,
        unmappedNumbers: unmappedNumbers,
        detectedTotal: detectedTotal,
        onApply: _handleOCRReviewApply,
      );

      // Ensure cleanup happens regardless of result (privacy requirement)
      _cleanupOCRData();
      
      return result;
    } catch (e) {
      // Handle any errors and ensure cleanup
      _cleanupOCRData();
      debugPrint('OCR Review Dialog error: $e');
      rethrow;
    }
  }

  /// Clean up OCR-related data for privacy compliance
  void _cleanupOCRData() {
    try {
      // Clear OCR service cache (local processing only)
      _ocrService.clearCache();
    } catch (e) {
      debugPrint('Error during OCR cleanup: $e');
    }
  }

  /// Handle apply changes from OCR review dialog
  void _handleOCRReviewApply(
    List<ReceiptItem> reviewedItems,
    Map<String, double> reviewedFees,
  ) {
    setState(() {
      // Clear existing items
      _matrix.items.clear();

      // Add reviewed items to the matrix
      for (final item in reviewedItems) {
        _matrix.addItem(item);
      }

      // Set fees from reviewed values
      _taxAmount = reviewedFees['tax'] ?? 0.0;
      _serviceAmount = reviewedFees['service'] ?? 0.0;
      _deliveryAmount = reviewedFees['delivery'] ?? 0.0;

      // Invalidate cache to force recalculation
      _invalidateCache();
    });
  }

  void _handleManualEntry() {
    debugPrint("MANUAL ENTRY");
    // // T O D O : Focus on manual item entry
    // setState(() {
    //   // Placeholder for manual entry mode
    // });
  }

  void _handleItemAdded(ReceiptItem item) {
    setState(() {
      _matrix.addItem(item);
      _invalidateCache();
    });
  }

  void _handleItemUpdated(int index, ReceiptItem updatedItem) {
    setState(() {
      if (index >= 0 && index < _matrix.items.length) {
        _matrix.items[index] = updatedItem;
        _invalidateCache();
      }
    });
  }

  void _handleItemRemoved(int index) {
    setState(() {
      _matrix.removeItem(index);
      _invalidateCache();
    });
  }

  void _handlePersonAdded(String name) {
    setState(() {
      final person = Person.withAutoColor(name, _matrix.people.length);
      _matrix.addPerson(person);
      _invalidateCache();
    });
  }

  void _handlePersonRemoved(int index) {
    setState(() {
      _matrix.removePerson(index);
      _invalidateCache();
    });
  }

  void _handleAssignmentToggled(int itemIndex, int personIndex) {
    setState(() {
      _matrix.toggleAssignment(itemIndex, personIndex);
      _invalidateCache();
    });
  }

  void _handleAssignToEveryone(int itemIndex) {
    setState(() {
      _matrix.assignItemToEveryone(itemIndex);
      _invalidateCache();
    });
  }

  void _handleAssignRemainingEqually() {
    setState(() {
      _matrix.assignRemainingItemsEqually();
      _invalidateCache();
    });
  }

  void _handleFeesChanged(double tax, double service, double delivery) {
    setState(() {
      _taxAmount = tax;
      _serviceAmount = service;
      _deliveryAmount = delivery;
      _invalidateCache();
    });
  }

  /// Show privacy information dialog
  void _showPrivacyInfo() {
    final privacyStatus = _dataService.getPrivacyStatus();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.privacy_tip, color: Colors.green),
            SizedBox(width: 8),
            Text('Privacy & Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your privacy is protected:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...privacyStatus.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      entry.value ? Icons.check_circle : Icons.cancel,
                      color: entry.value ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getPrivacyStatusText(entry.key),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Data is automatically cleared when you close or refresh the app.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Get human-readable privacy status text
  String _getPrivacyStatusText(String key) {
    switch (key) {
      case 'clientSideProcessing':
        return 'All processing happens locally';
      case 'noExternalCalls':
        return 'No data sent to external servers';
      case 'automaticDataClearing':
        return 'Data cleared automatically';
      case 'noDataPersistence':
        return 'No data saved permanently';
      case 'localOCRProcessing':
        return 'OCR processing is local only';
      case 'browserOnlyClipboard':
        return 'Clipboard access is browser-native';
      default:
        return key;
    }
  }

  Future<void> _handleShare() async {
    final totals = _getOptimizedTotals();

    // Filter out people with zero amounts
    final nonZeroTotals = totals.entries
        .where((entry) => entry.value > 0)
        .toList();

    if (nonZeroTotals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No totals to share. Assign items first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Create clean formatted text: "John: $12.50, Sarah: $8.25"
    final shareText = nonZeroTotals
        .map((entry) => '${entry.key.name}: ${entry.value.toStringAsFixed(2)}')
        .join('\n');

    try {
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: shareText));

      // Show success feedback with visual confirmation
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Copied to clipboard: '),
              Expanded(
                child: Text(
                  shareText,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      // Fallback: show the text in a dialog if clipboard fails
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Totals'),
          content: SelectableText(shareText),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}
