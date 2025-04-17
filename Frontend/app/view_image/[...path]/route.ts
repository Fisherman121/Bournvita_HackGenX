import { NextRequest, NextResponse } from 'next/server';

// Flask API URL
const FLASK_API_URL = "http://localhost:8080";

export async function GET(
  request: NextRequest,
  { params }: { params: { path: string[] } }
) {
  try {
    const imagePath = params.path.join("/");
    
    console.log("Image path from request:", imagePath);
    
    // Determine if we need to add a prefix
    let adjustedPath = imagePath;
    if (!imagePath.startsWith('uploads/') && 
        !imagePath.startsWith('detections/') && 
        !imagePath.startsWith('static/') && 
        !imagePath.includes('/')) {
      adjustedPath = `uploads/${imagePath}`;
      console.log("Adjusted path with uploads/ prefix:", adjustedPath);
    }
    
    // Fetch image from Flask API
    console.log("Attempting to fetch image from Flask API:", `http://localhost:8080/${adjustedPath}`);
    
    const response = await fetch(`http://localhost:8080/${adjustedPath}`, {
      cache: "no-store",
    });
    
    if (!response.ok) {
      console.error(`Failed to fetch image (${response.status}): ${adjustedPath}`);
      
      // Try alternate path if initial fetch fails
      if (!adjustedPath.startsWith('uploads/')) {
        const altPath = `uploads/${imagePath}`;
        console.log("Trying alternate path:", altPath);
        
        const altResponse = await fetch(`http://localhost:8080/${altPath}`, {
          cache: "no-store",
        });
        
        if (altResponse.ok) {
          const buffer = await altResponse.arrayBuffer();
          const contentType = altResponse.headers.get("content-type") || "image/jpeg";
          
          return new NextResponse(buffer, {
            headers: {
              "Content-Type": contentType,
              "Cache-Control": "public, max-age=3600",
            },
          });
        } else {
          console.error(`Alternate path also failed (${altResponse.status}): ${altPath}`);
        }
      }
      
      // If all attempts fail, redirect directly to Flask
      console.log("All fetch attempts failed, redirecting to Flask image");
      return NextResponse.redirect(`http://localhost:8080/${adjustedPath}`);
    }
    
    const buffer = await response.arrayBuffer();
    const contentType = response.headers.get("content-type") || "image/jpeg";
    
    console.log("Image fetched successfully:", adjustedPath);
    
    return new NextResponse(buffer, {
      headers: {
        "Content-Type": contentType,
        "Cache-Control": "public, max-age=3600",
      },
    });
  } catch (error) {
    console.error("Error fetching image:", error);
    return NextResponse.json(
      { error: "Failed to fetch image", details: String(error) },
      { status: 500 }
    );
  }
} 