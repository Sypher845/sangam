import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../services/tweet_service.dart';
import '../services/auth_service.dart';
import '../models/tweet_model.dart';
import '../models/user_model.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  bool _isPostedReportsExpanded = false;
  bool _isLikedReportsExpanded = false;

  // API services
  final TweetService _tweetService = TweetService();
  final AuthService _authService = AuthService();

  // State for API data
  List<Tweet> _myTweets = [];
  List<Tweet> _likedTweets = [];
  User? _currentUser;
  bool _isLoadingTweets = true;
  bool _isLoadingLikedTweets = true;
  bool _isLoadingProfile = true;
  String? _tweetsError;
  String? _likedTweetsError;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await Future.wait([
      _loadMyTweets(),
      _loadLikedTweets(),
      _loadStoredUserProfile(),
    ]);
  }

  Future<void> _loadMyTweets() async {
    setState(() {
      _isLoadingTweets = true;
      _tweetsError = null;
    });

    try {
      final response = await _tweetService.getMyTweets();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _myTweets = response.data!;
          _isLoadingTweets = false;
        });
      } else {
        setState(() {
          _tweetsError = response.message ?? 'Failed to load tweets';
          _isLoadingTweets = false;
        });
      }
    } catch (e) {
      setState(() {
        _tweetsError = 'Error: ${e.toString()}';
        _isLoadingTweets = false;
      });
    }
  }

  Future<void> _loadLikedTweets() async {
    setState(() {
      _isLoadingLikedTweets = true;
      _likedTweetsError = null;
    });

    try {
      final response = await _tweetService.getUpvotedTweets();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _likedTweets = response.data!;
          _isLoadingLikedTweets = false;
        });
      } else {
        setState(() {
          _likedTweetsError = response.message ?? 'Failed to load liked tweets';
          _isLoadingLikedTweets = false;
        });
      }
    } catch (e) {
      setState(() {
        _likedTweetsError = 'Error: ${e.toString()}';
        _isLoadingLikedTweets = false;
      });
    }
  }

  Future<void> _loadStoredUserProfile() async {
    try {
      final storedUser = await _authService.getStoredUser();
      setState(() {
        if (storedUser != null) {
          _currentUser = storedUser;
          _profileError = null;
        } else {
          _profileError = 'No user data found in storage';
        }
        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() {
        _profileError = 'Error loading stored profile: ${e.toString()}';
        _isLoadingProfile = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'User Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section
              _buildUserProfileSection(),
              const SizedBox(height: 20),

              // Address Information
              _buildAddressSection(),

              // Profile Error (if any)
              if (_profileError != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Profile Error',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profileError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadStoredUserProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Posted Reports Section
              _buildReportsSection(
                title: 'My Posted Reports',
                subtitle: _isLoadingTweets
                    ? 'Loading...'
                    : '${_myTweets.length} reports posted',
                tweets: _myTweets,
                isExpanded: _isPostedReportsExpanded,
                isLoading: _isLoadingTweets,
                error: _tweetsError,
                onToggle: () {
                  setState(() {
                    _isPostedReportsExpanded = !_isPostedReportsExpanded;
                  });
                },
                onRefresh: _loadMyTweets,
              ),
              const SizedBox(height: 16),

              // Liked Reports Section
              _buildReportsSection(
                title: 'Reports I Liked',
                subtitle: _isLoadingLikedTweets
                    ? 'Loading...'
                    : '${_likedTweets.length} reports liked',
                tweets: _likedTweets,
                isExpanded: _isLikedReportsExpanded,
                isLoading: _isLoadingLikedTweets,
                error: _likedTweetsError,
                onToggle: () {
                  setState(() {
                    _isLikedReportsExpanded = !_isLikedReportsExpanded;
                  });
                },
                onRefresh: _loadLikedTweets,
              ),
              const SizedBox(height: 30),

              // Logout Button
              _buildLogoutButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3498DB), Color(0xFF2980B9), Color(0xFF1F5F99)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3498DB).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Avatar with enhanced design
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1ABC9C), Color(0xFF16A085)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      authProvider.userName?.isNotEmpty == true
                          ? authProvider.userName![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // User Name with enhanced styling
              Text(
                authProvider.userName ?? 'User Name',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Phone Number with enhanced design
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.phone,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '+91 ${authProvider.userPhone ?? 'Not available'}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Additional user stats or info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    icon: Icons.upload,
                    count: _isLoadingTweets ? '...' : '${_myTweets.length}',
                    label: 'Reports',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  _buildStatItem(
                    icon: Icons.favorite,
                    count: _isLoadingLikedTweets
                        ? '...'
                        : '${_likedTweets.length}',
                    label: 'Liked',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  _buildStatItem(
                    icon: Icons.verified,
                    count: '2',
                    label: 'Verified',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String count,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Address Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),

          // User Information
          _buildAddressItem(
            icon: Icons.person,
            label: 'User ID',
            address: _currentUser?.id ?? 'Not available',
            isLoading: false,
          ),
          const SizedBox(height: 12),

          // Phone Number
          _buildAddressItem(
            icon: Icons.phone,
            label: 'Mobile Number',
            address: _currentUser?.phoneNumber ?? 'Not available',
            isLoading: false,
          ),
          const SizedBox(height: 12),

          // Registration Date
          _buildAddressItem(
            icon: Icons.calendar_today,
            label: 'Joined',
            address: _isLoadingProfile
                ? 'Loading...'
                : (_currentUser?.createdAt != null
                      ? _getTimeAgo(_currentUser!.createdAt)
                      : 'Not available'),
            isLoading: _isLoadingProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressItem({
    required IconData icon,
    required String label,
    required String address,
    bool isLoading = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3498DB).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF3498DB), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3498DB),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportsSection({
    required String title,
    required String subtitle,
    required List<Tweet> tweets,
    required bool isExpanded,
    required bool isLoading,
    required VoidCallback onToggle,
    required Future<void> Function() onRefresh,
    String? error,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: Radius.circular(isExpanded ? 0 : 16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3498DB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      title.contains('Posted') ? Icons.upload : Icons.favorite,
                      color: const Color(0xFF3498DB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF3498DB),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Reports List
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isExpanded ? null : 0,
            child: isExpanded
                ? isLoading
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF3498DB),
                            ),
                          ),
                        )
                      : error != null
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                error,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: onRefresh,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3498DB),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : tweets.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No reports found',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: tweets
                              .map((tweet) => _buildTweetItem(tweet))
                              .toList(),
                        )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildTweetItem(Tweet tweet) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          Text(
            tweet.hazardDescription,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  tweet.area,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                _getTimeAgo(tweet.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const Spacer(),
              Icon(
                tweet.isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
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
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return ElevatedButton(
            onPressed: authProvider.isLoading
                ? null
                : () async {
                    // Show confirmation dialog
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      await authProvider.logout();
                      if (mounted) {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          );
        },
      ),
    );
  }
}
