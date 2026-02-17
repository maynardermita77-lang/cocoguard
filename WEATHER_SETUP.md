# Weather Feature Setup Guide

## ⚠️ Important: You Need a Free API Key!

The weather feature requires a **free** OpenWeatherMap API key.

### Steps to Get Your API Key:

1. **Sign up for free** at: https://openweathermap.org/api
2. Click **"Get API Key"** or **"Sign Up"**
3. Create a free account (no credit card required)
4. Once logged in, go to: https://home.openweathermap.org/api_keys
5. Copy your API key (it looks like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`)

### Add Your API Key to the App:

1. Open file: `lib/services/weather_service.dart`
2. Find this line:
   ```dart
   static const String _apiKey = 'YOUR_API_KEY_HERE';
   ```
3. Replace `YOUR_API_KEY_HERE` with your actual API key:
   ```dart
   static const String _apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
   ```
4. Save the file
5. **Restart the app** (Hot reload won't work for API keys)

### ✅ Testing the Weather:

1. Open the app in your browser or device
2. Allow location permissions when prompted
3. The dashboard should show:
   - Your precise GPS location (e.g., "Manila, PH")
   - Current temperature
   - Weather description (e.g., "Clear sky", "Scattered clouds")
   - Current date

### 🔧 Troubleshooting:

**"Location unavailable"**
- Browser: Make sure you clicked "Allow" for location access
- Check browser permissions (usually a 🔒 icon in address bar)

**"Unable to fetch weather"**
- Check your API key is correct
- Wait ~10 minutes after creating your API key (activation time)
- Check your internet connection

**Still not working?**
- Open browser Console (F12)
- Look for error messages
- Check the error code:
  - 401 = Invalid API key
  - 429 = Too many requests (free tier limit)
  - 404 = Check API endpoint

### 📝 Notes:

- **Free tier limits**: 60 calls/minute, 1,000,000 calls/month
- Weather updates every time you open the dashboard
- GPS location is fetched in real-time (not static!)
- No "Farm A" or hardcoded locations anymore 🎉
