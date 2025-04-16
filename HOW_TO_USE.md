# Garbage Detection System Setup Guide

## Step 1: Start the Flask Server
1. Open a terminal in the project root directory
2. Run: `python app.py`
3. Server will start at: http://127.0.0.1:5000

## Step 2: Open the Test Web Interface
1. Open your browser and go to: http://127.0.0.1:5000/
2. This will load the test interface
3. Verify the server is working by checking "Connected" status
4. Click "Populate 5 Test Detections" to create sample data

## Step 3: Run the Flutter App
1. Open a terminal in the `garbage_cleaner_minimal` directory
2. Run: `flutter run`
3. When the app starts, go to the "Detections" tab
4. Click the "CHECK SERVER" button in the empty detections screen
5. For the server URL:
   - Android Emulator: use `http://10.0.2.2:5000`
   - Real Android/iOS device: use your computer's IP address, like `http://192.168.1.x:5000`
   - Web: use `http://localhost:5000`
6. Click "CHECK" to connect to the server
7. The app should now show the detections from the server

## Troubleshooting
If you still don't see detections:

1. Check the server console for errors
2. In the test web interface, try:
   - "Create Single Test Detection" button
   - "Get All Logs" button to check if detections exist
   - "Test First Image URL" to verify images are accessible
3. In the Flutter app: 
   - Make sure you're connected to the same network as the server
   - Try using the "Debug" tool in the app (bug icon in the app bar)
   - Check for any error messages in the app

## URL Reference
- Server API endpoint: `http://127.0.0.1:5000/get_logs`
- Image URL format: `http://127.0.0.1:5000/view_image/uploads/image_name.jpg`
- Test Web Interface: `http://127.0.0.1:5000/`
- Debug API endpoint: `http://127.0.0.1:5000/debug_api` 