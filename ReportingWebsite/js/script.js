// DOM Elements
const reportForm = document.getElementById('reportForm');
const photoUpload = document.getElementById('photoUpload');
const photoPreview = document.getElementById('photoPreview');
const getLocationBtn = document.getElementById('getLocationBtn');
const locationText = document.getElementById('locationText');
const latitudeInput = document.getElementById('latitude');
const longitudeInput = document.getElementById('longitude');
const successModal = document.getElementById('successModal');
const closeModalBtn = document.getElementById('closeModal');
const closeModalX = document.querySelector('.close-modal');
const reportIdSpan = document.getElementById('reportId');
const recentReports = document.getElementById('recentReports');

// Initialize storage
const STORAGE_KEY = 'garbage_reports';
let reports = [];

// Load existing reports from local storage
function loadReports() {
    const storedReports = localStorage.getItem(STORAGE_KEY);
    if (storedReports) {
        reports = JSON.parse(storedReports);
        updateRecentReportsList();
    }
}

// Save reports to local storage
function saveReports() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(reports));
}

// Display uploaded photo preview
photoUpload.addEventListener('change', function(event) {
    const file = event.target.files[0];
    if (file) {
        const reader = new FileReader();
        reader.onload = function(e) {
            const img = document.createElement('img');
            img.src = e.target.result;
            photoPreview.innerHTML = '';
            photoPreview.appendChild(img);
        };
        reader.readAsDataURL(file);
    }
});

// Get geolocation
getLocationBtn.addEventListener('click', function() {
    if (navigator.geolocation) {
        locationText.textContent = 'Getting location...';
        navigator.geolocation.getCurrentPosition(
            // Success callback
            function(position) {
                const lat = position.coords.latitude;
                const lng = position.coords.longitude;
                latitudeInput.value = lat;
                longitudeInput.value = lng;
                locationText.textContent = `Location: ${lat.toFixed(6)}, ${lng.toFixed(6)}`;
                
                // Get address from coordinates using reverse geocoding
                reverseGeocode(lat, lng);
            },
            // Error callback
            function(error) {
                console.error('Error getting location:', error);
                locationText.textContent = 'Error getting location. Please try again or enter manually.';
            },
            // Options
            {
                enableHighAccuracy: true,
                timeout: 10000,
                maximumAge: 0
            }
        );
    } else {
        locationText.textContent = 'Geolocation is not supported by your browser.';
    }
});

// Reverse geocoding to get address from coordinates
function reverseGeocode(lat, lng) {
    // Note: In a production environment, you would use a geocoding service API
    // For this example, we'll just display the coordinates
    locationText.textContent = `Location: ${lat.toFixed(6)}, ${lng.toFixed(6)}`;
    
    // If you want to use a service like OpenStreetMap's Nominatim, you'd make a fetch request like:
    /*
    fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}`)
        .then(response => response.json())
        .then(data => {
            if (data.display_name) {
                locationText.textContent = `Location: ${data.display_name}`;
            }
        })
        .catch(error => {
            console.error('Error in reverse geocoding:', error);
        });
    */
}

// Form submission
reportForm.addEventListener('submit', function(event) {
    event.preventDefault();
    
    // Get form values
    const reportType = document.getElementById('reportType').value;
    const description = document.getElementById('description').value;
    const customLocation = document.getElementById('customLocation').value;
    const userEmail = document.getElementById('userEmail').value;
    
    // Validate required fields
    if (!reportType || !description) {
        alert('Please fill in all required fields');
        return;
    }
    
    // Check if photo is provided
    if (!photoUpload.files || !photoUpload.files[0]) {
        alert('Please upload a photo');
        return;
    }
    
    // Check if location is provided
    const hasGeoLocation = latitudeInput.value && longitudeInput.value;
    const hasCustomLocation = customLocation.trim() !== '';
    
    if (!hasGeoLocation && !hasCustomLocation) {
        alert('Please provide a location (either automatically or manually)');
        return;
    }
    
    // Create a new report object
    const newReport = {
        id: generateUniqueId(),
        timestamp: new Date().toISOString(),
        reportType: reportType,
        description: description,
        photo: photoPreview.querySelector('img').src, // Base64 image data
        latitude: latitudeInput.value || null,
        longitude: longitudeInput.value || null,
        customLocation: customLocation || null,
        userEmail: userEmail || null,
        status: 'pending' // initial status
    };
    
    // Add to reports array
    reports.unshift(newReport); // Add to beginning of array
    
    // Limit storage to most recent 50 reports to prevent exceeding local storage limits
    if (reports.length > 50) {
        reports = reports.slice(0, 50);
    }
    
    // Save to storage
    saveReports();
    
    // Update UI
    updateRecentReportsList();
    
    // Show success modal
    reportIdSpan.textContent = newReport.id;
    successModal.style.display = 'flex';
    
    // Reset form
    reportForm.reset();
    photoPreview.innerHTML = '';
    locationText.textContent = 'Location: Not detected yet';
    latitudeInput.value = '';
    longitudeInput.value = '';
});

// Modal close buttons
closeModalBtn.addEventListener('click', function() {
    successModal.style.display = 'none';
});

closeModalX.addEventListener('click', function() {
    successModal.style.display = 'none';
});

// Close modal when clicking outside of it
window.addEventListener('click', function(event) {
    if (event.target === successModal) {
        successModal.style.display = 'none';
    }
});

// Generate a unique ID for reports
function generateUniqueId() {
    // Simple ID generator - in production, use a more robust method
    return 'REP' + Date.now().toString(36) + Math.random().toString(36).substr(2, 5).toUpperCase();
}

// Update the list of recent reports in the UI
function updateRecentReportsList() {
    if (reports.length === 0) {
        recentReports.innerHTML = '<p class="empty-state">No reports yet</p>';
        return;
    }
    
    recentReports.innerHTML = '';
    
    // Display the 10 most recent reports
    const reportsToShow = reports.slice(0, 10);
    
    reportsToShow.forEach(report => {
        const reportItem = document.createElement('div');
        reportItem.className = 'report-item';
        
        // Format date for display
        const reportDate = new Date(report.timestamp);
        const formattedDate = reportDate.toLocaleDateString() + ' ' + reportDate.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
        
        // Create location display text
        let locationDisplay = 'Unknown location';
        if (report.customLocation) {
            locationDisplay = report.customLocation;
        } else if (report.latitude && report.longitude) {
            locationDisplay = `${parseFloat(report.latitude).toFixed(6)}, ${parseFloat(report.longitude).toFixed(6)}`;
        }
        
        // Report type with first letter capitalized
        const reportTypeFormatted = report.reportType.charAt(0).toUpperCase() + report.reportType.slice(1);
        
        reportItem.innerHTML = `
            <img src="${report.photo}" alt="${reportTypeFormatted}" class="report-image">
            <div class="report-details">
                <div class="report-title">${reportTypeFormatted}</div>
                <div class="report-meta">
                    <span>${formattedDate}</span> • 
                    <span>${locationDisplay}</span>
                </div>
                <div class="report-description">${report.description}</div>
            </div>
        `;
        
        recentReports.appendChild(reportItem);
    });
}

// Initialize app
document.addEventListener('DOMContentLoaded', function() {
    loadReports();
}); 