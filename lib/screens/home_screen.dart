import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/tweet_service.dart';
import '../models/tweet_model.dart';
import 'user_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  double _sheetHeight = 0.5; // Initial height at 50%
  GoogleMapController? _mapController;
  int? _expandedCardIndex; // Track which card is expanded
  late ScrollController _scrollController;

  // Tweet related state
  List<Tweet> _tweets = [];
  List<Tweet> _verifiedTweets = [];
  List<Tweet> _unverifiedTweets = [];
  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition;
  final TweetService _tweetService = TweetService();

  // Fixed radius for nearby tweets (30km)
  static const double _radiusKm = 30.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadTweets();
  }

  void _onScroll() {
    // Collapse expanded card when scrolling
    if (_expandedCardIndex != null) {
      setState(() {
        _expandedCardIndex = null;
      });
    }
  }

  Future<void> _loadTweets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current location first
      await _getCurrentLocation();

      // Check if we have a valid location
      if (_currentPosition == null) {
        setState(() {
          _errorMessage = 'Location not available. Please enable location services and grant permission.';
          _isLoading = false;
        });
        return;
      }

      // Use ONLY the accurate current location
      final double lat = _currentPosition!.latitude;
      final double lng = _currentPosition!.longitude;

      debugPrint('📡 Fetching reports for ACCURATE location: $lat, $lng (radius: ${_radiusKm}km)');

      // Fetch verified tweets first with location
      final verifiedResponse = await _tweetService.getVerifiedTweets(
        latitude: lat,
        longitude: lng,
        radius: _radiusKm.toInt(),
      );
      
      debugPrint('✅ Verified tweets: ${verifiedResponse.data?.length ?? 0}');
      
      // Fetch unverified tweets with location
      final unverifiedResponse = await _tweetService.getUnverifiedTweets(
        latitude: lat,
        longitude: lng,
        radius: _radiusKm.toInt(),
      );
      
      debugPrint('✅ Unverified tweets: ${unverifiedResponse.data?.length ?? 0}');

      if (verifiedResponse.isSuccess || unverifiedResponse.isSuccess) {
        setState(() {
          _verifiedTweets = verifiedResponse.data ?? [];
          _unverifiedTweets = unverifiedResponse.data ?? [];
          
          // Combine: verified first, then unverified
          _tweets = [..._verifiedTweets, ..._unverifiedTweets];
          _isLoading = false;
        });

        // Update map markers after loading tweets
        _updateMapMarkers();
      } else {
        setState(() {
          _errorMessage = verifiedResponse.message ?? unverifiedResponse.message ?? 'Failed to load tweets';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading tweets: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      debugPrint('🌍 Attempting to get current location...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      debugPrint('✅ Location obtained: ${position.latitude}, ${position.longitude}');
      setState(() {
        _currentPosition = position;
      });
      // Update map to center on user's location
      _updateMapMarkers();
    } catch (e) {
      // Use default location if getting current location fails
      debugPrint('❌ Failed to get current location: $e');
      debugPrint('📍 Using default location (Mumbai)');
    }
  }

  void _updateMapMarkers() {
    if (_mapController != null) {
      // Animate to user's location if available
      if (_currentPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              zoom: 12,
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshTweets() async {
    await _loadTweets();
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _handleUpvote(Tweet tweet) async {
    // Prevent multiple upvotes if already upvoted
    if (tweet.isUpvoted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('You have already upvoted this report'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Optimistically update UI
    final tweetIndex = _tweets.indexWhere((t) => t.id == tweet.id);
    if (tweetIndex != -1) {
      setState(() {
        _tweets[tweetIndex] = tweet.copyWith(
          isUpvoted: true,
          upvoteCount: tweet.upvoteCount + 1,
        );
        
        // Update in verified/unverified lists too
        final verifiedIndex = _verifiedTweets.indexWhere((t) => t.id == tweet.id);
        if (verifiedIndex != -1) {
          _verifiedTweets[verifiedIndex] = _tweets[tweetIndex];
        }
        
        final unverifiedIndex = _unverifiedTweets.indexWhere((t) => t.id == tweet.id);
        if (unverifiedIndex != -1) {
          _unverifiedTweets[unverifiedIndex] = _tweets[tweetIndex];
        }
      });
    }

    try {
      final response = await _tweetService.upvoteTweet(tweet.id);
      if (response.isSuccess) {
        // Refresh reports to get updated data from server
        await _refreshTweets();
        
        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.thumb_up, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Report upvoted successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Revert optimistic update on failure
        if (tweetIndex != -1) {
          setState(() {
            _tweets[tweetIndex] = tweet.copyWith(
              isUpvoted: false,
              upvoteCount: tweet.upvoteCount,
            );
            
            // Revert in verified/unverified lists too
            final verifiedIndex = _verifiedTweets.indexWhere((t) => t.id == tweet.id);
            if (verifiedIndex != -1) {
              _verifiedTweets[verifiedIndex] = _tweets[tweetIndex];
            }
            
            final unverifiedIndex = _unverifiedTweets.indexWhere((t) => t.id == tweet.id);
            if (unverifiedIndex != -1) {
              _unverifiedTweets[unverifiedIndex] = _tweets[tweetIndex];
            }
          });
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(response.message ?? 'Failed to upvote report'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      if (tweetIndex != -1) {
        setState(() {
          _tweets[tweetIndex] = tweet.copyWith(
            isUpvoted: false,
            upvoteCount: tweet.upvoteCount,
          );
          
          // Revert in verified/unverified lists too
          final verifiedIndex = _verifiedTweets.indexWhere((t) => t.id == tweet.id);
          if (verifiedIndex != -1) {
            _verifiedTweets[verifiedIndex] = _tweets[tweetIndex];
          }
          
          final unverifiedIndex = _unverifiedTweets.indexWhere((t) => t.id == tweet.id);
          if (unverifiedIndex != -1) {
            _unverifiedTweets[unverifiedIndex] = _tweets[tweetIndex];
          }
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMapTapped() {
    setState(() {
      _sheetHeight = 0.2; // Minimize to 20%
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // Full-screen Google Map
        _buildGoogleMap(),

        // Header
        SafeArea(child: _buildHeader()),

        // Draggable Reports section - extends to full bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: screenHeight * _sheetHeight,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _sheetHeight -= details.delta.dy / screenHeight;
                _sheetHeight = _sheetHeight.clamp(0.15, 0.7);
              });
            },
            child: _buildReportsSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleMap() {
    // If location not available yet, show loading overlay
    if (_currentPosition == null) {
      return Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF3498DB)),
              const SizedBox(height: 16),
              Text(
                'Getting your location...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please ensure location services are enabled',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Create circles for hotspots and center dots
    final List<Circle> allCircles = [];
    
    for (var tweet in _tweets) {
      final bool isVerified = tweet.isVerified;
      final LatLng position = LatLng(tweet.latitude, tweet.longitude);
      
      // Large hotspot circle (12km for verified, 5km for unverified)
      final double radiusMeters = isVerified ? 12000.0 : 5000.0;
      final Color fillColor = isVerified 
          ? Colors.red.withOpacity(0.25) 
          : Colors.grey.withOpacity(0.25);
      final Color strokeColor = isVerified 
          ? Colors.red.withOpacity(0.6) 
          : Colors.grey.withOpacity(0.6);

      allCircles.add(Circle(
        circleId: CircleId('hotspot_${tweet.id}'),
        center: position,
        radius: radiusMeters,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: 2,
      ));
      
      // Small center dot (red for verified, grey for unverified)
      final Color dotColor = isVerified ? Colors.red.shade800 : Colors.grey.shade700;
      
      allCircles.add(Circle(
        circleId: CircleId('dot_${tweet.id}'),
        center: position,
        radius: 200, // 200 meter radius for visible center dot
        fillColor: dotColor,
        strokeColor: dotColor,
        strokeWidth: 0,
      ));
    }
    
    // Add user location marker (blue dot with white border)
    allCircles.add(Circle(
      circleId: const CircleId('user_location_border'),
      center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      radius: 150, // White border
      fillColor: Colors.white,
      strokeColor: Colors.white,
      strokeWidth: 0,
    ));
    
    allCircles.add(Circle(
      circleId: const CircleId('user_location'),
      center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      radius: 100, // Blue dot
      fillColor: Colors.blue.shade600,
      strokeColor: Colors.blue.shade600,
      strokeWidth: 0,
    ));

    return GestureDetector(
      onTap: _onMapTapped,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 12,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        myLocationEnabled: false, // Disable default location indicator
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        mapType: MapType.normal,
        circles: allCircles.toSet(),
      ),
    );
  }

  double _getMarkerColor(String hazardType) {
    switch (hazardType.toLowerCase()) {
      case 'pollution':
        return BitmapDescriptor.hueRed;
      case 'water quality':
        return BitmapDescriptor.hueBlue;
      case 'marine life':
        return BitmapDescriptor.hueGreen;
      case 'plastic waste':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueViolet;
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sangam Logo with circular white background
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              'assets/getting started/sangam logo\'.png',
              height: 50,
              width: 50,
              fit: BoxFit.contain,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserDashboardScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Section Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.report, color: Color(0xFF3498DB), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crowd-sourced Reports',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          children: [
                            TextSpan(text: '${_tweets.length} reports'),
                            if (_verifiedTweets.isNotEmpty || _unverifiedTweets.isNotEmpty) ...[
                              const TextSpan(text: ' ('),
                              if (_verifiedTweets.isNotEmpty)
                                TextSpan(
                                  text: '${_verifiedTweets.length} verified',
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                                ),
                              if (_verifiedTweets.isNotEmpty && _unverifiedTweets.isNotEmpty)
                                const TextSpan(text: ', '),
                              if (_unverifiedTweets.isNotEmpty)
                                TextSpan(
                                  text: '${_unverifiedTweets.length} unverified',
                                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                                ),
                              const TextSpan(text: ')'),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _refreshTweets,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.refresh,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498DB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Live',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Reports List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3498DB)),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshTweets,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3498DB),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _tweets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No reports found in your area\n(${_radiusKm}km radius)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshTweets,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3498DB),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshTweets,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _tweets.length + (_verifiedTweets.isNotEmpty && _unverifiedTweets.isNotEmpty ? 2 : _verifiedTweets.isNotEmpty || _unverifiedTweets.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show verified section header
                        if (index == 0 && _verifiedTweets.isNotEmpty) {
                          return Column(
                            children: [
                              _buildSectionHeader('Verified Reports', _verifiedTweets.length, Colors.green),
                              const SizedBox(height: 12),
                            ],
                          );
                        }
                        
                        // Show unverified section header
                        if (_verifiedTweets.isNotEmpty && index == _verifiedTweets.length + 1 && _unverifiedTweets.isNotEmpty) {
                          return Column(
                            children: [
                              const SizedBox(height: 8),
                              _buildSectionHeader('Unverified Reports', _unverifiedTweets.length, Colors.orange),
                              const SizedBox(height: 12),
                            ],
                          );
                        }
                        
                        // Adjust index for headers
                        int tweetIndex = index;
                        if (_verifiedTweets.isNotEmpty) {
                          tweetIndex = index - 1;
                        }
                        if (_verifiedTweets.isNotEmpty && _unverifiedTweets.isNotEmpty && index > _verifiedTweets.length + 1) {
                          tweetIndex = index - 2;
                        }
                        
                        if (tweetIndex < 0 || tweetIndex >= _tweets.length) {
                          return const SizedBox.shrink();
                        }
                        
                        final tweet = _tweets[tweetIndex];
                        return Column(
                          children: [
                            _buildReportCard(index: tweetIndex, tweet: tweet),
                            if (tweetIndex < _tweets.length - 1)
                              const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            title.contains('Verified') ? Icons.verified : Icons.pending,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({required int index, required Tweet tweet}) {
    final bool isExpanded = _expandedCardIndex == index;
    final String timeAgo = _getTimeAgo(tweet.createdAt);
    final String imageUrl = tweet.images.isNotEmpty
        ? tweet.images.first.imageUrl
        : 'https://images.unsplash.com/photo-1583212292454-1fe6229603b7?w=400'; // Default fallback
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_expandedCardIndex == index) {
            _expandedCardIndex = null; // Collapse if already expanded
          } else {
            _expandedCardIndex = index; // Expand this card and collapse others
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image on the left with verification badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.network(
                      imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade300,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade600,
                            size: 32,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey.shade500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Verification badge overlay
                if (tweet.isVerified)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content on the right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tweet.hazardType.isNotEmpty ? tweet.hazardType : tweet.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Text(
                      tweet.hazardDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    secondChild: Text(
                      tweet.hazardDescription,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          tweet.area,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _handleUpvote(tweet),
                        child: Row(
                          children: [
                            Icon(
                              tweet.isUpvoted
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_outlined,
                              size: 18,
                              color: tweet.isUpvoted
                                  ? const Color(0xFF3498DB)
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${tweet.upvoteCount}',
                              style: TextStyle(
                                fontSize: 13,
                                color: tweet.isUpvoted
                                    ? const Color(0xFF3498DB)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
