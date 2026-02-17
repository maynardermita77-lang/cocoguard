# Push Notification Setup Guide for CocoGuard

This guide explains how to set up Firebase Cloud Messaging (FCM) push notifications for the CocoGuard mobile app. When a user detects an Asiatic Palm Weevil (APW), all other users will receive an alert notification that appears at the top of their screen, even when the app is closed.

## Features

- **Heads-up notifications**: Notifications appear at the top of the screen like Messenger or NDRRMC alerts
- **Works when app is closed**: Notifications are delivered even when the app is not running
- **Critical alerts**: APW detections are treated as critical alerts with distinctive styling
- **Auto-dismiss**: Notifications auto-dismiss after display (user can tap to view details)

## Setup Steps

### Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or select an existing project
3. Enter project name: `CocoGuard` (or your preferred name)
4. Enable Google Analytics (optional)
5. Click "Create project"

### Step 2: Add Android App to Firebase

1. In Firebase Console, click the Android icon to add an Android app
2. Enter the package name: `com.example.cocoguard` (check your actual package name in `android/app/build.gradle.kts`)
3. Enter app nickname: `CocoGuard Android`
4. Download the `google-services.json` file
5. Place it in: `cocoguard/android/app/google-services.json`

### Step 3: Configure Android Build Files

#### a. Update `android/build.gradle.kts`:

```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

#### b. Update `android/app/build.gradle.kts`:

Add at the bottom:
```kotlin
apply(plugin = "com.google.gms.google-services")
```

### Step 4: Get Firebase Admin SDK Credentials (for Backend)

1. In Firebase Console, go to Project Settings → Service Accounts
2. Click "Generate new private key"
3. Download the JSON file
4. Rename it to `firebase-service-account.json`
5. Place it in: `cocoguard-backend/firebase-service-account.json`

**⚠️ SECURITY WARNING**: Never commit this file to version control! Add it to `.gitignore`.

### Step 5: Install Backend Dependencies

```bash
cd cocoguard-backend
pip install firebase-admin
```

Or add to `requirements.txt`:
```
firebase-admin>=6.0.0
```

### Step 6: Run Database Migration

Add the FCM token column to the users table:

```bash
cd cocoguard-backend
python add_fcm_token_column.py
```

### Step 7: Build and Test the Flutter App

```bash
cd cocoguard
flutter pub get
flutter run
```

## How It Works

### Mobile App Flow

1. **App Initialization**: When the app starts, it initializes Firebase and requests notification permissions
2. **Token Registration**: The app gets an FCM token and stores it locally
3. **Login**: After user logs in, the token is sent to the backend and stored with the user record
4. **Topic Subscription**: The app subscribes to the `pest_alerts` topic for broadcast notifications

### Backend Flow

1. **Pest Detection**: When a user scans and detects APW (Asiatic Palm Weevil)
2. **Notification Creation**: The backend creates in-app notifications for all users
3. **Push Notification**: The backend sends FCM push notifications:
   - To all registered device tokens
   - To the `pest_alerts` topic (reaches all subscribers)

### Notification Display

- **Foreground**: Notification appears as a heads-up popup at the top of the screen
- **Background**: Notification appears in the system notification tray with sound/vibration
- **App Closed**: Same as background - system handles the notification display

## Configuration Options

### Notification Channel (Android)

The app creates a high-priority notification channel for pest alerts:

```dart
static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'pest_alerts_channel',
  'Pest Alerts',
  description: 'Critical pest detection alerts',
  importance: Importance.max,  // Ensures heads-up display
  playSound: true,
  enableVibration: true,
);
```

### Customizing Notifications

Edit `lib/services/push_notification_service.dart` to customize:

- Notification appearance (colors, icons)
- Vibration patterns
- Sound settings
- Action buttons

## Testing

### Test Local Notification

Add a test button in your app to verify notifications work:

```dart
ElevatedButton(
  onPressed: () => PushNotificationService.showTestNotification(),
  child: Text('Test Notification'),
)
```

### Test FCM from Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter test message details
4. Target your app
5. Send the test message

### Test Backend Push Notification

```bash
# Run the backend
cd cocoguard-backend
python -m uvicorn app.main:app --reload

# In another terminal, test the FCM endpoint (if you have a test scan)
curl -X POST "http://localhost:8000/notifications/test-push" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Troubleshooting

### Notifications Not Appearing

1. **Check permissions**: Ensure the app has notification permission
2. **Check Firebase setup**: Verify `google-services.json` is in the correct location
3. **Check logs**: Look for FCM-related logs in the app and backend

### Background Notifications Not Working

1. **Battery optimization**: Disable battery optimization for the app
2. **Do Not Disturb**: Check if DND mode is enabled
3. **App restrictions**: Some devices restrict background notifications

### FCM Token Not Registering

1. **Check network**: Ensure the device has internet connectivity
2. **Check backend logs**: Look for errors when storing the token
3. **Re-login**: Try logging out and logging back in

## File Structure

```
cocoguard/
├── lib/
│   └── services/
│       └── push_notification_service.dart  # Flutter FCM handler
├── android/
│   ├── app/
│   │   ├── google-services.json            # Firebase config (ADD THIS)
│   │   └── src/main/
│   │       ├── AndroidManifest.xml         # Permissions & config
│   │       └── res/values/colors.xml       # Notification color

cocoguard-backend/
├── firebase-service-account.json           # Firebase Admin SDK (ADD THIS)
├── add_fcm_token_column.py                 # Database migration
├── app/
│   ├── models.py                           # User model with fcm_token
│   ├── routers/
│   │   ├── users.py                        # FCM token endpoint
│   │   └── notifications.py                # Push notification trigger
│   └── services/
│       └── fcm_service.py                  # FCM sending service
```

## Security Notes

1. **Keep credentials safe**: Never expose `firebase-service-account.json`
2. **Token rotation**: FCM tokens can change; the app handles this automatically
3. **Rate limiting**: Firebase has sending limits; don't spam notifications

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging](https://pub.dev/packages/firebase_messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
