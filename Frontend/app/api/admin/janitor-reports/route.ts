import { NextRequest, NextResponse } from 'next/server'

// Mock data for demo purposes
// In a real application, this would come from a database
const mockReports = [
  {
    id: "report-001",
    timestamp: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(), // 1 day ago
    location: "North Campus, Building A",
    wasteType: "Plastic",
    severity: "medium",
    description: "Large pile of plastic bottles and containers near the recycling bin. Appears someone dumped their recycling but missed the bin.",
    images: ["/uploads/mockimages/plastic-waste-1.jpg", "/uploads/mockimages/plastic-waste-2.jpg"],
    status: "pending",
    janitorName: "John Doe",
    createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
  },
  {
    id: "report-002",
    timestamp: new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString(), // 2 days ago
    location: "Student Center, East Entrance",
    wasteType: "Glass",
    severity: "high",
    description: "Broken glass bottles scattered across the walkway. Hazard for pedestrians and needs immediate cleanup.",
    images: ["/uploads/mockimages/glass-waste-1.jpg"],
    status: "in-progress",
    janitorName: "Jane Smith",
    createdAt: new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString()
  },
  {
    id: "report-003",
    timestamp: new Date(Date.now() - 72 * 60 * 60 * 1000).toISOString(), // 3 days ago
    location: "West Parking Lot",
    wasteType: "E-waste",
    severity: "low",
    description: "Discarded electronic components (looks like old computer parts) left near garbage bin. Not hazardous but should be properly recycled.",
    images: ["/uploads/mockimages/ewaste-1.jpg", "/uploads/mockimages/ewaste-2.jpg", "/uploads/mockimages/ewaste-3.jpg"],
    status: "resolved",
    janitorName: "Alex Johnson",
    createdAt: new Date(Date.now() - 72 * 60 * 60 * 1000).toISOString()
  },
  {
    id: "report-004",
    timestamp: new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString(), // 12 hours ago
    location: "Library, South Wing",
    wasteType: "Paper",
    severity: "medium",
    description: "Large pile of discarded books and papers. Appears someone cleaned out their locker and left everything on the floor.",
    images: ["/uploads/mockimages/paper-waste-1.jpg"],
    status: "pending",
    janitorName: "Morgan Lee",
    createdAt: new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString()
  },
  {
    id: "report-005",
    timestamp: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(), // 4 hours ago
    location: "Science Building, Room 204",
    wasteType: "Hazardous",
    severity: "critical",
    description: "Spill of unknown chemical in science lab. Room has been evacuated and locked. Requires hazmat-trained personnel for cleanup.",
    images: ["/uploads/mockimages/hazardous-1.jpg", "/uploads/mockimages/hazardous-2.jpg"],
    status: "in-progress",
    janitorName: "Sam Wilson",
    createdAt: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString()
  }
]

// GET handler for retrieving all reports
export async function GET(request: NextRequest) {
  try {
    // In a real app, you would fetch from a database
    // const reports = await fetchReportsFromDatabase()
    
    // Add query parameter handling for filtering
    const { searchParams } = new URL(request.url)
    const status = searchParams.get('status')
    
    let filteredReports = [...mockReports]
    
    // Apply status filter if provided
    if (status) {
      filteredReports = filteredReports.filter(report => report.status === status)
    }
    
    // Sort reports by timestamp (newest first)
    filteredReports.sort((a, b) => 
      new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
    )
    
    return NextResponse.json(filteredReports)
  } catch (error) {
    console.error('Error fetching janitor reports:', error)
    return NextResponse.json(
      { error: 'Failed to retrieve janitor reports' },
      { status: 500 }
    )
  }
} 