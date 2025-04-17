from flask import Flask, render_template, Response, jsonify, request, send_file, send_from_directory
import cv2
import math
import cvzone
import json
from datetime import datetime, timedelta
import os
import torch
import numpy as np
from werkzeug.utils import secure_filename
from ultralytics.nn.tasks import DetectionModel
from torch.nn.modules.container import Sequential
from ultralytics.nn.modules.conv import Conv
from torch.nn.modules.conv import Conv2d
from torch.nn.modules.batchnorm import BatchNorm2d
from torch.nn import SiLU, Upsample
from ultralytics.nn.modules import C2f, SPPF, Detect
import base64
import time
from flask_cors import CORS
import flask
import sqlite3
from sqlite3 import Error
import urllib.parse
import re

# Override torch_safe_load in ultralytics to use weights_only=False
# Only do this if you fully trust your model file
def torch_safe_load_override(file):
    ckpt = torch.load(file, map_location="cpu", weights_only=False)
    return ckpt, file  # Return both the checkpoint and the file path

# Patch the function in the ultralytics library
import ultralytics.nn.tasks
ultralytics.nn.tasks.torch_safe_load = torch_safe_load_override

# Now import YOLO after the patch
from ultralytics import YOLO

# Add all necessary classes to safe globals
torch.serialization.add_safe_globals([
    DetectionModel, Sequential, Conv, Conv2d, BatchNorm2d,
    SiLU, Upsample, C2f, SPPF, Detect
])

app = Flask(__name__, static_folder='static', static_url_path='')
# Enable CORS for all routes
CORS(app)

# Configure upload folder
UPLOAD_FOLDER = 'uploads'
PROCESSED_FOLDER = 'processed_videos'
PROCESSED_PHOTOS_FOLDER = 'processed_photos'
ALLOWED_EXTENSIONS = {'mp4', 'avi', 'mov', 'jpg', 'jpeg', 'png'}

# Ensure upload and processed folders exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(PROCESSED_FOLDER, exist_ok=True)
os.makedirs(PROCESSED_PHOTOS_FOLDER, exist_ok=True)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['PROCESSED_FOLDER'] = PROCESSED_FOLDER
app.config['PROCESSED_PHOTOS_FOLDER'] = PROCESSED_PHOTOS_FOLDER

# Load YOLO model with custom weights
yolo_model = YOLO("Weights/best.pt")

# Define class names
class_labels = ['0', 'c', 'garbage', 'garbage_bag', 'sampah-detection', 'trash']

# Create logs directory if it doesn't exist
if not os.path.exists('logs'):
    os.makedirs('logs')

# Store detection history
detection_history = []

# Track the last time a detection was logged for cleaning
last_cleaning_log_time = 0
CLEANING_LOG_INTERVAL = 60  # seconds

# Global variables
DETECTION_FOLDER = 'detections'
if not os.path.exists(DETECTION_FOLDER):
    os.makedirs(DETECTION_FOLDER)

# List to store detection results
detections = []

# Configuration for camera zones
CAMERA_ZONES = {
    'camera_0': {
        'zone_name': 'Zone 1',
        'location': 'Main Entrance',
        'description': 'Camera monitoring the main entrance area'
    }
    # Add more cameras as needed
}

# Current camera identifier - default to camera_0
current_camera_id = 'camera_0'

# Add global variable for location override
current_zone_override = None

def process_frame(frame):
    # Perform detection
    results = yolo_model(frame)
    
    detection_found = False
    current_detection = None
    
    # Process detections
    for r in results:
        boxes = r.boxes
        for box in boxes:
            x1, y1, x2, y2 = box.xyxy[0]
            x1, y1, x2, y2 = int(x1), int(y1), int(x2), int(y2)
            w, h = x2 - x1, y2 - y1
            
            conf = math.ceil((box.conf[0] * 100)) / 100
            cls = int(box.cls[0])
            
            if conf > 0.3:
                detection_found = True
                
                # Draw bounding box
                cvzone.cornerRect(frame, (x1, y1, w, h), t=2)
                cvzone.putTextRect(frame, f'{class_labels[cls]} {conf}', (x1, y1 - 10), scale=0.8, thickness=1, colorR=(255, 0, 0))
                
                # Save detection to history
                timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
                image_filename = f'detection_{timestamp}.jpg'
                image_path = os.path.join(UPLOAD_FOLDER, image_filename)
                
                # Save detection image
                try:
                    cv2.imwrite(image_path, frame)
                    print(f"Saved detection image to: {image_path}")
                    
                    # Check if file was actually saved
                    if os.path.exists(image_path):
                        print(f"File exists at: {image_path}")
                    else:
                        print(f"ERROR: File does not exist at: {image_path}")
                except Exception as e:
                    print(f"Error saving image: {e}")
                
                # Check if we should mark this detection for cleaning (once per minute)
                global last_cleaning_log_time
                current_time = time.time()
                mark_for_cleaning = (current_time - last_cleaning_log_time) >= CLEANING_LOG_INTERVAL
                
                if mark_for_cleaning:
                    last_cleaning_log_time = current_time
                
                # Get zone information - use override if available
                global current_zone_override
                if current_zone_override:
                    zone_info = current_zone_override
                else:
                    zone_info = CAMERA_ZONES.get(current_camera_id, {'zone_name': 'Unknown Zone', 'location': 'Unknown Location'})
                
                detection = {
                    'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                    'class': class_labels[cls],
                    'confidence': conf,
                    'status': 'pending',  # pending, cleaned
                    'image_path': f'{UPLOAD_FOLDER}/{image_filename}',
                    'forCleaning': mark_for_cleaning,
                    'camera_id': current_camera_id,
                    'zone_name': zone_info['zone_name'],
                    'location': zone_info['location']
                }
                
                # Extract coordinates if present in the location format "Name (lat, lng)"
                location_coords_match = re.search(r'\(([-+]?[0-9]*\.?[0-9]+),\s*([-+]?[0-9]*\.?[0-9]+)\)', zone_info['location'])
                if location_coords_match:
                    detection['latitude'] = location_coords_match.group(1)
                    detection['longitude'] = location_coords_match.group(2)
                
                current_detection = detection
                
                # Add to detection history
                detection_history.append(detection)
                print(f"Added detection to history: {detection}")
                
                # Keep only last 100 detections
                if len(detection_history) > 100:
                    detection_history.pop(0)
    
    return frame, current_detection

def generate_frames():
    camera = cv2.VideoCapture(0)
    while True:
        success, frame = camera.read()
        if not success:
            break
        else:
            frame, detection = process_frame(frame)
            
            ret, buffer = cv2.imencode('.jpg', frame)
            frame = buffer.tobytes()
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api_test')
def api_test():
    return send_from_directory('static', 'test_api.html')

@app.route('/video_feed')
def video_feed():
    return Response(generate_frames(),
                    mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/get_detections')
def get_detections():
    return jsonify(get_detections_from_db())

@app.route('/update_status', methods=['POST'])
def update_status():
    data = request.json
    timestamp = data.get('timestamp')
    status = data.get('status')
    
    for detection in detection_history:
        if detection['timestamp'] == timestamp:
            detection['status'] = status
            break
    
    return jsonify({'success': True})

@app.route('/process_photo', methods=['POST'])
def process_photo():
    if 'photo' not in request.files:
        return jsonify({'error': 'No photo uploaded'}), 400
    
    file = request.files['photo']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
    # Get location information from the request
    location = request.form.get('location', '')
    latitude = request.form.get('latitude', '')
    longitude = request.form.get('longitude', '')
    
    # Format coordinates if provided
    coordinates = ''
    if latitude and longitude:
        coordinates = f"{latitude}, {longitude}"
    
    # Create location string with coordinates if available
    location_with_coords = location
    if coordinates:
        location_with_coords = f"{location} ({coordinates})"
    
    if file:
        filename = secure_filename(file.filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)
        
        # Read and process the image
        frame = cv2.imread(filepath)
        
        # Get zone information for the current camera
        zone_info = CAMERA_ZONES.get(current_camera_id, {'zone_name': 'Unknown Zone', 'location': 'Unknown Location'})
        
        # Override location if user provided it
        if location_with_coords:
            zone_info['location'] = location_with_coords
        
        # Save the camera/zone info to use in process_frame
        global current_zone_override
        current_zone_override = zone_info
        
        frame, detection = process_frame(frame)
        
        # Reset the override
        current_zone_override = None
        
        # Save processed image
        processed_filename = 'processed_' + filename
        processed_path = os.path.join(app.config['PROCESSED_PHOTOS_FOLDER'], processed_filename)
        cv2.imwrite(processed_path, frame)
        
        return jsonify({
            'success': True,
            'original_path': filepath,
            'processed_path': processed_path,
            'detection': detection
        })

@app.route('/process_video', methods=['POST'])
def process_video():
    if 'video' not in request.files:
        return jsonify({'error': 'No video uploaded'}), 400
    
    file = request.files['video']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
    if file:
        filename = secure_filename(file.filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)
        
        # Create a processed video file with the same name in the processed folder
        processed_filename = 'processed_' + filename
        processed_path = os.path.join(app.config['PROCESSED_FOLDER'], processed_filename)
        
        # Process the video
        cap = cv2.VideoCapture(filepath)
        
        # Get video properties
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        fps = cap.get(cv2.CAP_PROP_FPS)
        
        # Create VideoWriter object
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        out = cv2.VideoWriter(processed_path, fourcc, fps, (width, height))
        
        # Process each frame
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
                
            # Process the frame
            frame, detection = process_frame(frame)
            out.write(frame)
        
        # Release resources
        cap.release()
        out.release()
        
        # Also save a preview image from the first frame
        cap = cv2.VideoCapture(filepath)
        ret, frame = cap.read()
        if ret:
            preview_filename = filename.rsplit('.', 1)[0] + '_preview.jpg'
            preview_path = os.path.join(app.config['UPLOAD_FOLDER'], preview_filename)
            frame = process_frame(frame)[0]
            cv2.imwrite(preview_path, frame)
            cap.release()
        
        return jsonify({
            'success': True,
            'original_path': filepath,
            'processed_path': processed_path,
            'processed_video': processed_filename,
            'preview_path': preview_path if ret else None
        })

@app.route('/download_video/<filename>')
def download_video(filename):
    processed_path = os.path.join(app.config['PROCESSED_FOLDER'], filename)
    if os.path.exists(processed_path):
        return send_file(processed_path, as_attachment=True)
    return jsonify({'error': 'File not found'}), 404

@app.route('/download_photo/<filename>')
def download_photo(filename):
    processed_path = os.path.join(app.config['PROCESSED_PHOTOS_FOLDER'], filename)
    if os.path.exists(processed_path):
        return send_file(processed_path, as_attachment=True)
    return jsonify({'error': 'File not found'}), 404

@app.route('/processed_videos/<filename>')
def serve_processed_video(filename):
    processed_path = os.path.join(app.config['PROCESSED_FOLDER'], filename)
    if os.path.exists(processed_path):
        # Determine the MIME type based on the file extension
        video_mime_types = {
            'mp4': 'video/mp4',
            'avi': 'video/x-msvideo',
            'mov': 'video/quicktime',
            'webm': 'video/webm'
        }
        
        # Get file extension
        file_ext = filename.rsplit('.', 1)[1].lower() if '.' in filename else 'mp4'
        mimetype = video_mime_types.get(file_ext, 'video/mp4')
        
        # Return the file with proper MIME type and headers for streaming
        response = send_file(
            processed_path,
            mimetype=mimetype,
            as_attachment=False,
            conditional=True
        )
        
        # Add headers to help with streaming
        response.headers['Accept-Ranges'] = 'bytes'
        response.headers['Cache-Control'] = 'public, max-age=3600'
        
        return response
    return jsonify({'error': 'File not found'}), 404

@app.route('/processed_photos/<filename>')
def serve_processed_photo(filename):
    processed_path = os.path.join(app.config['PROCESSED_PHOTOS_FOLDER'], filename)
    if os.path.exists(processed_path):
        return send_file(processed_path)
    return jsonify({'error': 'File not found'}), 404

@app.route('/get_logs')
def get_logs():
    # Ensure each detection has the required fields for the mobile app
    formatted_logs = []
    for detection in detection_history:
        # Create a copy to avoid modifying the original
        detection_copy = detection.copy()
        
        # Add image_url if not present
        if 'image_path' in detection_copy and 'image_url' not in detection_copy:
            # Get host URL from request
            host_url = request.host_url.rstrip('/')
            image_filename = os.path.basename(detection_copy['image_path'])
            detection_copy['image_url'] = f"{host_url}/view_image/{detection_copy['image_path']}"
        
        # Ensure forCleaning is set (default to true for compatibility)
        if 'forCleaning' not in detection_copy:
            detection_copy['forCleaning'] = True
            
        # Ensure all fields have sensible defaults
        if 'zone_name' not in detection_copy:
            detection_copy['zone_name'] = 'Unknown Zone'
            
        if 'location' not in detection_copy:
            detection_copy['location'] = 'Unknown Location'
            
        if 'camera_id' not in detection_copy:
            detection_copy['camera_id'] = 'camera_0'
            
        formatted_logs.append(detection_copy)
    
    print(f"Returning {len(formatted_logs)} logs")
    # Debug print the first log if available
    if formatted_logs:
        print(f"First log: {formatted_logs[0]}")
        
    # Add Access-Control-Allow-Origin header
    response = jsonify(formatted_logs)
    response.headers.add('Access-Control-Allow-Origin', '*')
    return response

@app.route('/uploads/<path:filename>')
def serve_upload(filename):
    # Determine the appropriate MIME type
    mime_types = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'mp4': 'video/mp4',
        'avi': 'video/x-msvideo',
        'mov': 'video/quicktime'
    }
    
    # Get file extension
    file_ext = filename.rsplit('.', 1)[1].lower() if '.' in filename else ''
    mimetype = mime_types.get(file_ext, 'application/octet-stream')
    
    return send_file(os.path.join(UPLOAD_FOLDER, filename), mimetype=mimetype)

@app.route('/view_image/<path:filename>')
def view_image(filename):
    """Serve any image file from any path."""
    print(f"DEBUG: Request to view image: {filename}")
    
    # Try multiple possible locations for the image
    possible_paths = [
        os.path.join(os.getcwd(), filename),               # Full path as provided
        os.path.join(UPLOAD_FOLDER, filename),             # In uploads folder
        os.path.join(UPLOAD_FOLDER, os.path.basename(filename)),  # Just filename in uploads
        os.path.join(DETECTION_FOLDER, filename),          # In detections folder
        os.path.join(DETECTION_FOLDER, os.path.basename(filename)),  # Just filename in detections
        filename,                                          # Direct path as provided
    ]
    
    print(f"DEBUG: Checking {len(possible_paths)} possible file paths:")
    
    # Find the first path that exists and is a file
    for idx, filepath in enumerate(possible_paths):
        print(f"DEBUG: Path {idx}: {filepath} - {'EXISTS' if os.path.exists(filepath) else 'NOT FOUND'}")
        if os.path.exists(filepath) and os.path.isfile(filepath):
            print(f"DEBUG: Found image at: {filepath}")
            
            # Default to image/jpeg, but try to set a more appropriate MIME type if possible
            mime_types = {
                'jpg': 'image/jpeg',
                'jpeg': 'image/jpeg',
                'png': 'image/png',
                'gif': 'image/gif'
            }
            
            # Get file extension
            file_ext = filepath.rsplit('.', 1)[1].lower() if '.' in filepath else 'jpg'
            mimetype = mime_types.get(file_ext, 'image/jpeg')
            
            return send_file(filepath, mimetype=mimetype)
    
    # If we've checked all paths and found nothing, look for any image file with a similar name
    image_basename = os.path.basename(filename)
    name_part = os.path.splitext(image_basename)[0]  # Get the name without extension
    
    print(f"DEBUG: Looking for any file containing the name part: {name_part}")
    
    for folder in [UPLOAD_FOLDER, DETECTION_FOLDER]:
        if os.path.exists(folder):
            for file in os.listdir(folder):
                if name_part in file and file.lower().endswith(('.jpg', '.jpeg', '.png', '.gif')):
                    filepath = os.path.join(folder, file)
                    print(f"DEBUG: Found similar image: {filepath}")
                    file_ext = filepath.rsplit('.', 1)[1].lower()
                    mimetype = mime_types.get(file_ext, 'image/jpeg')
                    return send_file(filepath, mimetype=mimetype)
    
    # If still no image found, serve a placeholder image instead of 404
    print(f"DEBUG: Image not found in any location, serving placeholder instead")
    placeholder_path = os.path.join('static', 'images', 'placeholder-image.jpg')
    
    # Ensure placeholder exists
    if not os.path.exists(placeholder_path):
        # Create a basic placeholder image
        placeholder_dir = os.path.join('static', 'images')
        os.makedirs(placeholder_dir, exist_ok=True)
        
        placeholder = np.zeros((300, 300, 3), dtype=np.uint8)
        placeholder[:] = (200, 200, 200)  # Gray background
        cv2.putText(placeholder, "No Image", (75, 150), 
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 0), 2)
        cv2.imwrite(placeholder_path, placeholder)
        
    return send_file(placeholder_path, mimetype='image/jpeg')

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/detect', methods=['POST'])
def detect():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400
    
    file = request.files['image']
    # Read image file
    img_bytes = file.read()
    nparr = np.frombuffer(img_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    # Get image dimensions for metadata
    height, width = img.shape[:2]
    
    # Perform object detection
    results = yolo_model(img)
    
    garbage_found = False
    detection_results = []
    
    # Process detection results
    for r in results:
        boxes = r.boxes
        for box in boxes:
            x1, y1, x2, y2 = box.xyxy[0]
            x1, y1, x2, y2 = int(x1), int(y1), int(x2), int(y2)
            
            w, h = x2 - x1, y2 - y1
            
            conf = float(box.conf[0])
            cls = int(box.cls[0])
            
            if conf > 0.3:
                garbage_found = True
                
                # Draw bounding box on the image
                cvzone.cornerRect(img, (x1, y1, w, h), t=2)
                cvzone.putTextRect(img, f'{class_labels[cls]} {conf:.2f}', (x1, y1 - 10), scale=0.8, thickness=1, colorR=(255, 0, 0))
                
                # Add detection result
                detection_results.append({
                    'class': class_labels[cls],
                    'confidence': float(conf),
                    'bbox': [int(x1), int(y1), int(w), int(h)]
                })
    
    # If garbage is detected, save the image and detection metadata
    if garbage_found:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        image_filename = f"{timestamp}.jpg"
        image_path = os.path.join(DETECTION_FOLDER, image_filename)
        cv2.imwrite(image_path, img)
        
        # Create detection entry
        detection_entry = {
            'timestamp': timestamp,
            'image': image_filename,
            'detections': detection_results,
            'cleaned': False,
            'source': request.form.get('source', 'unknown')
        }
        detections.append(detection_entry)
        
        return jsonify({'success': True, 'garbage_detected': True, 'detection': detection_entry})
    
    return jsonify({'success': True, 'garbage_detected': False})

@app.route('/detect_video', methods=['POST'])
def detect_video():
    if 'video' not in request.files:
        return jsonify({'error': 'No video provided'}), 400
    
    # This endpoint would handle video uploads for detection
    # For simplicity, we'll just return a placeholder response
    return jsonify({'message': 'Video detection not implemented yet'})

@app.route('/get_detection_image/<timestamp>', methods=['GET'])
def get_detection_image(timestamp):
    image_path = os.path.join(DETECTION_FOLDER, f"{timestamp}.jpg")
    if os.path.exists(image_path):
        return send_file(image_path, mimetype='image/jpeg')
    return jsonify({'error': 'Image not found'}), 404

@app.route('/webcam_detect', methods=['POST'])
def webcam_detect():
    # This would be called from the website when it wants to start the webcam
    # For now, we'll just return a placeholder
    return jsonify({'message': 'Webcam detection endpoint'})

@app.route('/upload_report', methods=['POST'])
def upload_report():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400
    
    file = request.files['image']
    timestamp = request.form.get('timestamp', datetime.now().strftime("%Y%m%d_%H%M%S"))
    latitude = request.form.get('latitude', 'unknown')
    longitude = request.form.get('longitude', 'unknown')
    
    # Read image file
    img_bytes = file.read()
    nparr = np.frombuffer(img_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    # Save the report image
    report_folder = 'reports'
    if not os.path.exists(report_folder):
        os.makedirs(report_folder)
    
    image_filename = f"report_{timestamp}.jpg"
    image_path = os.path.join(report_folder, image_filename)
    cv2.imwrite(image_path, img)
    
    # Create report entry (you could save this to a database)
    report_entry = {
        'timestamp': timestamp,
        'image': image_filename,
        'latitude': latitude,
        'longitude': longitude,
        'status': 'cleaned'
    }
    
    # You could store reports in a similar structure to detections
    # or in a database for persistence
    print(f"Received report: {report_entry}")
    
    return jsonify({'success': True, 'report': report_entry})

@app.route('/mobile/get_detections')
def mobile_get_detections():
    """API endpoint for mobile app to fetch detection history."""
    # Get detections from database
    all_detections = get_detections_from_db()
    
    # Only return detections marked for cleaning
    cleaning_detections = [d for d in all_detections if d.get('for_cleaning', 1) == 1]
    
    return jsonify({
        'success': True,
        'detections': cleaning_detections
    })

@app.route('/mobile/update_status', methods=['POST'])
def mobile_update_status():
    """API endpoint for mobile app to update detection status."""
    data = request.json
    if not data or 'timestamp' not in data or 'status' not in data:
        return jsonify({'success': False, 'error': 'Invalid request data'}), 400
    
    timestamp = data.get('timestamp')
    status = data.get('status')
    cleaned_by = data.get('cleanedBy')
    notes = data.get('notes')
    
    # Update in database
    success = update_detection_status(timestamp, status, cleaned_by, notes)
    
    return jsonify({'success': success})

@app.route('/mobile/get_zones')
def mobile_get_zones():
    """API endpoint to get all camera zones."""
    return jsonify({
        'success': True,
        'zones': CAMERA_ZONES
    })

@app.route('/mobile/set_camera', methods=['POST'])
def mobile_set_camera():
    """API endpoint to set the current active camera."""
    data = request.json
    if not data or 'camera_id' not in data:
        return jsonify({'success': False, 'error': 'Camera ID is required'}), 400
    
    camera_id = data.get('camera_id')
    if camera_id not in CAMERA_ZONES:
        return jsonify({'success': False, 'error': 'Invalid camera ID'}), 400
    
    global current_camera_id
    current_camera_id = camera_id
    
    return jsonify({'success': True, 'camera_id': current_camera_id})

@app.route('/mobile/report_cleaned', methods=['POST'])
def mobile_report_cleaned():
    """API endpoint for mobile app to report a detection as cleaned."""
    data = request.json
    if not data or 'timestamp' not in data:
        return jsonify({'success': False, 'error': 'Invalid request data'}), 400
    
    timestamp = data.get('timestamp')
    cleaned_by = data.get('cleaned_by', 'Unknown')
    notes = data.get('notes', '')
    
    # Find and update the detection
    updated = False
    for detection in detection_history:
        if detection['timestamp'] == timestamp:
            detection['status'] = 'cleaned'
            detection['cleaned_by'] = cleaned_by
            detection['cleaned_at'] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            detection['notes'] = notes
            updated = True
            break
    
    return jsonify({'success': updated})

# Add a debug endpoint to check if API is reachable
@app.route('/api_check')
def api_check():
    return jsonify({
        'status': 'success',
        'message': 'API is reachable',
        'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        'detection_count': len(detection_history)
    })

# Add a debug endpoint to create a test detection
@app.route('/create_test_detection')
def create_test_detection():
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    
    # Look for existing images in uploads folder
    upload_files = os.listdir(UPLOAD_FOLDER)
    image_files = [f for f in upload_files if f.endswith(('.jpg', '.jpeg', '.png'))]
    
    if not image_files:
        return jsonify({
            'status': 'error',
            'message': 'No image files found in uploads folder'
        }), 400
    
    # Use the first image found
    image_path = f"{UPLOAD_FOLDER}/{image_files[0]}"
    
    # Create a basic detection entry
    detection = {
        'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        'class': 'test_garbage',
        'confidence': 0.95,
        'status': 'pending',
        'image_path': image_path,
        'forCleaning': True,
        'camera_id': 'camera_0',
        'zone_name': 'Test Zone',
        'location': 'Test Location'
    }
    
    # Add to detection history
    detection_history.append(detection)
    
    print(f"Created test detection with image: {image_path}")
    print(f"Detection history now has {len(detection_history)} items")
    
    return jsonify({
        'status': 'success', 
        'message': 'Test detection created',
        'detection': detection
    })

# Add diagnostic endpoint for testing the complete pipeline
@app.route('/debug_api')
def debug_api():
    # Create a test detection if none exist
    if len(detection_history) == 0:
        create_test_detection()
    
    # Get information about API state
    debug_info = {
        'server_info': {
            'flask_version': flask.__version__,
            'server_time': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            'host_url': request.host_url,
            'endpoints': [
                f"{request.host_url}get_logs",
                f"{request.host_url}api_check",
                f"{request.host_url}create_test_detection",
                f"{request.host_url}mobile/get_detections",
            ]
        },
        'detection_history': {
            'count': len(detection_history),
            'sample': detection_history[:1] if detection_history else []
        },
        'file_system': {
            'upload_folder': UPLOAD_FOLDER,
            'upload_folder_exists': os.path.exists(UPLOAD_FOLDER),
            'files_in_upload': os.listdir(UPLOAD_FOLDER)[:5] if os.path.exists(UPLOAD_FOLDER) else []
        },
        'api_test': {
            'get_logs_format': json.loads(get_logs().get_data(as_text=True))[:1] if detection_history else [],
            'mobile_get_detections': json.loads(mobile_get_detections().get_data(as_text=True))
        }
    }
    
    # Print diagnostic info to server console
    print("======================= DEBUG API REPORT =======================")
    print(f"Server URL: {request.host_url}")
    print(f"Detection count: {len(detection_history)}")
    if detection_history:
        print(f"First detection: {detection_history[0]}")
    print("================================================================")
    
    response = jsonify(debug_info)
    response.headers.add('Access-Control-Allow-Origin', '*')
    return response

# Force populate detection history with test data
@app.route('/populate_test_data')
def populate_test_data():
    # Clear existing detection history
    global detection_history
    detection_history = []
    
    # Find image files in uploads
    upload_files = os.listdir(UPLOAD_FOLDER)
    image_files = [f for f in upload_files if f.endswith(('.jpg', '.jpeg', '.png'))]
    
    if not image_files:
        return jsonify({
            'status': 'error',
            'message': 'No image files found in uploads folder'
        }), 400
    
    # Create 5 test detections with different timestamps
    for i in range(5):
        image_path = f"{UPLOAD_FOLDER}/{image_files[i % len(image_files)]}"
        timestamp = (datetime.now() - timedelta(minutes=i*5)).strftime("%Y-%m-%d %H:%M:%S")
        
        detection = {
            'timestamp': timestamp,
            'class': f'test_garbage_{i+1}',
            'confidence': 0.95 - (i * 0.05),
            'status': 'pending',
            'image_path': image_path,
            'forCleaning': True,
            'camera_id': 'camera_0',
            'zone_name': f'Test Zone {i+1}',
            'location': f'Test Location {i+1}'
        }
        
        detection_history.append(detection)
    
    print(f"Populated {len(detection_history)} test detections")
    
    # Return success and the data
    return jsonify({
        'status': 'success',
        'message': f'Created {len(detection_history)} test detections',
        'detections': detection_history
    })

@app.route('/ping')
def ping_test():
    """Simple page to test if server is accessible from mobile devices"""
    return send_from_directory('static', 'ping_test.html')

# Add a lightweight API endpoint for mobile devices with slow connections
@app.route('/mobile_minimal')
def mobile_minimal():
    """Returns minimal data for mobile testing"""
    # Create a single test detection if none exist
    if len(detection_history) == 0:
        create_test_detection()
    
    # Get only the essential data from the first few detections
    minimal_data = []
    for i, detection in enumerate(detection_history[:3]):  # Just take first 3
        # Create a minimal version with only essential fields
        minimal_detection = {
            'timestamp': detection['timestamp'],
            'class': detection['class'],
            'confidence': detection['confidence'],
            'status': detection['status'],
            'zone_name': detection.get('zone_name', 'Unknown Zone'),
            'location': detection.get('location', 'Unknown Location')
        }
        minimal_data.append(minimal_detection)
    
    response = jsonify({
        'success': True,
        'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S"), 
        'detection_count': len(detection_history),
        'minimal_detections': minimal_data
    })
    response.headers.add('Access-Control-Allow-Origin', '*')
    return response

# Add a restart endpoint for troubleshooting
@app.route('/restart')
def restart():
    """Restart the detection history and reset state"""
    global detection_history
    detection_history = []
    
    # Add a sample detection
    detection = {
        'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        'class': 'test_restart',
        'confidence': 0.99,
        'status': 'pending',
        'forCleaning': True,
        'camera_id': 'camera_0',
        'zone_name': 'Restart Zone',
        'location': 'Test Location'
    }
    
    # Find an image to use
    upload_files = os.listdir(UPLOAD_FOLDER)
    image_files = [f for f in upload_files if f.endswith(('.jpg', '.jpeg', '.png'))]
    
    if image_files:
        detection['image_path'] = f"{UPLOAD_FOLDER}/{image_files[0]}"
    else:
        detection['image_path'] = "uploads/placeholder.jpg"
    
    # Add to detection history
    detection_history.append(detection)
    
    # Ensure defaults directory exists
    if not os.path.exists('static/images'):
        os.makedirs('static/images')
    
    # Create a placeholder image if needed
    placeholder_path = 'static/images/placeholder-image.jpg'
    if not os.path.exists(placeholder_path):
        # If no placeholder exists, copy an existing image or create a basic one
        if image_files:
            source_img = cv2.imread(os.path.join(UPLOAD_FOLDER, image_files[0]))
            cv2.imwrite(placeholder_path, source_img)
        else:
            # Create a basic placeholder image
            placeholder = np.zeros((300, 300, 3), dtype=np.uint8)
            placeholder[:] = (200, 200, 200)  # Gray background
            cv2.putText(placeholder, "Placeholder", (75, 150), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 0), 2)
            cv2.imwrite(placeholder_path, placeholder)
    
    return jsonify({
        'success': True,
        'message': 'Server state reset',
        'detection_count': len(detection_history),
        'placeholder_created': os.path.exists(placeholder_path)
    })

# Initialize SQLite database
def init_db():
    """Initialize the SQLite database and create tables if they don't exist"""
    conn = None
    try:
        conn = sqlite3.connect('detections.db')
        cursor = conn.cursor()
        
        # Create detections table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS detections (
            timestamp TEXT PRIMARY KEY,
            class TEXT,
            confidence REAL,
            status TEXT DEFAULT 'pending',
            image_path TEXT,
            for_cleaning INTEGER DEFAULT 1,
            camera_id TEXT,
            zone_name TEXT,
            location TEXT,
            cleaned_by TEXT,
            cleaned_at TEXT,
            notes TEXT,
            created_at TEXT
        )
        ''')
        
        conn.commit()
        return True
    except Error as e:
        print(f"Error initializing database: {e}")
        return False
    finally:
        if conn:
            conn.close()

# Initialize database on startup
init_db()

# Helper functions for database operations
def get_db_connection():
    """Get a connection to the SQLite database"""
    conn = sqlite3.connect('detections.db')
    conn.row_factory = sqlite3.Row  # This enables column access by name
    return conn

def save_detection_to_db(detection_data):
    """Save a detection to the database"""
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute('''
        INSERT OR REPLACE INTO detections (
            timestamp, class, confidence, status, image_path, 
            for_cleaning, camera_id, zone_name, location, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            detection_data.get('timestamp', datetime.now().isoformat()),
            detection_data.get('class', 'unknown'),
            detection_data.get('confidence', 0.0),
            detection_data.get('status', 'pending'),
            detection_data.get('image_path', ''),
            detection_data.get('forCleaning', 1),
            detection_data.get('camera_id', 'unknown'),
            detection_data.get('zone_name', 'Unknown Zone'),
            detection_data.get('location', 'Unknown Location'),
            datetime.now().isoformat()
        ))
        conn.commit()
        return True
    except Error as e:
        print(f"Error saving detection to database: {e}")
        return False
    finally:
        conn.close()

def get_detections_from_db():
    """Get all detections from the database"""
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute('SELECT * FROM detections ORDER BY timestamp DESC')
        rows = cursor.fetchall()
        
        # Convert rows to dictionaries
        detections = []
        for row in rows:
            detection = dict(row)
            # Add image_url for Flutter app
            if detection['image_path']:
                host_url = request.host_url.rstrip('/')
                detection['image_url'] = f"{host_url}/view_image/{detection['image_path']}"
            detections.append(detection)
        
        return detections
    except Error as e:
        print(f"Error retrieving detections from database: {e}")
        return []
    finally:
        conn.close()

def update_detection_status(timestamp, status, cleaned_by=None, notes=None):
    """Update the status of a detection"""
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        
        if status == 'cleaned':
            # If marking as cleaned, update cleaned_by, cleaned_at and notes
            cursor.execute('''
            UPDATE detections 
            SET status = ?, cleaned_by = ?, cleaned_at = ?, notes = ?
            WHERE timestamp = ?
            ''', (status, cleaned_by, datetime.now().isoformat(), notes, timestamp))
        else:
            # Just update the status
            cursor.execute('UPDATE detections SET status = ? WHERE timestamp = ?', 
                           (status, timestamp))
        
        conn.commit()
        return cursor.rowcount > 0
    except Error as e:
        print(f"Error updating detection status: {e}")
        return False
    finally:
        conn.close()

# New Flask API endpoints for the mobile app
@app.route('/api/detections', methods=['GET'])
def api_get_detections():
    """API endpoint to get all detections"""
    detections = get_detections_from_db()
    return jsonify({
        'success': True,
        'detections': detections
    })

@app.route('/api/detections', methods=['POST'])
def api_add_detection():
    """API endpoint to add a new detection"""
    try:
        data = request.json
        if not data:
            return jsonify({'success': False, 'error': 'No data provided'}), 400
        
        # Add to detection_history for backward compatibility
        detection_history.append(data)
        
        # Save to database
        success = save_detection_to_db(data)
        
        return jsonify({
            'success': success,
            'message': 'Detection added successfully' if success else 'Failed to add detection'
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/detections/<timestamp>', methods=['PUT', 'PATCH'])
def api_update_detection(timestamp):
    """API endpoint to update a detection status"""
    try:
        data = request.json
        if not data:
            return jsonify({'success': False, 'error': 'No data provided'}), 400
        
        status = data.get('status')
        if not status:
            return jsonify({'success': False, 'error': 'Status field is required'}), 400
        
        # Update in detection_history for backward compatibility
        for detection in detection_history:
            if detection.get('timestamp') == timestamp:
                detection['status'] = status
                if status == 'cleaned':
                    detection['cleaned_by'] = data.get('cleanedBy')
                    detection['cleaned_at'] = datetime.now().isoformat()
                    detection['notes'] = data.get('notes')
                break
        
        # Update in database
        success = update_detection_status(
            timestamp, 
            status, 
            data.get('cleanedBy'), 
            data.get('notes')
        )
        
        return jsonify({
            'success': success,
            'message': 'Detection updated successfully' if success else 'Failed to update detection'
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/sample_data')
def add_sample_data():
    """Add sample detections to the database"""
    # Sample detections data
    sample_detections = [
        {
            'timestamp': datetime.now().isoformat(),
            'class': 'Plastic Bottle',
            'confidence': 0.95,
            'status': 'pending',
            'image_path': 'uploads/sample_bottle.jpg',
            'forCleaning': True,
            'camera_id': 'cam-1',
            'zone_name': 'Zone A',
            'location': 'Entrance'
        },
        {
            'timestamp': (datetime.now() - timedelta(hours=2)).isoformat(),
            'class': 'Garbage Bag',
            'confidence': 0.88,
            'status': 'pending',
            'image_path': 'uploads/sample_bag.jpg',
            'forCleaning': True,
            'camera_id': 'cam-2',
            'zone_name': 'Zone B',
            'location': 'Parking Lot'
        },
        {
            'timestamp': (datetime.now() - timedelta(days=1)).isoformat(),
            'class': 'Paper Cup',
            'confidence': 0.77,
            'status': 'cleaned',
            'image_path': 'uploads/sample_cup.jpg',
            'forCleaning': True,
            'camera_id': 'cam-3',
            'zone_name': 'Zone C',
            'location': 'Cafeteria',
            'cleaned_by': 'Maintenance Staff',
            'cleaned_at': (datetime.now() - timedelta(hours=6)).isoformat(),
            'notes': 'Found near the recycle bin'
        }
    ]
    
    # Add sample detections to the database
    for detection in sample_detections:
        save_detection_to_db(detection)
        
    # Also add to detection_history for backward compatibility
    detection_history.extend(sample_detections)
    
    return jsonify({
        'success': True,
        'message': 'Sample detections added to database',
        'count': len(sample_detections)
    })

@app.route('/get_image_base64/<path:filename>')
def get_image_base64(filename):
    """
    Endpoint to get an image as base64 encoded string. This is useful for mobile apps
    where direct image loading may not work consistently.
    
    Args:
        filename: Path to the image file, relative to the server root
        
    Returns:
        JSON with the base64 encoded image data
    """
    try:
        # Try to find the file in various locations
        possible_paths = [
            filename,  # As provided
            os.path.join(UPLOAD_FOLDER, filename),  # In uploads folder
            os.path.join(DETECTION_FOLDER, filename),  # In detections folder
            os.path.join('static', 'images', filename),  # In static/images
        ]
        
        # Find the first path that exists
        full_path = None
        for path in possible_paths:
            if os.path.exists(path):
                full_path = path
                break
        
        # If none of the paths exist, use a placeholder
        if full_path is None:
            full_path = os.path.join('static', 'images', 'placeholder-image.jpg')
            print(f"Image not found at any location, using placeholder: {full_path}")
        
        # Check if file exists and is readable
        if not os.path.isfile(full_path):
            return jsonify({
                'success': False, 
                'error': f'File not found: {full_path}',
                'possible_paths': possible_paths
            }), 404
            
        # Read the file and encode as base64
        with open(full_path, 'rb') as image_file:
            encoded_image = base64.b64encode(image_file.read()).decode('utf-8')
            
        return jsonify({
            'success': True,
            'image_data': encoded_image,
            'mime_type': 'image/jpeg',  # Assuming JPEG, could be determined from file extension
            'path_used': full_path
        })
        
    except Exception as e:
        print(f"Error serving base64 image: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# Direct uploads access - simple endpoint to serve any file in the uploads folder
@app.route('/uploads-direct/<filename>')
def uploads_direct(filename):
    """Serve a file directly from the uploads folder, no path resolving needed."""
    print(f"DEBUG: Direct uploads access request for: {filename}")
    
    # Look for exact filename match in uploads folder
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    if os.path.exists(filepath) and os.path.isfile(filepath):
        print(f"DEBUG: Serving direct file from uploads: {filepath}")
        return send_file(filepath)
    
    # No exact match, look for similar filename
    if os.path.exists(UPLOAD_FOLDER):
        for file in os.listdir(UPLOAD_FOLDER):
            # Check if this file contains the requested filename (partial match)
            if filename in file and file.lower().endswith(('.jpg', '.jpeg', '.png', '.gif')):
                filepath = os.path.join(UPLOAD_FOLDER, file)
                print(f"DEBUG: Serving similar file from uploads: {filepath}")
                return send_file(filepath)
    
    # If no image found, serve placeholder
    print(f"DEBUG: No file found in uploads for {filename}, serving placeholder")
    placeholder_path = os.path.join('static', 'images', 'placeholder-image.jpg')
    
    # Ensure placeholder exists
    if not os.path.exists(placeholder_path):
        placeholder_dir = os.path.join('static', 'images')
        os.makedirs(placeholder_dir, exist_ok=True)
        
        placeholder = np.zeros((300, 300, 3), dtype=np.uint8)
        placeholder[:] = (200, 200, 200)  # Gray background
        cv2.putText(placeholder, "File Not Found", (60, 130), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 2)
        cv2.putText(placeholder, filename[:20], (60, 170), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 0), 1)
        cv2.imwrite(placeholder_path, placeholder)
        
    return send_file(placeholder_path)

# Simple endpoint that serves images by timestamp
@app.route('/image-by-timestamp/<timestamp>')
def image_by_timestamp(timestamp):
    """Serve an image by its detection timestamp to avoid URL encoding issues."""
    print(f"DEBUG: Request for image by timestamp: {timestamp}")
    
    # Find the detection by timestamp
    detection = None
    for d in detection_history:
        if d.get('timestamp', '') == timestamp:
            detection = d
            break
    
    # If found, get the image path and serve it
    if detection and 'image_path' in detection:
        image_path = detection['image_path']
        print(f"DEBUG: Found image path for timestamp {timestamp}: {image_path}")
        
        # Try to find the file
        possible_paths = [
            image_path,
            os.path.join(os.getcwd(), image_path),
            os.path.join(UPLOAD_FOLDER, os.path.basename(image_path))
        ]
        
        for path in possible_paths:
            if os.path.exists(path) and os.path.isfile(path):
                print(f"DEBUG: Serving image from path: {path}")
                return send_file(path)
    
    # Try to find any image with the timestamp in its name
    for folder in [UPLOAD_FOLDER, DETECTION_FOLDER]:
        if os.path.exists(folder):
            for file in os.listdir(folder):
                # Replace spaces and colons in the timestamp for comparison
                safe_timestamp = timestamp.replace(' ', '_').replace(':', '_')
                if safe_timestamp in file and file.lower().endswith(('.jpg', '.jpeg', '.png', '.gif')):
                    filepath = os.path.join(folder, file)
                    print(f"DEBUG: Found image with matching timestamp: {filepath}")
                    return send_file(filepath)
    
    # If no image found, create and serve a custom placeholder
    print(f"DEBUG: No image found for timestamp {timestamp}, creating custom placeholder")
    
    # Create a custom placeholder with timestamp information
    placeholder_dir = os.path.join('static', 'images')
    os.makedirs(placeholder_dir, exist_ok=True)
    placeholder_path = os.path.join(placeholder_dir, f'placeholder-{timestamp}.jpg')
    
    placeholder = np.zeros((300, 300, 3), dtype=np.uint8)
    placeholder[:] = (200, 200, 200)  # Gray background
    
    # Add text with timestamp
    cv2.putText(placeholder, "Image Not Found", (50, 100), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 2)
    cv2.putText(placeholder, timestamp, (50, 150), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 0), 1)
                
    cv2.imwrite(placeholder_path, placeholder)
    return send_file(placeholder_path, mimetype='image/jpeg')

# Fix URL encoding issues with spaces in filenames
@app.route('/image-direct/<path:filename>')
def image_direct(filename):
    """Serve an image directly, handling URL encoding issues."""
    print(f"DEBUG: Image direct access request: {filename}")
    
    # Normalize the filename to handle URL encoding issues
    # Replace URL-encoded spaces (%20) with actual spaces
    decoded_filename = urllib.parse.unquote(filename)
    print(f"DEBUG: Decoded filename: {decoded_filename}")
    
    # First look in uploads folder with original and decoded filename
    for name in [filename, decoded_filename]:
        # Try uploads folder
        filepath = os.path.join(UPLOAD_FOLDER, name)
        if os.path.exists(filepath) and os.path.isfile(filepath):
            print(f"DEBUG: Serving direct image from uploads: {filepath}")
            return send_file(filepath)
        
        # Try full path
        if os.path.exists(name) and os.path.isfile(name):
            print(f"DEBUG: Serving direct image from full path: {name}")
            return send_file(name)
    
    # If no exact match, try to list the uploads folder and find a similar filename
    if os.path.exists(UPLOAD_FOLDER):
        for file in os.listdir(UPLOAD_FOLDER):
            # Check if the file names are similar (ignoring spaces/underscores/etc)
            clean_file = file.replace(' ', '').replace('_', '').lower()
            clean_filename = filename.replace(' ', '').replace('_', '').lower()
            clean_decoded = decoded_filename.replace(' ', '').replace('_', '').lower()
            
            if (clean_file in clean_filename or clean_filename in clean_file or
                clean_file in clean_decoded or clean_decoded in clean_file):
                filepath = os.path.join(UPLOAD_FOLDER, file)
                print(f"DEBUG: Found similar file (ignoring spaces/underscores): {filepath}")
                return send_file(filepath)
    
    # If no image found, create and serve a custom placeholder
    print(f"DEBUG: No image found for direct access, creating placeholder")
    placeholder_dir = os.path.join('static', 'images')
    os.makedirs(placeholder_dir, exist_ok=True)
    placeholder_path = os.path.join(placeholder_dir, f'placeholder-image-direct.jpg')
    
    placeholder = np.zeros((300, 300, 3), dtype=np.uint8)
    placeholder[:] = (200, 200, 200)  # Gray background
    cv2.putText(placeholder, "File Not Found", (60, 130), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 2)
    cv2.putText(placeholder, filename[:20], (60, 170), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 0), 1)
    cv2.imwrite(placeholder_path, placeholder)
    
    return send_file(placeholder_path, mimetype='image/jpeg')

if __name__ == '__main__':
    # Listen on all interfaces (important for mobile access)
    app.run(host='0.0.0.0', port=8080, debug=True)