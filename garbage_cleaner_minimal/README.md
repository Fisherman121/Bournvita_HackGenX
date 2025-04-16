# Garbage Cleaner Minimal App

A Flutter application for logging and cleaning garbage detections. This app provides functionality to:

- View garbage detections from a local database
- Sync with a remote server to fetch and update detection data
- Mark garbage as cleaned
- Manage server connection settings

## API Service Usage

The application includes a comprehensive API service for communicating with the backend server:

### Basic Setup

```dart
// Initialize API service with default or stored URL
await ApiService.initFromPrefs();

// Create an instance of the service
final apiService = ApiService();

// Don't forget to dispose when done
apiService.dispose();
```

### Configuration

```dart
// Set a custom server URL
await ApiService.setupServerUrl('http://10.0.2.2:8080');

// Get current server URL
final url = await ApiService.getBaseUrl();

// Test connection to server
final connectionStatus = await apiService.testConnection();
if (connectionStatus['success']) {
  // Connection successful
} else {
  // Connection failed
}
```

### Working with Detections

```dart
// Get all detections
final allDetections = await apiService.getAllDetections();

// Get only detections marked for cleaning
final cleaningTasks = await apiService.getCleaningDetections();

// Get simplified detection logs
final detectionLogs = await apiService.getDetectionLogs();

// Get minimal test data
final minimalData = await apiService.getMinimalDetections();

// Upload a new detection
await apiService.uploadDetection(detection);

// Update detection status
await apiService.updateDetectionStatus(timestamp, 'cleaned');

// Report a cleaned detection
await apiService.reportCleaned(
  timestamp,
  'Cleaner Name',
  'Notes about cleaning',
);

// Sync local detections with server
await apiService.syncDetections(localDetections);
```

### Error Handling

The API service throws `ApiException` for better error handling:

```dart
try {
  final detections = await apiService.getAllDetections();
  // Process detections
} catch (e) {
  if (e is ApiException) {
    print('API Error: ${e.message}, Status: ${e.statusCode}');
  } else {
    print('General Error: $e');
  }
}
```

## Local Storage

The app uses SQLite for local storage of detection data with synchronization capabilities:

```dart
final localStorage = LocalStorage();

// Get all detections
final detections = await localStorage.getDetections();

// Mark as cleaned
await localStorage.markAsCleaned(
  timestamp,
  'Cleaner Name',
  'Cleaning notes',
);

// Sync with server (both ways)
final syncSuccess = await localStorage.syncWithServer();

// Full refresh from server (clear local, get all from server)
final refreshSuccess = await localStorage.fullRefreshFromServer();
```

## Running the Application

```bash
flutter pub get
flutter run
```

## Testing

Use the test data service to add sample data for testing:

```dart
await TestDataService.addTestData();
```
