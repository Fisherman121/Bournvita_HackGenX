## ✨ Features (as of now)

- **Real-time Garbage Detection**: Analyze video feeds to identify and classify garbage
- **Multi-platform Support**: Works on mobile devices through Flutter and on web browsers
- **Image & Video Analysis**: Upload images or videos for offline processing
- **Detection Reports**: Download reports of processed media
- **User-friendly Interface**: Intuitive design for easy interaction
- **Live Camera Integration**: Connect to cameras for continuous monitoring

## 🛠️ Technologies Used

### Frontend
- Flutter (for mobile application)
- HTML/CSS/JavaScript (for web interface)

### Backend
- Flask (Python web framework)
- OpenCV (for image processing)
- Machine Learning models for garbage classification
- RESTful API for communication between frontend and backend

## 🚀 Installation

### Prerequisites
- Python 3.8+
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
# Navigate to Flutter project
cd garbage_cleaner_minimal

# Install dependencies
flutter pub get

# Run the application
flutter run
```

##  Usage

### Web Interface
1. Access the application at `http://localhost:5000`
2. Upload an image or video, or connect to a camera feed
3. View detection results in real-time
4. Download reports as needed

### Mobile Application
1. Launch the GarbageDetector mobile app
2. Sign in to your account (if applicable)
3. Use camera to detect garbage or upload media from gallery
4. View results and statistics

## 📁 Project Structure

```
/GarbageDetector/
├── garbage_cleaner_minimal/       # Flutter mobile application
│   ├── lib/                       # Dart source code
│   ├── pubspec.yaml               # Flutter dependencies
│   └── ...                        # Other Flutter-related files
├── app.py                         # Flask application (main backend)
├── GarbageDetector.py             # Core detection algorithms
├── GarbageDetector_Camera.py      # Camera integration
├── GarbageDetectorLive.py         # Live detection processing
├── index.html                     # Web interface
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

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [Dataset 1](https://drive.google.com/drive/folders/18GFW52hDXwDYJP_EKIXR6R9F4UxZWUlU?usp=sharing)
- [Dataset 2](https://github.com/garythung/trashnet.git)
- [OpenCV](https://opencv.org/) for image processing capabilities
- [Flutter](https://flutter.dev/) for cross-platform application development
- [Flask](https://flask.palletsprojects.com/) for backend web framework 