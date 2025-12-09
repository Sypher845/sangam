import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sangam/widgets/translated_text.dart';
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
  late TabController _tabController;
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
    _tabController = TabController(length: 2, vsync: this);
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
        final verifiedList = verifiedResponse.data ?? [];
        final unverifiedList = unverifiedResponse.data ?? [];
        
        debugPrint('📊 Setting state with ${verifiedList.length} verified and ${unverifiedList.length} unverified tweets');
        
        setState(() {
          _verifiedTweets = verifiedList;
          _unverifiedTweets = unverifiedList;
          
          // Combine: verified first, then unverified
          _tweets = [..._verifiedTweets, ..._unverifiedTweets];
          _isLoading = false;
        });

        debugPrint('✅ State updated. Total tweets: ${_tweets.length}');
        
        // Update map markers after loading tweets
        _updateMapMarkers();
      } else {
        debugPrint('❌ Failed to load tweets: ${verifiedResponse.message ?? unverifiedResponse.message}');
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

  Color _getCredibilityColor(int credibility) {
    // Credibility is from 1-10
    if (credibility >= 7) {
      return Colors.green.shade700; // High credibility (7-10)
    } else if (credibility >= 4) {
      return Colors.orange.shade700; // Medium credibility (4-6)
    } else {
      return Colors.red.shade700; // Low credibility (1-3)
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
              TranslatedText('You have already upvoted this report'),
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
                  TranslatedText('Report upvoted successfully'),
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
                    child: TranslatedText(response.message ?? 'Failed to upvote report'),
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
                Expanded(child: TranslatedText('Error: ${e.toString()}')),
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
    _tabController.dispose();
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
              TranslatedText(
                'Getting your location...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TranslatedText(
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.report, color: Color(0xFF3498DB), size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: TranslatedText(
                    'Crowd-sourced Reports',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
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
                  child: const TranslatedText(
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

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF3498DB),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified, size: 16),
                      const SizedBox(width: 6),
                      Text('Verified (${_verifiedTweets.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pending, size: 16),
                      const SizedBox(width: 6),
                      Text('Unverified (${_unverifiedTweets.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tab View Content
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
                        TranslatedText(
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
                          child: const TranslatedText('Retry'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Verified Reports Tab
                      _buildReportsList(_verifiedTweets, 'verified'),
                      // Unverified Reports Tab
                      _buildReportsList(_unverifiedTweets, 'unverified'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(List<Tweet> tweets, String type) {
    debugPrint('🔍 Building $type reports list with ${tweets.length} items');
    
    if (tweets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'verified' ? Icons.verified_outlined : Icons.pending_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No $type reports found\nin your area (${_radiusKm}km radius)',
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
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTweets,
      child: ListView.builder(
        key: PageStorageKey<String>('reports_list_$type'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: tweets.length,
        itemBuilder: (context, index) {
          final tweet = tweets[index];
          debugPrint('📝 Building card for tweet ${tweet.id} at index $index');
          return Column(
            children: [
              _buildReportCard(index: index, tweet: tweet),
              if (index < tweets.length - 1) const SizedBox(height: 12),
            ],
          );
        },
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
                        child: TranslatedText(
                          tweet.hazardType.isNotEmpty ? tweet.hazardType : tweet.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      // Credibility indicator for unverified reports in top right
                      if (!tweet.isVerified && tweet.credibility != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCredibilityColor(tweet.credibility!).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _getCredibilityColor(tweet.credibility!),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user,
                                size: 14,
                                color: _getCredibilityColor(tweet.credibility!),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${tweet.credibility!}/10',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getCredibilityColor(tweet.credibility!),
                                ),
                              ),
                            ],
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
                    firstChild: TranslatedText(
                      tweet.hazardDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    secondChild: TranslatedText(
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
                        child: TranslatedText(
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
                      TranslatedText(
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
                            TranslatedText(
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
