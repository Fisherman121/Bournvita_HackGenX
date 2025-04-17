import { NextResponse } from 'next/server';

// Flask API URL
const FLASK_API_URL = "http://localhost:8080";

export async function GET() {
  try {
    // Try to fetch a simple endpoint from Flask
    const response = await fetch(`${FLASK_API_URL}/ping`, {
      method: 'GET',
      cache: 'no-store',
      next: { revalidate: 0 },
    });

    if (!response.ok) {
      // Try another common endpoint if first one failed
      const fallbackResponse = await fetch(`${FLASK_API_URL}/`, {
        method: 'GET',
        cache: 'no-store',
        next: { revalidate: 0 },
      });

      if (!fallbackResponse.ok) {
        throw new Error(`Flask API not responding correctly: ${fallbackResponse.status} ${fallbackResponse.statusText}`);
      }

      return NextResponse.json({
        success: true,
        message: 'Connected to Flask API via fallback endpoint',
        status: fallbackResponse.status,
      });
    }

    // Get response data
    const data = await response.json();

    return NextResponse.json({
      success: true,
      message: 'Successfully connected to Flask API',
      data: data,
    });
  } catch (error) {
    console.error('Flask API connection test failed:', error);
    
    return NextResponse.json({
      success: false,
      message: 'Failed to connect to Flask API',
      error: error instanceof Error ? error.message : String(error),
      suggestion: 'Make sure the Flask API is running on http://localhost:8080',
    }, { status: 500 });
  }
} 