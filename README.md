# Sangam - Ocean Conservation & Community Safety App

<div align="center">
  <img src="assets/getting started/sangam logo'.png" alt="Sangam Logo" width="150"/>
  
  **Empowering coastal communities through crowd-sourced reporting and real-time ocean safety information**
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.10.1+-02569B?logo=flutter)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.10.1+-0175C2?logo=dart)](https://dart.dev)
  [![License](https://img.shields.io/badge/License-Private-red.svg)](LICENSE)
</div>

---

## 📖 Table of Contents

- [About Sangam](#about-sangam)
- [Key Features](#key-features)
- [Screenshots](#screenshots)
- [Getting Started](#getting-started)
- [Installation](#installation)
- [Configuration](#configuration)
- [How to Use](#how-to-use)
- [App Architecture](#app-architecture)
- [Technologies Used](#technologies-used)
- [Contributing](#contributing)
- [Support](#support)

---

## 🌊 About Sangam

**Sangam** is a comprehensive mobile application designed to protect ocean ecosystems and ensure the safety of coastal communities. The app combines crowd-sourced hazard reporting with real-time weather data and emergency services to create a safer, more informed maritime environment.

### Mission
To empower fishermen, coastal residents, and ocean enthusiasts with the tools they need to report environmental hazards, access critical weather information, and stay safe while at sea.

### Vision
A connected community working together to preserve our oceans and protect lives through technology and collaboration.

---

## ✨ Key Features

### 🗺️ **Interactive Map with Hazard Reporting**
- **Real-time hazard visualization** with Google Maps integration
- **Crowd-sourced reports** from community members
- **Verified and unverified reports** with distinct visual indicators
- **Location-based filtering** (30km radius from your current location)
- **Hotspot circles** showing hazard zones (12km for verified, 5km for unverified)
- **Report categories**: Pollution, Water Quality, Marine Life, Plastic Waste, and more
- **Upvote system** to validate community reports
- **Image attachments** for visual evidence

### 🌤️ **Weather & Ocean Conditions**
- **Current weather data** with beautiful gradient UI
- **5-day weather forecast** for planning ahead
- **Ocean-specific conditions**:
  - Wind speed and direction
  - Visibility
  - Humidity
  - Atmospheric pressure
  - Sunrise and sunset times
- **Fishing Safety Indicator** - AI-powered safety assessment based on:
  - Wind conditions (unsafe if > 25 km/h)
  - Visibility (unsafe if < 1 km)
  - Weather conditions (storms, heavy rain)
- **Location-aware** weather using GPS

### 📸 **Camera Integration**
- **Capture hazard photos** directly from the app
- **Image upload** with reports for verification
- **Gallery access** for existing photos
- **Permission handling** for camera and storage

### 🚨 **Emergency Helpline**
- **24/7 emergency contact** (9420473470)
- **One-tap calling** for urgent situations
- **Water-related emergency assistance**
- **Hazard reporting support**

### 🌐 **Multi-language Support**
- **Real-time translation** of all app content
- **Support for multiple languages** to reach diverse communities
- **Seamless language switching**
- **Localized user experience**

### 👤 **User Authentication & Dashboard**
- **Secure login and signup** system
- **User profiles** with personalized dashboards
- **Report history** tracking
- **Activity monitoring**
- **Session management**

### 📍 **Location Services**
- **GPS integration** for accurate positioning
- **Automatic location detection**
- **Permission management**
- **Offline location caching**

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.10.1 or higher) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (3.10.1 or higher) - Comes with Flutter
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for version control
- **A physical device or emulator** for testing

### System Requirements

- **Windows**: Windows 10 or later
- **macOS**: macOS 10.14 or later
- **Linux**: 64-bit distribution
- **Disk Space**: At least 2.8 GB (excluding IDE/tools)
- **RAM**: Minimum 4 GB recommended

---

## 📥 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/sangam.git
cd sangam
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Verify Flutter Installation

```bash
flutter doctor
```

Fix any issues reported by Flutter Doctor before proceeding.

### 4. Run the App

**For Android:**
```bash
flutter run
```

**For iOS:**
```bash
cd ios
pod install
cd ..
flutter run
```

**For Web:**
```bash
flutter run -d chrome
```

---

## ⚙️ Configuration

### 🌦️ Weather API Setup (Required)

The weather feature requires a free API key from OpenWeatherMap. Follow these steps:

#### Step 1: Get Your API Key
1. Visit [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for a free account
3. Verify your email address
4. Navigate to [API Keys](https://home.openweathermap.org/api_keys)
5. Copy your API key

#### Step 2: Configure the App
1. Open `lib/services/weather_service.dart`
2. Find the line:
   ```dart
   static const String _apiKey = 'YOUR_API_KEY_HERE';
   ```
3. Replace `YOUR_API_KEY_HERE` with your actual API key:
   ```dart
   static const String _apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
   ```
4. Save the file

**Note**: New API keys may take 10-15 minutes to activate.

### 📍 Google Maps API Setup (Required for Android/iOS)

#### For Android:
1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Open `android/app/src/main/AndroidManifest.xml`
3. Add your API key:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
   ```

#### For iOS:
1. Open `ios/Runner/AppDelegate.swift`
2. Add your API key:
   ```swift
   GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
   ```

### 🔐 Permissions Configuration

The app requires the following permissions (already configured in the project):

**Android** (`android/app/src/main/AndroidManifest.xml`):
- `ACCESS_FINE_LOCATION` - GPS location
- `ACCESS_COARSE_LOCATION` - Network location
- `CAMERA` - Photo capture
- `INTERNET` - API calls
- `WRITE_EXTERNAL_STORAGE` - Save photos
- `READ_EXTERNAL_STORAGE` - Access gallery

**iOS** (`ios/Runner/Info.plist`):
- `NSLocationWhenInUseUsageDescription` - Location access
- `NSCameraUsageDescription` - Camera access
- `NSPhotoLibraryUsageDescription` - Photo library access

---

## 📖 How to Use

### 🏠 Home Screen - Map & Reports

1. **View Hazard Reports**
   - Open the app to see the interactive map
   - Red circles indicate verified hazards (12km radius)
   - Gray circles indicate unverified reports (5km radius)
   - Blue dot shows your current location

2. **Submit a Report**
   - Tap the camera/report button
   - Take a photo of the hazard
   - Select hazard type (Pollution, Water Quality, etc.)
   - Add description
   - Submit report

3. **Upvote Reports**
   - Scroll through the reports list at the bottom
   - Tap the upvote button to validate reports
   - Verified reports (with enough upvotes) appear in green

4. **View Report Details**
   - Tap on any report card to expand
   - See full description, images, and location
   - Check verification status and upvote count

### 🌤️ Weather Screen

1. **Check Current Conditions**
   - Navigate to the Weather tab
   - View current temperature, feels-like, and conditions
   - See weather icon representing current state

2. **Fishing Safety**
   - Check the safety indicator card
   - **Green "Safe"** = Good conditions for fishing
   - **Red "Unsafe"** = Dangerous conditions (high winds, poor visibility, storms)

3. **Detailed Ocean Conditions**
   - Wind speed and direction
   - Humidity percentage
   - Visibility distance
   - Atmospheric pressure
   - Sunrise and sunset times

4. **5-Day Forecast**
   - Scroll down to see upcoming weather
   - Each day shows temperature, conditions, and safety status
   - Plan your activities accordingly

5. **Refresh Data**
   - Pull down to refresh
   - Or tap the refresh icon in the header

### 🚨 Emergency Screen

1. **Access Emergency Services**
   - Navigate to the Emergency tab
   - View the 24/7 helpline number: **9420473470**

2. **Make Emergency Call**
   - Tap the "Call Now" button
   - Your phone will dial the emergency number
   - Available for water-related emergencies and hazard reporting

3. **Emergency Information**
   - Read the information card for guidance
   - Available 24/7 for immediate assistance

### 👤 User Dashboard

1. **Access Your Profile**
   - Tap the profile icon in the top-right corner
   - View your account information
   - See your report history
   - Check activity statistics

2. **Manage Settings**
   - Change language preferences
   - Update profile information
   - Manage notifications
   - Log out

### 🌐 Language Settings

1. **Change Language**
   - Access settings from the dashboard
   - Select your preferred language
   - All text will be translated in real-time
   - Supports multiple regional languages

---

## 🏗️ App Architecture

### Project Structure

```
sangam/
├── android/              # Android-specific files
├── ios/                  # iOS-specific files
├── lib/
│   ├── constants/        # App constants and configurations
│   ├── extensions/       # Dart extensions
│   ├── models/          # Data models
│   │   ├── tweet_model.dart      # Report/Tweet data structure
│   │   └── weather_model.dart    # Weather data structure
│   ├── providers/       # State management (Provider pattern)
│   │   ├── auth_provider.dart    # Authentication state
│   │   ├── user_provider.dart    # User data state
│   │   └── language_provider.dart # Language state
│   ├── screens/         # UI screens
│   │   ├── home_screen.dart           # Map & reports
│   │   ├── weather_screen.dart        # Weather & forecast
│   │   ├── emergency_screen.dart      # Emergency helpline
│   │   ├── camera_capture_page.dart   # Photo capture
│   │   ├── user_dashboard_screen.dart # User profile
│   │   ├── citizen_login_screen.dart  # Login
│   │   ├── citizen_signup_screen.dart # Registration
│   │   └── getting_started_screen.dart # Onboarding
│   ├── services/        # Business logic & API calls
│   │   ├── api_service.dart          # Base API service
│   │   ├── auth_service.dart         # Authentication
│   │   ├── tweet_service.dart        # Report management
│   │   ├── weather_service.dart      # Weather API
│   │   ├── translation_service.dart  # Language translation
│   │   ├── permission_service.dart   # Permission handling
│   │   └── storage_service.dart      # Local storage
│   ├── widgets/         # Reusable UI components
│   │   └── translated_text.dart      # Auto-translating text widget
│   └── main.dart        # App entry point
├── assets/              # Images, icons, and resources
├── test/                # Unit and widget tests
├── pubspec.yaml         # Dependencies and configuration
└── README.md            # This file
```

### State Management

The app uses **Provider** for state management:
- `AuthProvider` - Manages authentication state
- `UserProvider` - Manages user data and session
- `LanguageProvider` - Manages language preferences

### Data Flow

1. **User Action** → UI Screen
2. **Screen** → Service (API call or local operation)
3. **Service** → Provider (update state)
4. **Provider** → UI (rebuild with new data)

---

## 🛠️ Technologies Used

### Core Framework
- **Flutter** 3.10.1+ - Cross-platform UI framework
- **Dart** 3.10.1+ - Programming language

### Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `provider` | ^6.1.1 | State management |
| `google_maps_flutter` | ^2.5.0 | Interactive maps |
| `geolocator` | ^12.0.0 | GPS location services |
| `camera` | ^0.10.5+9 | Photo capture |
| `http` | ^1.2.2 | API communication |
| `translator` | ^1.0.4+1 | Multi-language support |
| `url_launcher` | ^6.3.1 | Phone calls & links |
| `permission_handler` | ^11.3.1 | Permission management |
| `shared_preferences` | ^2.3.2 | Local data storage |
| `path_provider` | ^2.1.4 | File system access |
| `flutter_svg` | ^2.0.10+1 | SVG image support |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

### External APIs
- **OpenWeatherMap API** - Weather data and forecasts
- **Google Maps API** - Map visualization and location services
- **Custom Backend API** - User authentication and report management

---

## 🤝 Contributing

We welcome contributions from the community! Here's how you can help:

### Reporting Issues
1. Check if the issue already exists
2. Create a detailed bug report with:
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Screenshots (if applicable)
   - Device and OS information

### Submitting Pull Requests
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex logic
- Write unit tests for new features

---

## 🐛 Troubleshooting

### Common Issues

**Issue**: Weather data not loading
- **Solution**: Check your OpenWeatherMap API key and ensure it's activated (wait 10-15 minutes after creation)

**Issue**: Location not detected
- **Solution**: Enable location services in device settings and grant permission to the app

**Issue**: Map not displaying
- **Solution**: Verify Google Maps API key is correctly configured in AndroidManifest.xml or AppDelegate.swift

**Issue**: Camera not working
- **Solution**: Grant camera permission in device settings

**Issue**: Build errors after `flutter pub get`
- **Solution**: Run `flutter clean` then `flutter pub get` again

---

## 📞 Support

### Need Help?

- **Emergency Helpline**: 9420473470 (24/7)
- **Email**: support@sangam.app
- **Documentation**: [Full Documentation](docs/)
- **FAQ**: [Frequently Asked Questions](docs/FAQ.md)

### Community

- **Discord**: [Join our community](https://discord.gg/sangam)
- **Twitter**: [@SangamApp](https://twitter.com/sangamapp)
- **Facebook**: [Sangam Community](https://facebook.com/sangamapp)

---

## 📄 License

This project is private and proprietary. All rights reserved.

---

## 🙏 Acknowledgments

- **OpenWeatherMap** for providing weather data API
- **Google Maps Platform** for mapping services
- **Flutter Community** for excellent packages and support
- **Coastal Communities** for their valuable feedback and testing
- **All Contributors** who have helped make Sangam better

---

## 🗺️ Roadmap

### Upcoming Features
- [ ] Push notifications for nearby hazards
- [ ] Offline mode with cached data
- [ ] Social sharing of reports
- [ ] Advanced analytics dashboard
- [ ] Integration with coast guard services
- [ ] Marine life identification using AI
- [ ] Tide predictions
- [ ] Ocean current information
- [ ] Community forums
- [ ] Gamification and rewards system

---

## 📊 Version History

### Version 1.0.0 (Current)
- Initial release
- Interactive map with hazard reporting
- Weather and ocean conditions
- Emergency helpline
- Multi-language support
- User authentication
- Camera integration

---

<div align="center">
  
  **Made with ❤️ for Ocean Conservation**
  
  *Protecting our oceans, one report at a time*
  
  [⬆ Back to Top](#sangam---ocean-conservation--community-safety-app)
  
</div>
