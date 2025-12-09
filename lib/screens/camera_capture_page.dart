import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sangam/widgets/translated_text.dart';
import '../services/permission_service.dart';
import '../services/tweet_service.dart';

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isCapturing = false;
  int _selectedCameraIndex = 0;
  Position? _currentLocation;
  final PermissionService _permissionService = PermissionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() => _isLoading = true);

    try {
      // Start permission check and camera fetch in parallel
      final permissionFuture = _permissionService.hasAllRequiredPermissions();
      final camerasFuture = availableCameras();

      // Wait for both to complete
      final results = await Future.wait([permissionFuture, camerasFuture]);
      final hasPermissions = results[0] as bool;
      _cameras = results[1] as List<CameraDescription>;

      // Handle permissions if needed
      if (!hasPermissions) {
        final granted = await _permissionService.requestAllPermissions(context);
        if (!granted) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (_cameras.isEmpty) {
        _showErrorDialog('No cameras available on this device');
        setState(() => _isLoading = false);
        return;
      }

      // Initialize camera controller with optimized settings
      // Using low resolution for faster initialization
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.low, // Changed from medium to low for faster init
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // Show camera immediately, get location in background
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }

      // Get current location in background (non-blocking)
      _permissionService.getCurrentLocation().then((location) {
        if (mounted) {
          setState(() {
            _currentLocation = location;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to initialize camera: $e');
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    setState(() => _isLoading = true);

    await _cameraController?.dispose();

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;

    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.low, // Changed from medium to low for faster switching
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to switch camera: $e');
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (!_isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      // Capture the photo immediately
      final image = await _cameraController!.takePicture();

      // Use existing location (already fetched during initialization)
      // Only refresh if location is null
      _currentLocation ??= await _permissionService.getCurrentLocation();

      // Navigate to preview screen with captured image
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HazardPreviewPage(
              imagePath: image.path,
              location: _currentLocation,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to capture photo: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const TranslatedText('Error'),
        content: TranslatedText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const TranslatedText('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const TranslatedText(
          'Capture Hazard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF3498DB)),
                  SizedBox(height: 16),
                  TranslatedText(
                    'Initializing Camera...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : !_isInitialized
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const TranslatedText(
                    'Camera not available',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const TranslatedText(
                    'Please check camera permissions',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _initializeCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3498DB),
                    ),
                    child: const TranslatedText('Retry'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Camera preview
                Positioned.fill(child: CameraPreview(_cameraController!)),

                // Location indicator
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentLocation != null
                              ? Icons.location_on
                              : Icons.location_off,
                          color: _currentLocation != null
                              ? Colors.green
                              : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        TranslatedText(
                          _currentLocation != null
                              ? 'Location: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}'
                              : 'Location unavailable',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Camera controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Switch camera button
                        if (_cameras.length > 1)
                          _buildControlButton(
                            icon: Icons.flip_camera_ios,
                            onPressed: _switchCamera,
                          )
                        else
                          const SizedBox(width: 60),

                        // Capture button
                        GestureDetector(
                          onTap: _capturePhoto,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isCapturing ? Colors.red : Colors.white,
                              ),
                              child: _isCapturing
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),

                        // Flash/Settings button (placeholder)
                        _buildControlButton(
                          icon: Icons.flash_off,
                          onPressed: () {
                            // TODO: Implement flash toggle
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

class HazardPreviewPage extends StatefulWidget {
  final String imagePath;
  final Position? location;

  const HazardPreviewPage({super.key, required this.imagePath, this.location});

  @override
  State<HazardPreviewPage> createState() => _HazardPreviewPageState();
}

class _HazardPreviewPageState extends State<HazardPreviewPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  final TweetService _tweetService = TweetService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: TranslatedText(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitHazardReport() async {
    // Validate form fields
    final hazardType = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (hazardType.isEmpty) {
      _showValidationError('Please enter a hazard type for the report');
      return;
    }

    if (hazardType.length < 3) {
      _showValidationError('Hazard type must be at least 3 characters long');
      return;
    }

    if (description.isEmpty) {
      _showValidationError('Please enter a description for the hazard report');
      return;
    }

    if (description.length < 10) {
      _showValidationError('Description must be at least 10 characters long');
      return;
    }

    if (widget.location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText('Location is required to submit a hazard report'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Show AI credibility loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3498DB).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology,
                      size: 48,
                      color: Color(0xFF3498DB),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Analyzing Report',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Finding Credibility by AI...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    color: Color(0xFF3498DB),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    try {
      // Prepare image file
      final imageFile = File(widget.imagePath);

      // Check if file exists
      if (!await imageFile.exists()) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: TranslatedText(
                'Image file not found. Please capture the photo again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check file size (limit to 10MB)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        // 10MB limit
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: TranslatedText(
                'Image file is too large (max 10MB allowed). Please capture a smaller image.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Submit hazard report with real API call
      // Note: hazardType is now in title field, and title is set to hazardType
      final response = await _tweetService.createTweet(
        hazardType: _titleController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: widget.location!.latitude,
        longitude: widget.location!.longitude,
        images: [imageFile],
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: TranslatedText(
                      'Hazard report submitted successfully!',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate back to home screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          String errorMessage = 'Failed to submit report';

          // Provide specific error messages based on status code
          if (response.statusCode == 401) {
            errorMessage = 'Authentication failed. Please log in again.';
          } else if (response.statusCode == 413) {
            errorMessage = 'File too large. Please use a smaller image.';
          } else if (response.statusCode == 400) {
            errorMessage = response.message ?? 'Invalid data provided.';
          } else if (response.statusCode != null &&
              response.statusCode! >= 500) {
            errorMessage = 'Server error. Please try again later.';
          } else if (response.message != null) {
            errorMessage = response.message!;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TranslatedText(
                      errorMessage,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _submitHazardReport,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Failed to submit report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const TranslatedText(
          'Report Hazard',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
                image: DecorationImage(
                  image: FileImage(File(widget.imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          TranslatedText(
                            'Captured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Location info
            if (widget.location != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3498DB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF3498DB),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TranslatedText(
                        'Location: ${widget.location!.latitude.toStringAsFixed(6)}, ${widget.location!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Hazard Type field (replaces both dropdown and title)
            const TranslatedText(
              'Hazard Type *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: 'e.g., Ocean Pollution, Plastic Waste, Oil Spill',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3498DB)),
                ),
                contentPadding: const EdgeInsets.all(16),
                counterText: '',
              ),
            ),

            const SizedBox(height: 20),

            // Description field
            const TranslatedText(
              'Description *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    'Describe the hazard in detail (min 10 characters)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3498DB)),
                ),
                contentPadding: const EdgeInsets.all(16),
                helperText:
                    'Provide details about location, severity, and impact',
                helperStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitHazardReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498DB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          TranslatedText(
                            'Submitting...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : const TranslatedText(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            // Help text
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TranslatedText(
                      'Your report will help the community stay informed about ocean hazards and environmental issues.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
