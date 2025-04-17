"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import { 
  ClipboardList, 
  CheckCircle, 
  ChevronRight, 
  Clock, 
  Calendar, 
  MapPin, 
  AlertTriangle,
  RotateCw
} from "lucide-react"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { CustomProgress } from "../components/CustomProgress"

// Define types for janitor tasks
interface Task {
  id: string;
  timestamp: string;
  location: string;
  class: string;
  confidence: number;
  status: "pending" | "in-progress" | "completed";
  image_path?: string;
  priority: "low" | "medium" | "high" | "critical";
  assignedAt: string;
}

export default function JanitorDashboard() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [stats, setStats] = useState({
    totalTasks: 0,
    completedTasks: 0,
    pendingTasks: 0,
    inProgressTasks: 0
  })
  
  // Fetch janitor tasks
  const fetchTasks = async () => {
    setIsLoading(true)
    setError(null)
    
    try {
      // In a real app, this would be an API call
      // const response = await fetch('/api/janitor/tasks')
      // const data = await response.json()
      
      // For demo, using mock data
      const mockTasks: Task[] = [
        {
          id: "task-001",
          timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
          location: "North Campus, Building A",
          class: "Plastic Waste",
          confidence: 92.5,
          status: "pending",
          image_path: "/uploads/mockimages/plastic-waste-1.jpg",
          priority: "high",
          assignedAt: new Date(Date.now() - 30 * 60 * 1000).toISOString()
        },
        {
          id: "task-002",
          timestamp: new Date(Date.now() - 5 * 60 * 60 * 1000).toISOString(),
          location: "Student Center, East Entrance",
          class: "Glass Waste",
          confidence: 88.3,
          status: "in-progress",
          image_path: "/uploads/mockimages/glass-waste-1.jpg",
          priority: "medium",
          assignedAt: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString()
        },
        {
          id: "task-003",
          timestamp: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
          location: "Library, Main Entrance",
          class: "Paper Waste",
          confidence: 95.7,
          status: "completed",
          image_path: "/uploads/mockimages/paper-waste-1.jpg",
          priority: "low",
          assignedAt: new Date(Date.now() - 23 * 60 * 60 * 1000).toISOString()
        },
        {
          id: "task-004",
          timestamp: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
          location: "Science Building, Room 204",
          class: "Hazardous Waste",
          confidence: 97.8,
          status: "pending",
          image_path: "/uploads/mockimages/hazardous-1.jpg",
          priority: "critical",
          assignedAt: new Date(Date.now() - 20 * 60 * 1000).toISOString()
        }
      ]
      
      setTasks(mockTasks)
      
      // Calculate stats
      const totalTasks = mockTasks.length
      const completedTasks = mockTasks.filter(task => task.status === "completed").length
      const pendingTasks = mockTasks.filter(task => task.status === "pending").length
      const inProgressTasks = mockTasks.filter(task => task.status === "in-progress").length
      
      setStats({
        totalTasks,
        completedTasks,
        pendingTasks,
        inProgressTasks
      })
      
    } catch (err) {
      console.error("Error fetching tasks:", err)
      setError("Failed to load your tasks. Please try again later.")
    } finally {
      setIsLoading(false)
    }
  }
  
  // Fetch data on component mount
  useEffect(() => {
    fetchTasks()
    
    // Set up auto-refresh every 5 minutes
    const interval = setInterval(fetchTasks, 5 * 60 * 1000)
    
    return () => clearInterval(interval)
  }, [])
  
  // Format time for display
  const formatTime = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  }
  
  // Format date for display
  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString([], { month: 'short', day: 'numeric' })
  }
  
  // Calculate time since assignment
  const getTimeSince = (dateString: string) => {
    const assignedTime = new Date(dateString).getTime()
    const currentTime = Date.now()
    const diffMinutes = Math.floor((currentTime - assignedTime) / (1000 * 60))
    
    if (diffMinutes < 60) {
      return `${diffMinutes} min ago`
    } else if (diffMinutes < 24 * 60) {
      const hours = Math.floor(diffMinutes / 60)
      return `${hours} hour${hours > 1 ? 's' : ''} ago`
    } else {
      const days = Math.floor(diffMinutes / (24 * 60))
      return `${days} day${days > 1 ? 's' : ''} ago`
    }
  }
  
  return (
    <div className="space-y-6 p-6">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-white">Janitor Dashboard</h1>
          <p className="text-gray-400">Manage your assigned tasks and submit reports</p>
        </div>
        
        {/* Add a prominent report button in the header */}
        <Link href="/janitor/report">
          <Button className="bg-green-600 hover:bg-green-500 text-white">
            <ClipboardList className="mr-2 h-4 w-4" />
            Report an Issue
          </Button>
        </Link>
      </div>
      
      {/* Stats Cards */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-4">
        <Card className="bg-gray-900/50 border-gray-800">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-400">Total Tasks</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-white">{stats.totalTasks}</div>
          </CardContent>
        </Card>
        
        <Card className="bg-gray-900/50 border-gray-800">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-400">Completed</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-500">{stats.completedTasks}</div>
          </CardContent>
        </Card>
        
        <Card className="bg-gray-900/50 border-gray-800">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-400">In Progress</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-blue-500">{stats.inProgressTasks}</div>
          </CardContent>
        </Card>
        
        <Card className="bg-gray-900/50 border-gray-800">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-400">Pending</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-yellow-500">{stats.pendingTasks}</div>
          </CardContent>
        </Card>
      </div>
      
      {/* Action Cards - Make Report card more prominent */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <Card className="bg-gray-900/50 border-gray-800 hover:bg-gray-800/70 transition-colors">
          <Link href="/janitor/tasks" className="block p-6">
            <div className="flex items-center gap-4">
              <div className="rounded-full bg-green-500/10 p-3">
                <CheckCircle className="h-6 w-6 text-green-500" />
              </div>
              <div>
                <CardTitle className="text-xl font-semibold">My Tasks</CardTitle>
                <CardDescription>
                  View and manage your assigned cleaning tasks
                </CardDescription>
              </div>
              <ChevronRight className="ml-auto h-5 w-5 text-gray-500" />
            </div>
          </Link>
        </Card>
        
        <Card className="bg-green-900/20 border-green-800 hover:bg-green-800/30 transition-colors shadow-md">
          <Link href="/janitor/report" className="block p-6">
            <div className="flex items-center gap-4">
              <div className="rounded-full bg-amber-500/20 p-3">
                <ClipboardList className="h-6 w-6 text-amber-500" />
              </div>
              <div>
                <CardTitle className="text-xl font-semibold">Submit Report</CardTitle>
                <CardDescription className="text-gray-300">
                  Report waste, hazards or cleanup needs
                </CardDescription>
              </div>
              <div className="ml-auto flex h-8 w-8 items-center justify-center rounded-full bg-green-600 text-white">
                <ChevronRight className="h-5 w-5" />
              </div>
            </div>
          </Link>
        </Card>
      </div>
      
      {/* Recent Tasks */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-white">Recent Tasks</h2>
          <Button 
            variant="outline" 
            size="sm" 
            className="border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white"
            onClick={fetchTasks}
            disabled={isLoading}
          >
            <RotateCw className={`mr-2 h-4 w-4 ${isLoading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
        </div>
        
        {error && (
          <div className="bg-red-900/20 border border-red-700 text-red-400 p-4 rounded-lg mb-4">
            <h3 className="font-semibold mb-2">Error</h3>
            <p>{error}</p>
          </div>
        )}
        
        {isLoading && !error ? (
          <div className="flex items-center justify-center p-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-500"></div>
            <span className="ml-3 text-gray-400">Loading tasks...</span>
          </div>
        ) : tasks.length === 0 ? (
          <div className="flex flex-col items-center justify-center rounded-lg border border-dashed border-gray-700 p-8 text-center">
            <p className="mt-2 text-sm text-gray-400">No tasks assigned yet.</p>
          </div>
        ) : (
          <div className="space-y-4">
            {tasks.map((task) => (
              <Card key={task.id} className="bg-gray-900/50 border-gray-800 overflow-hidden">
                <div className="flex flex-col md:flex-row">
                  <div className="p-4 md:p-6 flex-1">
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center">
                        <Badge
                          className={`mr-2 ${
                            task.priority === "critical"
                              ? "bg-red-500/20 text-red-500"
                              : task.priority === "high"
                              ? "bg-amber-500/20 text-amber-500"
                              : task.priority === "medium"
                              ? "bg-blue-500/20 text-blue-500"
                              : "bg-green-500/20 text-green-500"
                          }`}
                        >
                          {task.priority.charAt(0).toUpperCase() + task.priority.slice(1)} Priority
                        </Badge>
                        <Badge
                          className={`${
                            task.status === "completed"
                              ? "bg-green-500/20 text-green-500"
                              : task.status === "in-progress"
                              ? "bg-blue-500/20 text-blue-500"
                              : "bg-yellow-500/20 text-yellow-500"
                          }`}
                        >
                          {task.status === "completed"
                            ? "Completed"
                            : task.status === "in-progress"
                            ? "In Progress"
                            : "Pending"}
                        </Badge>
                      </div>
                      <div className="text-sm text-gray-400">
                        <Clock className="inline-block mr-1 h-3 w-3" />
                        {getTimeSince(task.assignedAt)}
                      </div>
                    </div>
                    
                    <h3 className="text-lg font-semibold text-white mb-1">{task.class}</h3>
                    
                    <div className="flex items-center text-gray-400 mb-3">
                      <MapPin className="mr-1 h-4 w-4" />
                      <span>{task.location}</span>
                    </div>
                    
                    <div className="flex items-center text-sm text-gray-500">
                      <Calendar className="mr-1 h-4 w-4" />
                      <span>Detected: {formatDate(task.timestamp)} at {formatTime(task.timestamp)}</span>
                    </div>
                  </div>
                  
                  <div className="p-4 md:w-48 flex flex-row md:flex-col justify-end items-center gap-2 border-t md:border-t-0 md:border-l border-gray-800 bg-gray-800/30">
                    {task.status === "pending" && (
                      <Button className="w-full md:w-auto bg-green-600 hover:bg-green-500">
                        Start Task
                      </Button>
                    )}
                    {task.status === "in-progress" && (
                      <Button className="w-full md:w-auto bg-green-600 hover:bg-green-500">
                        Mark Complete
                      </Button>
                    )}
                    <Button variant="outline" className="w-full md:w-auto border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white">
                      View Details
                    </Button>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        )}
        
        {tasks.length > 0 && (
          <div className="mt-4 text-center">
            <Link 
              href="/janitor/tasks"
              className="text-green-500 hover:text-green-400 text-sm font-medium"
            >
              View All Tasks →
            </Link>
          </div>
        )}
      </div>
      
      {/* Progress Overview */}
      <Card className="bg-gray-900/50 border-gray-800">
        <CardHeader>
          <CardTitle>Today's Progress</CardTitle>
          <CardDescription>Your task completion progress</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-6">
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <div className="text-sm text-gray-400">Overall Completion</div>
                <div className="text-sm font-medium text-white">
                  {stats.completedTasks}/{stats.totalTasks} tasks ({Math.round((stats.completedTasks / Math.max(stats.totalTasks, 1)) * 100)}%)
                </div>
              </div>
              <CustomProgress 
                value={(stats.completedTasks / Math.max(stats.totalTasks, 1)) * 100}
                className="h-2 bg-gray-800"
                indicatorColor="var(--green-500)"
              />
            </div>
            
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <div className="text-sm text-gray-400">Critical Tasks</div>
                <div className="text-sm font-medium text-white">
                  {tasks.filter(t => t.priority === "critical" && t.status === "completed").length}/
                  {tasks.filter(t => t.priority === "critical").length} completed
                </div>
              </div>
              <CustomProgress 
                value={(tasks.filter(t => t.priority === "critical" && t.status === "completed").length / 
                       Math.max(tasks.filter(t => t.priority === "critical").length, 1)) * 100}
                className="h-2 bg-gray-800"
                indicatorColor="#ef4444"
              />
            </div>
            
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <div className="text-sm text-gray-400">High Priority Tasks</div>
                <div className="text-sm font-medium text-white">
                  {tasks.filter(t => t.priority === "high" && t.status === "completed").length}/
                  {tasks.filter(t => t.priority === "high").length} completed
                </div>
              </div>
              <CustomProgress 
                value={(tasks.filter(t => t.priority === "high" && t.status === "completed").length / 
                       Math.max(tasks.filter(t => t.priority === "high").length, 1)) * 100}
                className="h-2 bg-gray-800"
                indicatorColor="#f59e0b"
              />
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
} 