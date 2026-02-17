# CocoGuard Mobile App - API Integration Guide

## Overview

The API integration is now complete and ready to use. The app has three main components:

1. **`api_service.dart`** - Core API client handling all HTTP requests, authentication, and error handling
2. **`api_endpoints.dart`** - API endpoint wrappers organized by feature (Auth, Scans, Farms, etc.)
3. **Backend** - FastAPI server running on `http://localhost:8000`

## Configuration

### Update API Base URL

The API service is configured to use different base URLs depending on your platform:

**In `lib/services/api_service.dart`:**

```dart
// For Android emulator (default):
static const String baseUrl = 'http://10.0.2.2:8000';

// For iOS/Web simulator:
// static const String baseUrl = 'http://localhost:8000';

// For Android physical device (replace with your IP):
// static const String baseUrl = 'http://192.168.x.x:8000';
```

### Environment Setup

1. **Start the backend server:**
   ```powershell
   cd c:\xampp\htdocs\cocoguard-backend
   .\venv\Scripts\python.exe -m uvicorn app.main:app --reload
   ```

2. **Run the Flutter app:**
   ```bash
   flutter run
   ```

## Usage Examples

### Authentication

```dart
import 'services/api_endpoints.dart';

// Login
try {
  final response = await AuthApi.login('user@example.com', 'password');
  print('Login successful: ${response['user']['email']}');
} on ApiException catch (e) {
  print('Login failed: ${e.message}');
}

// Register
try {
  final response = await AuthApi.register(
    'newuser@example.com',
    'password123',
    'John Doe',
  );
  print('Registration successful');
} on ApiException catch (e) {
  print('Registration failed: ${e.message}');
}

// Get current user
try {
  final user = await AuthApi.getCurrentUser();
  print('User: ${user['email']}');
} on ApiException catch (e) {
  print('Failed to get user: ${e.message}');
}

// Logout
await AuthApi.logout();
```

### Scans

```dart
// Get all scans
try {
  final scans = await ScansApi.getScans(limit: 10, offset: 0);
  for (var scan in scans) {
    print('Scan: ${scan['id']} - ${scan['pest_type']}');
  }
} on ApiException catch (e) {
  print('Failed to get scans: ${e.message}');
}

// Create new scan with image
try {
  final result = await ScansApi.createScan(
    '/path/to/image.jpg',
    'coconut_mite',
    latitude: 10.5,
    longitude: 20.5,
  );
  print('Scan created: ${result['id']}');
} on ApiException catch (e) {
  print('Failed to create scan: ${e.message}');
}

// Get scan details
try {
  final scan = await ScansApi.getScanDetail(1);
  print('Pest Type: ${scan['pest_type']}');
} on ApiException catch (e) {
  print('Failed to get scan: ${e.message}');
}
```

### Farms

```dart
// Get all farms
try {
  final farms = await FarmsApi.getFarms();
  for (var farm in farms) {
    print('Farm: ${farm['name']} - ${farm['location']}');
  }
} on ApiException catch (e) {
  print('Failed to get farms: ${e.message}');
}

// Create new farm
try {
  final farm = await FarmsApi.createFarm(
    'My Farm',
    'Coastal Region',
    latitude: 10.5,
    longitude: 20.5,
  );
  print('Farm created: ${farm['id']}');
} on ApiException catch (e) {
  print('Failed to create farm: ${e.message}');
}
```

### Pest Types

```dart
// Get all pest types
try {
  final pestTypes = await PestTypesApi.getPestTypes();
  for (var pest in pestTypes) {
    print('Pest: ${pest['name']} - ${pest['description']}');
  }
} on ApiException catch (e) {
  print('Failed to get pest types: ${e.message}');
}

// Search pest types
try {
  final results = await PestTypesApi.searchPestTypes('mite');
  print('Found ${results.length} pest types');
} on ApiException catch (e) {
  print('Search failed: ${e.message}');
}
```

### Knowledge Articles

```dart
// Get articles
try {
  final articles = await KnowledgeApi.getArticles(limit: 10);
  for (var article in articles) {
    print('Article: ${article['title']}');
  }
} on ApiException catch (e) {
  print('Failed to get articles: ${e.message}');
}

// Get article details
try {
  final article = await KnowledgeApi.getArticleDetail(1);
  print('Content: ${article['content']}');
} on ApiException catch (e) {
  print('Failed to get article: ${e.message}');
}
```

### Analytics

```dart
// Get dashboard stats
try {
  final stats = await AnalyticsApi.getDashboardStats();
  print('Total scans: ${stats['total_scans']}');
} on ApiException catch (e) {
  print('Failed to get stats: ${e.message}');
}

// Get scan statistics
try {
  final scanStats = await AnalyticsApi.getScanStats(period: 'week');
  print('Scans this week: ${scanStats['count']}');
} on ApiException catch (e) {
  print('Failed to get scan stats: ${e.message}');
}
```

### Feedback

```dart
// Submit feedback
try {
  final result = await FeedbackApi.submitFeedback(
    'Bug Report',
    'The app crashes when uploading large images',
    '2',
  );
  print('Feedback submitted');
} on ApiException catch (e) {
  print('Failed to submit feedback: ${e.message}');
}
```

## Error Handling

The API service throws `ApiException` for all errors. Handle them in your screens:

```dart
try {
  final data = await SomeApi.someMethod();
  // Use data
} on ApiException catch (e) {
  // Show error to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.message}')),
  );
}
```

## Authentication Tokens

Tokens are automatically:
- Saved to local storage after login
- Loaded on app startup via `ApiService.init()`
- Included in all authenticated requests
- Cleared on logout or 401 responses

Check authentication status:
```dart
if (ApiService.isAuthenticated()) {
  // User is logged in
} else {
  // Show login screen
}
```

## Timeout Configuration

All requests have a 30-second timeout (5 minutes for file uploads). Modify in `api_service.dart` if needed:

```dart
.timeout(const Duration(seconds: 30))
```

## Next Steps

1. Update your login/registration screens to use `AuthApi`
2. Update scan screens to use `ScansApi`
3. Update knowledge screens to use `KnowledgeApi`
4. Add error handling and loading states
5. Add toast/snackbar notifications for API responses
6. Test with the running backend server

## Backend API Documentation

Once the backend is running, visit:
- **Interactive API Docs**: http://localhost:8000/docs
- **Alternative Docs**: http://localhost:8000/redoc

This will show all available endpoints, request/response formats, and allow you to test endpoints directly.
