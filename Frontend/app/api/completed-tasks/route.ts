import { NextRequest, NextResponse } from 'next/server';

// Mock data for completed tasks
const mockCompletedTasks = [
  {
    id: "task-101",
    timestamp: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
    location: "North Campus, Building A",
    class: "Plastic Waste",
    confidence: 92.5,
    status: "cleaned",
    verified: true,
    beforeImage: "/uploads/mockimages/placeholder.svg",
    afterImage: "/uploads/mockimages/placeholder.svg",
    cleanedAt: new Date(Date.now() - 2.5 * 24 * 60 * 60 * 1000).toISOString(),
    janitorName: "John Doe",
    notes: "Area completely cleaned. All plastic waste removed and properly recycled."
  },
  {
    id: "task-102",
    timestamp: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000).toISOString(),
    location: "Student Center, East Entrance",
    class: "Glass Waste",
    confidence: 88.3,
    status: "cleaned",
    verified: false,
    beforeImage: "/uploads/mockimages/placeholder.svg",
    afterImage: "/uploads/mockimages/placeholder.svg",
    cleanedAt: new Date(Date.now() - 3.8 * 24 * 60 * 60 * 1000).toISOString(),
    janitorName: "Jane Smith",
    notes: "All glass fragments removed. Area is now safe for pedestrians."
  },
  {
    id: "task-103",
    timestamp: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
    location: "Library, Main Entrance",
    class: "Paper Waste",
    confidence: 95.7,
    status: "cleaned",
    verified: true,
    beforeImage: "/uploads/mockimages/placeholder.svg",
    afterImage: "/uploads/mockimages/placeholder.svg",
    cleanedAt: new Date(Date.now() - 1.5 * 24 * 60 * 60 * 1000).toISOString(),
    janitorName: "Alex Johnson",
    notes: "All paper and cardboard collected and sent for recycling."
  },
  {
    id: "task-104",
    timestamp: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
    location: "West Parking Lot",
    class: "General Waste",
    confidence: 91.2,
    status: "cleaned",
    verified: false,
    beforeImage: "/uploads/mockimages/placeholder.svg",
    afterImage: "/uploads/mockimages/placeholder.svg",
    cleanedAt: new Date(Date.now() - 0.7 * 24 * 60 * 60 * 1000).toISOString(),
    janitorName: "Morgan Lee",
    notes: "Area fully cleaned. Several plastic bags and food containers removed."
  },
  {
    id: "task-105",
    timestamp: new Date(Date.now() - 0.5 * 24 * 60 * 60 * 1000).toISOString(),
    location: "Science Building, Room 204",
    class: "E-waste",
    confidence: 97.8,
    status: "cleaned",
    verified: true,
    beforeImage: "/uploads/mockimages/placeholder.svg",
    afterImage: "/uploads/mockimages/placeholder.svg",
    cleanedAt: new Date(Date.now() - 0.3 * 24 * 60 * 60 * 1000).toISOString(),
    janitorName: "Sam Wilson",
    notes: "Electronic waste collected and transported to e-waste recycling point."
  }
];

export async function GET() {
  try {
    // Mock data for completed tasks with placeholder images
    const completedTasks = [
      {
        id: 'task-101',
        title: 'Plastic bottle cleanup',
        description: 'Plastic bottles detected in park area',
        location: '40.7128° N, 74.0060° W',
        status: 'completed',
        priority: 'high',
        assignedTo: 'John Doe',
        createdAt: '2023-10-01T08:30:00Z',
        completedAt: '2023-10-01T10:30:00Z',
        images: ['/uploads/mockimages/placeholder.svg']
      },
      {
        id: 'task-102',
        title: 'Paper waste removal',
        description: 'Paper waste detected near office building',
        location: '34.0522° N, 118.2437° W',
        status: 'completed',
        priority: 'medium',
        assignedTo: 'Jane Smith',
        createdAt: '2023-10-02T12:15:00Z',
        completedAt: '2023-10-02T14:15:00Z',
        images: ['/uploads/mockimages/placeholder.svg']
      },
      {
        id: 'task-103',
        title: 'Glass debris cleanup',
        description: 'Broken glass detected on sidewalk',
        location: '51.5074° N, 0.1278° W',
        status: 'completed',
        priority: 'high',
        assignedTo: 'Robert Johnson',
        createdAt: '2023-10-03T07:45:00Z',
        completedAt: '2023-10-03T09:45:00Z',
        images: ['/uploads/mockimages/placeholder.svg']
      },
      {
        id: 'task-104',
        title: 'Food waste cleanup',
        description: 'Food waste detected in public area',
        location: '35.6762° N, 139.6503° E',
        status: 'completed',
        priority: 'low',
        assignedTo: 'Emily Chen',
        createdAt: '2023-10-04T14:20:00Z',
        completedAt: '2023-10-04T16:20:00Z',
        images: ['/uploads/mockimages/placeholder.svg']
      },
      {
        id: 'task-105',
        title: 'Mixed waste cleanup',
        description: 'Mixed waste detected in residential area',
        location: '19.0760° N, 72.8777° E',
        status: 'completed',
        priority: 'medium',
        assignedTo: 'Rajesh Kumar',
        createdAt: '2023-10-05T09:10:00Z',
        completedAt: '2023-10-05T11:10:00Z',
        images: ['/uploads/mockimages/placeholder.svg']
      }
    ];

    return NextResponse.json(completedTasks);
  } catch (error) {
    console.error('Error fetching completed tasks:', error);
    return NextResponse.json(
      { error: 'Failed to fetch completed tasks' },
      { status: 500 }
    );
  }
} 