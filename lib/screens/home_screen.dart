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
  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition;
  final TweetService _tweetService = TweetService();

  // Fixed radius for nearby tweets (30km)
  static const double _radiusKm = 30.0;

  // Default location (Mumbai, India)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(19.0760, 72.8777),
    zoom: 11,
  );

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

      // Use current location or default location
      final double lat = _currentPosition?.latitude ?? 19.0760;
      final double lng = _currentPosition?.longitude ?? 72.8777;

      // Fetch nearby tweets with fixed 30km radius
      final response = await _tweetService.getNearbyTweets(
        latitude: lat,
        longitude: lng,
        radius: _radiusKm.toInt(),
      );

      if (response.isSuccess && response.data != null) {
        setState(() {
          _tweets = response.data!;
          _isLoading = false;
        });

        // Update map markers after loading tweets
        _updateMapMarkers();
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load tweets';
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
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      // Use default location if getting current location fails
      debugPrint('Failed to get current location: $e');
    }
  }

  void _updateMapMarkers() {
    if (_mapController != null && _tweets.isNotEmpty) {
      // Optionally animate to show all markers
      // You can implement bounds calculation here if needed
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
    try {
      final response = await _tweetService.upvoteTweet(tweet.id);
      if (response.isSuccess) {
        // Refresh tweets to get updated upvote status
        await _refreshTweets();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed to upvote tweet'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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

        // Draggable Reports section
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: screenHeight * _sheetHeight,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _sheetHeight -= details.delta.dy / screenHeight;
                _sheetHeight = _sheetHeight.clamp(0.2, 0.8);
              });
            },
            child: _buildReportsSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleMap() {
    // Create markers from tweets
    final Set<Marker> markers = _tweets.map((tweet) {
      return Marker(
        markerId: MarkerId('tweet_${tweet.id}'),
        position: LatLng(tweet.latitude, tweet.longitude),
        infoWindow: InfoWindow(
          title: tweet.title,
          snippet: '${tweet.hazardType} - ${tweet.area}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerColor(tweet.hazardType),
        ),
      );
    }).toSet();

    return GestureDetector(
      onTap: _onMapTapped,
      child: GoogleMap(
        initialCameraPosition: _currentPosition != null
            ? CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 11,
              )
            : _initialPosition,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        mapType: MapType.normal,
        markers: markers,
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
          const Text(
            'Aqua X',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'User',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
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
                      Text(
                        '${_tweets.length} reports within ${_radiusKm}km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      itemCount: _tweets.length,
                      itemBuilder: (context, index) {
                        final tweet = _tweets[index];
                        return Column(
                          children: [
                            _buildReportCard(index: index, tweet: tweet),
                            if (index < _tweets.length - 1)
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
            // Image on the left
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
                          tweet.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF3498DB)),
                        ),
                        child: Text(
                          tweet.hazardType,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF3498DB),
                            fontWeight: FontWeight.w600,
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
                              size: 14,
                              color: tweet.isUpvoted
                                  ? const Color(0xFF3498DB)
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${tweet.upvoteCount}',
                              style: TextStyle(
                                fontSize: 11,
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
