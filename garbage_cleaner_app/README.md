# Garbage Cleaner App

A Flutter mobile application for cleaning staff to report and track garbage locations with photo capture and location tracking using OpenStreetMap.

## Features

- Staff login authentication
- Camera integration for taking photos of garbage
- Location tracking with OpenStreetMap
- Report submission with photos and geolocation
- History of submitted reports
- User-friendly interface

## Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (version 2.10.0 or higher)
- [Dart](https://dart.dev/get-dart) (version 2.16.0 or higher)
- Android Studio or VS Code with Flutter extensions
- A physical device or emulator for testing

## Dependencies

The app uses the following key packages:
- `flutter_map` for OpenStreetMap integration
- `geolocator` for accessing device location
- `image_picker` for camera and gallery access
- `shared_preferences` for local storage
- `provider` for state management

## Setup and Run

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/garbage_cleaner_app.git
cd garbage_cleaner_app
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the app

#### On an emulator:

```bash
flutter run
```

#### On a physical device:

1. Enable Developer options and USB debugging on your device
2. Connect your device to your computer via USB
3. Run:

```bash
flutter devices  # Verify your device is detected
flutter run
```

### 4. Build APK for installation

To build an APK that you can install directly on your Android device:

```bash
flutter build apk --release
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

## Running on Your Phone

### Android

1. Build the APK as mentioned above
2. Transfer the APK to your phone (email, USB, etc.)
3. Open the APK on your phone and follow installation prompts
4. If prompted about installing from unknown sources, enable this setting for this installation

### iOS

For iOS devices, you'll need to:
1. Have a Mac with Xcode installed
2. Register for an Apple Developer account
3. Connect your iPhone to your Mac
4. Open the project in Xcode:
   ```bash
   flutter build ios
   open ios/Runner.xcworkspace
   ```
5. Select your device in Xcode and click Run

## Test Account

Use the following credentials to log in:
- Username: staff
- Password: password123

## Integration with Garbage Detection Backend

This mobile app is designed to work with the garbage detection backend system. In a production environment, you would:

1. Configure the backend URL in the app's settings
2. Set up proper API authentication
3. Implement data synchronization between the app and the server

## Troubleshooting

- **Camera not working**: Ensure camera permissions are granted in device settings
- **Location not working**: Check location permissions and that GPS is enabled
- **Can't install on Android**: Enable "Install from Unknown Sources" in device settings
- **Flutter build errors**: Make sure you're using a compatible Flutter version 