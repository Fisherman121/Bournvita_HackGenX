import { NextRequest, NextResponse } from 'next/server';

// Flask API URL
const FLASK_API_URL = "http://localhost:8080";

export async function POST(request: NextRequest) {
  try {
    // Parse the request body
    const body = await request.json();

    // Log the data being sent for debugging
    console.log('Sending data to Flask API:', body);

    // Forward the request to Flask with proper configuration
    const response = await fetch(`${FLASK_API_URL}/update_status`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
      cache: 'no-store',
      next: { revalidate: 0 }
    });

    // Check if response is OK
    if (!response.ok) {
      throw new Error(`Flask API error: ${response.status} ${response.statusText}`);
    }

    // Get the response data
    const data = await response.json();

    // Return the data
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error updating status in Flask:', error);
    
    // More detailed error response
    return NextResponse.json(
      { 
        error: 'Failed to update status', 
        success: false,
        details: error instanceof Error ? error.message : String(error)
      },
      { status: 500 }
    );
  }
} 