# Weather API Setup Instructions

## Getting Your OpenWeatherMap API Key

The weather feature requires a free API key from OpenWeatherMap. Follow these steps:

### Step 1: Sign Up for OpenWeatherMap
1. Go to https://openweathermap.org/api
2. Click on "Sign Up" or "Get API Key"
3. Create a free account
4. Verify your email address

### Step 2: Get Your API Key
1. Log in to your OpenWeatherMap account
2. Go to your API keys page: https://home.openweathermap.org/api_keys
3. Copy your API key (it looks like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`)

### Step 3: Add API Key to the App
1. Open the file: `sangam/lib/services/weather_service.dart`
2. Find this line:
   ```dart
   static const String _apiKey = 'YOUR_API_KEY_HERE';
   ```
3. Replace `YOUR_API_KEY_HERE` with your actual API key:
   ```dart
   static const String _apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
   ```
4. Save the file

### Step 4: Test the Weather Feature
1. Run the app
2. Navigate to the Weather tab
3. The weather data should now load successfully

## Important Notes

- **Free Tier Limits**: The free plan allows 1,000 API calls per day
- **API Activation**: New API keys may take 10-15 minutes to activate
- **Keep it Secret**: Don't share your API key publicly or commit it to public repositories

## Troubleshooting

### Error 401 (Unauthorized)
- Your API key is invalid or not activated yet
- Wait 10-15 minutes after creating your account
- Double-check that you copied the key correctly

### No Data Loading
- Check your internet connection
- Ensure location permissions are granted
- Verify the API key is correctly set

## Features Included

✅ Current weather conditions
✅ Temperature and feels-like temperature
✅ Wind speed and direction
✅ Humidity and visibility
✅ Sunrise and sunset times
✅ 5-day weather forecast
✅ **Fishing Safety Indicator** (Safe/Unsafe based on conditions)
✅ Ocean-oriented weather display

## API Documentation

For more information about the OpenWeatherMap API:
- API Documentation: https://openweathermap.org/api
- Current Weather: https://openweathermap.org/current
- 5 Day Forecast: https://openweathermap.org/forecast5
