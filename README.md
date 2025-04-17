## ✨ Features (as of now)

- **Real-time Garbage Detection**: Analyze video feeds to identify and classify garbage
- **Multi-platform Support**: Works on mobile devices through Flutter and on web browsers
- **Image & Video Analysis**: Upload images or videos for offline processing
- **Detection Reports**: Download reports of processed media
- **User-friendly Interface**: Intuitive design for easy interaction
- **Live Camera Integration**: Connect to cameras for continuous monitoring
- **Multi-user Authentication**: Supports different user roles with customized portals
- **Real-time Analytics**: Dashboard with statistics and insights on garbage detection
- **Task Management**: System for assigning and tracking cleaning tasks
- **Manual Reporting Website**: Simple HTML/CSS/JS website for reporting garbage in areas without cameras

## 🛠️ Technologies Used

### Frontend
- React.js with Next.js for web interface
- Material UI for component styling
- Flutter (for mobile application)
- HTML/CSS/JavaScript for standalone reporting website

### Backend
- Flask (Python web framework)
- OpenCV (for image processing)
- YOLOv5 for object detection and garbage classification
- SQLite for data storage
- RESTful API for communication between frontend and backend

## 🚀 Installation

### Prerequisites
- Python 3.8+
- Node.js 16+ and npm
- Flutter SDK
- Git

### Backend Setup
```bash
# Clone the repository
git clone <repository-url>
cd GarbageDetector

# Create a virtual environment
python -m venv venv
source venv/bin/activate  # On Windows, use: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the Flask server
python app.py
```

### Frontend Setup
```bash
# Navigate to Frontend project
cd Frontend

# Install dependencies
npm install

# Run the application
npm run dev

# For Flutter mobile app
cd ../garbage_detector_app
flutter pub get
flutter run
```

### Reporting Website Setup
```bash
# Navigate to the reporting website directory
cd ReportingWebsite

# Open the website in a browser
# For local development, you can use any static file server
# Example using Python's built-in HTTP server:
python -m http.server 8080
# Then open http://localhost:8080 in your browser
```

## How the System Works

### Website Architecture
The web application follows a client-server architecture:

1. **Authentication System**:
   - Multiple user roles supported: Administrator, Janitor, and Inspector
   - Each role has access to a dedicated portal with role-specific functionalities
   - JWT-based authentication for secure access

2. **Administrator Portal**:
   - Dashboard with real-time statistics and analytics
   - User management for creating and managing janitor and inspector accounts
   - Access to all detection reports and task assignments
   - System configuration and settings

3. **Janitor Portal**:
   - Task list showing assigned garbage cleanup tasks
   - Task management interface for updating status (pending, in progress, completed)
   - Image upload capability to verify task completion
   - History of completed tasks and performance metrics

4. **Inspector Portal**:
   - Review of completed tasks
   - Approval or rejection of cleanup verification
   - Reporting capabilities for system performance
   - Analytics on detection accuracy and cleanup efficiency

5. **Real-time Updates**:
   - All portals feature automatic data refreshing every 60 seconds
   - Instant notifications for task assignments and status changes
   - Interactive maps showing detection locations and hotspots

6. **Reporting Website**:
   - Standalone web application for manual garbage reporting
   - Allows users to report garbage in areas without camera coverage
   - Uses geolocation to automatically capture location information
   - Supports photo uploads and detailed reporting
   - Can be integrated with the main system via API

### Backend System
The backend is built on Flask and handles:

1. **Machine Learning Pipeline**:
   - YOLOv5 model for garbage detection and classification
   - Image preprocessing for optimal detection accuracy
   - Confidence scoring for detected items

2. **API Endpoints**:
   - `/api/auth` - Authentication and user management
   - `/api/detections` - Garbage detection processing and results
   - `/api/tasks` - Task creation, assignment, and management
   - `/api/reports` - Report generation and statistics
   - `/api/logs` - System activity logging
   - `/get_logs` - Retrieval of detection history
   - `/update_status` - Updating task completion status

3. **Data Management**:
   - SQLite database for storing detection results, user data, and task information
   - File system storage for images and detection results
   - Automatic cleanup of temporary files

4. **Processing Pipeline**:
   - Input validation and sanitization
   - Queue system for handling multiple detection requests
   - Asynchronous processing for improved performance
   - Results caching for frequently accessed data

## 📁 Project Structure

```
/GarbageDetector/
├── Frontend/                      # Next.js web application
│   ├── app/                       # Next.js pages and components
│   ├── public/                    # Static assets
│   └── package.json               # Frontend dependencies
├── garbage_detector_app/          # Flutter mobile application
│   ├── lib/                       # Dart source code
│   ├── pubspec.yaml               # Flutter dependencies
├── garbage-cleaner-pwa/           # Progressive Web App
│   ├── src/                       # React components
│   ├── public/                    # Static assets
├── ReportingWebsite/              # Simple HTML/CSS/JS website for manual reporting
│   ├── css/                       # Stylesheet files
│   ├── js/                        # JavaScript files
│   ├── images/                    # Image assets
│   ├── uploads/                   # Directory for storing uploaded images
│   └── index.html                 # Main HTML file
├── app.py                         # Flask application (main backend)
├── detector/                      # Core detection algorithms
├── database/                      # Database models and connections
├── utils/                         # Utility functions
├── api/                           # API endpoint definitions
└── README.md                      # This documentation
```

## 👥 Team

- **[Viren Bahure]** 

## 🔮 Upcoming Improvements

- [ ] Add support for more waste categories
- [ ] Implement cloud storage for detection results
- [ ] Develop analytics dashboard for waste management insights
- [ ] Create mobile notifications for critical garbage accumulation
- [ ] Integrate with waste collection scheduling systems
- [ ] Improve detection accuracy in various lighting conditions
- [ ] Add geofencing capabilities for location-based alerts
- [ ] Implement predictive analytics for optimizing cleanup routes
- [ ] Integrate the reporting website with the main backend system

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [Dataset 1](https://drive.google.com/drive/folders/18GFW52hDXwDYJP_EKIXR6R9F4UxZWUlU?usp=sharing)
- [Dataset 2](https://github.com/garythung/trashnet.git)
- [OpenCV](https://opencv.org/) for image processing capabilities
- [Flutter](https://flutter.dev/) for cross-platform application development
- [Flask](https://flask.palletsprojects.com/) for backend web framework
- [Next.js](https://nextjs.org/) for frontend framework
- [Material UI](https://mui.com/) for UI components 