# Garbage Reporting Website

A lightweight, client-side web application that allows users to report garbage or spills in areas without CCTV coverage.

## Overview

This web application serves as a supplementary tool for the main Garbage Detection System. It enables users (students, residents, staff) to manually report garbage, spills, or debris by uploading photos and providing location information. The system automatically captures the user's geolocation (with permission) and stores the reports locally.

## Features

- **Simple Reporting Form**: Easy-to-use interface for submitting garbage reports
- **Photo Upload**: Capture or select photos of garbage/spills
- **Automatic Geolocation**: Uses browser's geolocation API to automatically capture coordinates
- **Manual Location Entry**: Option to manually enter location description
- **Recent Reports View**: Displays recently submitted reports
- **Responsive Design**: Works on mobile devices and desktop browsers
- **Offline Capability**: Stores reports in the browser's localStorage

## Implementation Details

### Technologies Used

- **HTML5**: For structure and form elements
- **CSS3**: For styling and responsive design
- **JavaScript**: For client-side logic and storage
- **localStorage API**: For storing reports on the client side
- **Geolocation API**: For fetching user coordinates

### Storage

The website uses the browser's localStorage to store reports, which means:
- Reports are stored on the user's device
- Reports persist between browser sessions
- Storage has a limited capacity (5-10MB in most browsers)
- Reports are not shared between devices or browsers

In a production environment, this would be connected to a backend server to store reports in a database and integrate with the main Garbage Detection System.

## Deployment

This is a static website that can be deployed to any web server or hosting service.

### Simple Local Deployment

1. Upload all files to a web server or hosting service
2. No build steps or server-side processing required
3. Can be served from any static file server

### Integration with Main System

To integrate with the main Garbage Detection System:

1. Modify the form submission handler in `script.js` to send reports to the backend API
2. Add authentication if required
3. Update the UI to retrieve reports from the server instead of localStorage

Example of sending reports to a server (add to form submission event):

```javascript
// Send report to server
fetch('https://your-api-endpoint/reports', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
    },
    body: JSON.stringify(newReport)
})
.then(response => response.json())
.then(data => {
    console.log('Success:', data);
    // Show success message
})
.catch((error) => {
    console.error('Error:', error);
    // Show error message
});
```

## Customization

The website can be easily customized:

- **Colors**: Edit the CSS variables in the `styles.css` file
- **Branding**: Replace logos and update header/footer in `index.html`
- **Report Types**: Modify the options in the select element in `index.html`
- **Additional Fields**: Add more form fields in `index.html` and update the JavaScript accordingly

## Privacy Considerations

- The application requests geolocation access, which requires user permission
- Photos and location data are stored only on the user's device
- Email addresses are optional and stored only locally
- No data is transmitted to any server in the current implementation

## Future Improvements

- Backend integration for storing reports in a central database
- User authentication to track reporter history
- Admin interface for managing and addressing reports
- Push notifications for report status updates
- Image optimization to reduce storage usage
- Offline-first PWA implementation with service workers 