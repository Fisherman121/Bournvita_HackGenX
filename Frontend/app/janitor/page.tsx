"use client"

import { useEffect, useState } from "react"
import { Camera, CheckCircle2, Clock, FileText, ImageIcon, MapPin, MoreHorizontal, RefreshCw, X } from "lucide-react"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Textarea } from "@/components/ui/textarea"
import { cn } from "@/lib/utils"
import { motion } from "framer-motion"
import Image from "next/image"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog"

// Flask API URL - use relative path to avoid CORS issues
const API_BASE_URL = ""; // Empty string means it will use the same host

// Types for our detection data
interface DetectionLog {
  timestamp: string;
  class: string;
  confidence: number;
  image_path?: string;
  image_url?: string;
  location: string;
  status: string;
  zone_name?: string;
  camera_id?: string;
  forCleaning?: boolean;
  cleaned_by?: string;
  cleaned_at?: string;
  notes?: string;
  images?: string[];
}

// Near the imports, add this utility function
const isBlockedError = (failedSrc: string): boolean => {
  return failedSrc.includes('localhost:8080');
};

export default function JanitorPage() {
  const [tasks, setTasks] = useState<DetectionLog[]>([]);
  const [selectedTask, setSelectedTask] = useState<string | null>(null);
  const [cleanupNotes, setCleanupNotes] = useState<string>("");
  const [afterImage, setAfterImage] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showMap, setShowMap] = useState(false);
  const [mapLocation, setMapLocation] = useState<{name: string; coords: string}>({name: "", coords: ""});

  // Get the selected task data
  const selectedTaskData = selectedTask 
    ? tasks.find((task) => task.timestamp === selectedTask) 
    : null;

  // Format date for display
  const formatDate = (dateString: string) => {
    try {
      const date = new Date(dateString);
      return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    } catch (e) {
      return dateString;
    }
  };

  // Format full date and time
  const formatFullDateTime = (dateString: string) => {
    try {
      const date = new Date(dateString);
      return date.toLocaleString();
    } catch (e) {
      return dateString;
    }
  };

  // Fetch detection logs from the Flask API
  const fetchDetectionLogs = async () => {
    setIsLoading(true);
    setError(null);
    
    try {
      const response = await fetch(`/api/logs`);
      
      if (!response.ok) {
        throw new Error(`Failed to fetch logs: ${response.status} ${response.statusText}`);
      }
      
      const data = await response.json();
      
      // Filter for logs marked for cleaning
      const cleaningTasks = data.filter((log: DetectionLog) => log.forCleaning);
      
      // Debug log to check image paths
      console.log("Fetched detection logs:", cleaningTasks);
      if (cleaningTasks.length > 0) {
        console.log("Sample image path:", cleaningTasks[0].image_path);
        console.log("Sample image URL:", cleaningTasks[0].image_url);
      }
      
      setTasks(cleaningTasks);
    } catch (err) {
      console.error("Error fetching logs:", err);
      setError(err instanceof Error ? err.message : "Failed to fetch logs");
    } finally {
      setIsLoading(false);
    }
  };

  // Update the status of a task
  const updateTaskStatus = async (timestamp: string, status: string) => {
    try {
      const response = await fetch(`/api/update-status`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          timestamp,
          status,
          cleanedBy: "Janitor App",
          notes: cleanupNotes
        }),
      });
      
      if (!response.ok) {
        throw new Error(`Failed to update status: ${response.status} ${response.statusText}`);
      }
      
      // Update local tasks state
      setTasks(tasks.map(task => 
        task.timestamp === timestamp 
          ? { ...task, status, cleaned_by: "Janitor App", cleaned_at: new Date().toISOString(), notes: cleanupNotes } 
          : task
      ));
      
      // Reset form after successful update
      setCleanupNotes("");
      
      // Show success message
      alert(`Task has been marked as ${status}`);
    } catch (err) {
      console.error("Error updating task status:", err);
      alert("Failed to update task status. Please try again.");
    }
  };

  // Handle complete task button click
  const handleCompleteTask = () => {
    if (selectedTask) {
      updateTaskStatus(selectedTask, "cleaned");
  }
  };

  // Handle image upload
  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      const reader = new FileReader();
      
      reader.onload = (loadEvent) => {
        if (loadEvent.target?.result) {
          setAfterImage(loadEvent.target.result as string);
        }
      };
      
      reader.readAsDataURL(file);
    }
  };

  // Load logs when component mounts
  useEffect(() => {
    fetchDetectionLogs();
    
    // Set up an interval to refresh logs every 30 seconds
    const interval = setInterval(fetchDetectionLogs, 30000);
    
    // Clean up interval on component unmount
    return () => clearInterval(interval);
  }, []);

  // Get counts for dashboard stats
  const pendingTasks = tasks.filter(task => task.status === "pending" || !task.status).length;
  const completedTasks = tasks.filter(task => task.status === "cleaned").length;
  const totalTasks = tasks.length;
  
  // Get next task deadline (just using the oldest pending task for demonstration)
  const pendingTasksList = tasks.filter(task => task.status === "pending" || !task.status);
  const nextTask = pendingTasksList.length > 0 ? pendingTasksList[0] : null;

  // Parse location string to extract coordinates
  const parseLocation = (location: string) => {
    // Expected format: "Location Name (12.345, 67.890)"
    // or just "12.345, 67.890"
    if (!location) return null;
    
    try {
      let name = location;
      let coords = "";
      
      // Check if location has coordinates in parentheses
      const match = location.match(/(.+)\s*\(([^)]+)\)/);
      if (match) {
        name = match[1].trim();
        coords = match[2].trim();
      } else if (location.match(/^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$/)) {
        // If location is just coordinates
        coords = location;
        name = "Location";
      } else {
        // Just a name without coordinates
        name = location;
        coords = "";
      }
      
      return { name, coords };
    } catch (e) {
      console.error("Failed to parse location:", e);
      return null;
    }
  };

  // Open map modal with location
  const handleLocationClick = (location: string) => {
    const parsedLocation = parseLocation(location);
    if (!parsedLocation) {
      console.error("Failed to parse location:", location);
      return;
    }
    
    // Set the location info regardless of whether we have coordinates
    setMapLocation(parsedLocation);
    setShowMap(true);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 p-4 md:p-6">
      <header className="mb-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="rounded-full bg-gradient-to-r from-green-600 to-emerald-600 p-1">
              <svg className="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"
                />
              </svg>
            </div>
            <h1 className="text-2xl font-bold text-white">EcoTrack Janitor Portal</h1>
          </div>
          <div className="flex items-center gap-3">
            <Button 
              variant="outline" 
              size="sm" 
              onClick={fetchDetectionLogs} 
              className="bg-gray-800 text-gray-200 border-gray-700"
            >
              <RefreshCw className="h-4 w-4 mr-2" />
              Refresh
            </Button>
            <Avatar>
              <AvatarImage src="/placeholder.svg?height=40&width=40" alt="Janitor" />
              <AvatarFallback className="bg-green-900 text-green-50">JA</AvatarFallback>
            </Avatar>
            <div className="hidden md:block">
              <div className="font-medium text-gray-200">Janitor Account</div>
              <div className="text-xs text-gray-400">janitor@ecotrack.com</div>
            </div>
          </div>
        </div>
      </header>

      <main className="space-y-6">
        <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
          <Card className="bg-gray-900/50 border-gray-800">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-gray-400">Assigned Tasks</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">{pendingTasks}</div>
              <p className="text-xs text-yellow-500">
                {pendingTasks > 0 ? `${pendingTasks} tasks need attention` : "No pending tasks"}
              </p>
            </CardContent>
          </Card>
          <Card className="bg-gray-900/50 border-gray-800">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-gray-400">Completed Today</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">{completedTasks}</div>
              <p className="text-xs text-green-500">
                {completedTasks > 0 ? `${Math.round((completedTasks / totalTasks) * 100)}% completion rate` : "No completed tasks yet"}
              </p>
            </CardContent>
          </Card>
          <Card className="bg-gray-900/50 border-gray-800">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-gray-400">Total Garbage Detected</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">{totalTasks}</div>
              <p className="text-xs text-blue-500">
                {nextTask ? `Next: ${nextTask.location || 'Unknown location'}` : "No tasks in queue"}
              </p>
            </CardContent>
          </Card>
        </div>

        {isLoading && (
          <Card className="bg-gray-900/50 border-gray-800 p-8 text-center">
            <div className="flex flex-col items-center justify-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-500 mb-4"></div>
              <p className="text-gray-300">Loading tasks...</p>
            </div>
          </Card>
        )}

        {error && (
          <Card className="bg-gray-900/50 border-gray-800 p-8 text-center border-red-700">
            <div className="text-red-500 mb-4">
              <svg className="h-12 w-12 mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
            </div>
            <p className="text-red-400 mb-2">Error loading tasks</p>
            <p className="text-gray-400 text-sm mb-4">{error}</p>
            <Button onClick={fetchDetectionLogs} variant="outline" className="bg-gray-800 hover:bg-gray-700 text-gray-200 border-gray-700">
              Try Again
            </Button>
          </Card>
        )}

        {!isLoading && !error && (
        <Tabs defaultValue="active" className="space-y-4">
          <TabsList className="bg-gray-800/50">
            <TabsTrigger
              value="active"
              className="data-[state=active]:bg-green-900/30 data-[state=active]:text-green-500"
            >
              Active Tasks
            </TabsTrigger>
            <TabsTrigger
              value="completed"
              className="data-[state=active]:bg-green-900/30 data-[state=active]:text-green-500"
            >
              Completed Tasks
            </TabsTrigger>
          </TabsList>

          <TabsContent value="active" className="space-y-4">
            <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
              <div className="lg:col-span-1">
                <Card className="bg-gray-900/50 border-gray-800">
                  <CardHeader>
                    <CardTitle>Your Tasks</CardTitle>
                    <CardDescription>Select a task to update</CardDescription>
                  </CardHeader>
                  <CardContent className="p-0">
                      <div className="space-y-2 p-4 max-h-[500px] overflow-y-auto">
                        {tasks.filter(task => task.status !== "cleaned").length > 0 ? (
                          tasks
                            .filter(task => task.status !== "cleaned")
                            .map((task, index) => (
                        <motion.div
                                key={task.timestamp}
                          initial={{ opacity: 0, y: 10 }}
                          animate={{ opacity: 1, y: 0 }}
                          transition={{ duration: 0.2, delay: index * 0.05 }}
                        >
                          <div
                            className={cn(
                              "cursor-pointer rounded-lg border p-3 transition-colors",
                                    selectedTask === task.timestamp
                                ? "border-green-500 bg-green-900/20"
                                : "border-gray-800 bg-gray-800/30 hover:bg-gray-800/50",
                            )}
                                  onClick={() => setSelectedTask(task.timestamp)}
                          >
                            <div className="flex items-center justify-between">
                                    <div className="font-medium text-gray-200">{task.class}</div>
                              <Badge
                                      className="bg-yellow-500/20 text-yellow-500 hover:bg-yellow-500/30"
                                    >
                                      {task.status || "pending"}
                              </Badge>
                            </div>
                            <div className="mt-2 flex items-center gap-1 text-sm text-gray-400">
                              <MapPin className="h-3.5 w-3.5" />
                                    <button 
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        handleLocationClick(task.location || "Unknown location");
                                      }} 
                                      className="text-gray-400 hover:text-blue-400 hover:underline"
                                    >
                                      {task.location || "Unknown location"}
                                    </button>
                            </div>
                            <div className="mt-1 flex items-center gap-1 text-sm text-gray-400">
                              <Clock className="h-3.5 w-3.5" />
                                    <span>Detected: {formatFullDateTime(task.timestamp)}</span>
                            </div>
                            </div>
                              </motion.div>
                            ))
                        ) : (
                          <div className="text-center py-8 text-gray-500">
                            <CheckCircle2 className="h-12 w-12 mx-auto mb-2 text-green-600/50" />
                            <p>No pending tasks!</p>
                            <p className="text-sm mt-1">All tasks have been completed.</p>
                          </div>
                        )}
                    </div>
                  </CardContent>
                </Card>
              </div>

              <div className="lg:col-span-2">
                {selectedTaskData ? (
                  <Card className="bg-gray-900/50 border-gray-800">
                    <CardHeader>
                      <div className="flex items-center justify-between">
                          <CardTitle>Task Details</CardTitle>
                        <Badge
                            className="bg-yellow-500/20 text-yellow-500 hover:bg-yellow-500/30"
                          >
                            {selectedTaskData.status || "pending"}
                        </Badge>
                      </div>
                        <CardDescription>Review and update task information</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-6">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                          <div>
                            <h3 className="text-sm font-medium text-gray-400 mb-2">Detected Garbage</h3>
                            <div className="overflow-hidden rounded-lg border border-gray-800 bg-gray-800/30">
                              {selectedTaskData.image_path || selectedTaskData.image_url ? (
                                <img
                                  src={
                                    selectedTaskData.image_url ? 
                                    selectedTaskData.image_url : 
                                    selectedTaskData.image_path?.startsWith('/') || selectedTaskData.image_path?.startsWith('http') ?
                                    `/view_image/${selectedTaskData.image_path}` :
                                    `/view_image/uploads/${selectedTaskData.image_path || selectedTaskData.image || ''}`
                                  }
                                  alt="Garbage detection"
                                  className="h-56 w-full object-cover"
                                  onError={(e) => {
                                    // Get the current src that failed
                                    const imgElement = e.target as HTMLImageElement;
                                    const failedSrc = imgElement.src;
                                    
                                    console.error("Image failed to load:", {
                                      failedSrc,
                                      imagePath: selectedTaskData.image_path,
                                      imageUrl: selectedTaskData.image_url,
                                      image: selectedTaskData.image
                                    });
                                    
                                    // Check if this is likely a browser blocking issue
                                    if (isBlockedError(failedSrc)) {
                                      console.log("Image appears to be blocked by the browser, trying Next.js route");
                                      // Try our Next.js route which acts as a proxy
                                      const nextJsRoute = `/view_image/${selectedTaskData.image_path || selectedTaskData.image || ''}`;
                                      imgElement.src = nextJsRoute;
                                      
                                      // Set one-time error handler for this attempt
                                      imgElement.onerror = () => {
                                        console.log("Next.js route failed, using placeholder");
                                        imgElement.src = "https://via.placeholder.com/400x300?text=Image+Not+Available";
                                        imgElement.onerror = null; // Prevent further retries
                                      };
                                      return;
                                    }
                                    
                                    // Skip external URL retries if already tried
                                    if (failedSrc.includes('placeholder')) {
                                      return; // Already at fallback image
                                    }
                                    
                                    // Try different paths in sequence if this wasn't a blocking error
                                    if (selectedTaskData.image_path) {
                                      // Use Next.js route instead of direct Flask access
                                      const nextJsRoute = `/view_image/${selectedTaskData.image_path}`;
                                      console.log("Trying Next.js route:", nextJsRoute);
                                      imgElement.src = nextJsRoute;
                                      
                                      // Add fallback handler
                                      imgElement.onerror = () => {
                                        console.log("Next.js route failed, using placeholder");
                                        imgElement.src = "https://via.placeholder.com/400x300?text=Image+Not+Available";
                                        imgElement.onerror = null; // Prevent infinite loop
                                      };
                                      return;
                                    }
                                    
                                    // If image_path doesn't exist but we have image property
                                    if (selectedTaskData.image) {
                                      const nextJsRoute = `/view_image/uploads/${selectedTaskData.image}`;
                                      console.log("Trying Next.js uploads route:", nextJsRoute);
                                      imgElement.src = nextJsRoute;
                                      
                                      imgElement.onerror = () => {
                                        console.log("All attempts failed, using placeholder");
                                        imgElement.src = "https://via.placeholder.com/400x300?text=Image+Not+Available";
                                        imgElement.onerror = null;
                                      };
                                      return;
                                    }
                                    
                                    // Final fallback
                                    imgElement.src = "https://via.placeholder.com/400x300?text=Image+Not+Available";
                                  }}
                                />
                              ) : selectedTaskData.image ? (
                                <img
                                  src={`/view_image/uploads/${selectedTaskData.image}`}
                                  alt="Garbage detection"
                                  className="h-56 w-full object-cover"
                                  onError={(e) => {
                                    // Fallback if image fails to load
                                    (e.target as HTMLImageElement).src = "https://via.placeholder.com/400x300?text=Image+Not+Available";
                                  }}
                                />
                              ) : (
                                <div className="h-56 w-full flex items-center justify-center bg-gray-800">
                                  <ImageIcon className="h-12 w-12 text-gray-600" />
                                </div>
                              )}
                        </div>
                            <div className="mt-2 text-sm">
                              <div className="flex items-center justify-between mb-1">
                                <span className="text-gray-400">Type:</span>
                                <span className="text-gray-200">{selectedTaskData.class}</span>
                      </div>
                              <div className="flex items-center justify-between mb-1">
                                <span className="text-gray-400">Confidence:</span>
                                <span className="text-gray-200">{(selectedTaskData.confidence * 100).toFixed(1)}%</span>
                              </div>
                              <div className="flex items-center justify-between mb-1">
                                <span className="text-gray-400">Location:</span>
                                <button 
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleLocationClick(selectedTaskData.location || "Unknown");
                                  }} 
                                  className="text-gray-200 hover:text-blue-400 hover:underline"
                                >
                                  {selectedTaskData.location || "Unknown"}
                                </button>
                            </div>
                              <div className="flex items-center justify-between">
                                <span className="text-gray-400">Detected:</span>
                                <span className="text-gray-200">{formatFullDateTime(selectedTaskData.timestamp)}</span>
                          </div>
                        </div>
                      </div>

                          <div>
                            <h3 className="text-sm font-medium text-gray-400 mb-2">Cleanup Verification</h3>
                            <div className="space-y-4">
                              <div>
                                <Label htmlFor="cleanup-notes" className="text-gray-300">Cleanup Notes</Label>
                                <Textarea
                                  id="cleanup-notes"
                                  placeholder="Enter details about how the garbage was disposed..."
                                  className="mt-1 bg-gray-800/50 border-gray-700 text-gray-200"
                                  value={cleanupNotes}
                                  onChange={(e) => setCleanupNotes(e.target.value)}
                                />
                      </div>

                              <div>
                                <Label htmlFor="after-image" className="text-gray-300">Upload After Image (Optional)</Label>
                                <div className="mt-1 flex items-center gap-4">
                                  <div
                                    className="h-24 w-24 rounded-md border border-dashed border-gray-700 flex items-center justify-center cursor-pointer hover:bg-gray-800/70 transition-colors"
                                    onClick={() => document.getElementById("after-image-input")?.click()}
                                  >
                              {afterImage ? (
                                      <img src={afterImage} alt="After cleanup" className="h-full w-full object-cover rounded-md" />
                                    ) : (
                                      <Camera className="h-8 w-8 text-gray-600" />
                                    )}
                                </div>
                                  <input
                                    id="after-image-input"
                                  type="file"
                                  accept="image/*"
                                  className="hidden"
                                  onChange={handleImageUpload}
                                />
                                  <div className="text-sm text-gray-400">
                                    {afterImage ? "Image selected. Click to change." : "Click to upload an after image."}
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                    </CardContent>
                      <CardFooter className="flex justify-end space-x-4">
                      <Button
                        variant="outline"
                          className="border-gray-700 text-gray-300 hover:bg-gray-800 hover:text-gray-100"
                          onClick={() => setSelectedTask(null)}
                      >
                          Cancel
                      </Button>
                        <Button
                          className="bg-green-600 text-white hover:bg-green-700"
                          onClick={handleCompleteTask}
                        >
                          <CheckCircle2 className="h-4 w-4 mr-2" />
                          Mark as Cleaned
                        </Button>
                    </CardFooter>
                  </Card>
                ) : (
                    <Card className="bg-gray-900/50 border-gray-800 h-full flex items-center justify-center p-8">
                      <div className="text-center">
                        <div className="rounded-full bg-gray-800/80 p-4 mx-auto mb-4 w-16 h-16 flex items-center justify-center">
                          <FileText className="h-8 w-8 text-gray-500" />
                      </div>
                        <h3 className="text-gray-300 text-lg font-medium mb-2">No Task Selected</h3>
                        <p className="text-gray-500 max-w-md">
                          Select a task from the list to view details and mark it as cleaned.
                        </p>
                    </div>
                  </Card>
                )}
              </div>
            </div>
          </TabsContent>

          <TabsContent value="completed" className="space-y-4">
              <Card className="bg-gray-900/50 border-gray-800">
                <CardHeader>
                  <CardTitle>Completed Tasks</CardTitle>
                  <CardDescription>Tasks you have cleaned up</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4 max-h-[600px] overflow-y-auto">
                    {tasks.filter(task => task.status === "cleaned").length > 0 ? (
                      tasks
                        .filter(task => task.status === "cleaned")
                        .map((task, index) => (
                <motion.div
                            key={task.timestamp}
                            initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                            transition={{ duration: 0.2, delay: index * 0.05 }}
                          >
                            <div className="rounded-lg border border-gray-800 bg-gray-800/30 p-4">
                              <div className="flex items-start gap-4">
                                <div className="h-20 w-20 flex-shrink-0 overflow-hidden rounded-md">
                                  {task.image_url || task.image_path ? (
                                    <img
                                      src={
                                        task.image_url ? 
                                        task.image_url : 
                                        task.image_path?.startsWith('/') || task.image_path?.startsWith('http') ?
                                        `/view_image/${task.image_path}` :
                                        `/view_image/uploads/${task.image_path || task.image || ''}`
                                      }
                                      alt="Garbage detection"
                                      className="h-full w-full object-cover"
                                      onError={(e) => {
                                        // Get the current src that failed
                                        const imgElement = e.target as HTMLImageElement;
                                        const failedSrc = imgElement.src;
                                        
                                        console.error("Completed task image failed to load:", {
                                          failedSrc,
                                          imagePath: task.image_path,
                                          imageUrl: task.image_url,
                                          image: task.image
                                        });
                                        
                                        // Check if this is likely a browser blocking issue
                                        if (isBlockedError(failedSrc)) {
                                          console.log("Image appears to be blocked by the browser, trying Next.js route");
                                          // Try our Next.js route which acts as a proxy
                                          const nextJsRoute = `/view_image/${task.image_path || task.image || ''}`;
                                          imgElement.src = nextJsRoute;
                                          
                                          // Set one-time error handler for this attempt
                                          imgElement.onerror = () => {
                                            console.log("Next.js route failed, using placeholder");
                                            imgElement.src = "https://via.placeholder.com/80?text=No+Image";
                                            imgElement.onerror = null; // Prevent further retries
                                          };
                                          return;
                                        }
                                        
                                        // Skip external URL retries if already tried
                                        if (failedSrc.includes('placeholder')) {
                                          return; // Already at fallback image
                                        }
                                        
                                        // Try different paths in sequence if this wasn't a blocking error
                                        if (task.image_path) {
                                          // Use Next.js route instead of direct Flask access
                                          const nextJsRoute = `/view_image/${task.image_path}`;
                                          console.log("Trying Next.js route:", nextJsRoute);
                                          imgElement.src = nextJsRoute;
                                          
                                          // Add fallback handler
                                          imgElement.onerror = () => {
                                            console.log("Next.js route failed, using placeholder");
                                            imgElement.src = "https://via.placeholder.com/80?text=No+Image";
                                            imgElement.onerror = null; // Prevent infinite loop
                                          };
                                          return;
                                        }
                                        
                                        // If image_path doesn't exist but we have image property
                                        if (task.image) {
                                          const nextJsRoute = `/view_image/uploads/${task.image}`;
                                          console.log("Trying Next.js uploads route:", nextJsRoute);
                                          imgElement.src = nextJsRoute;
                                          
                                          imgElement.onerror = () => {
                                            console.log("All attempts failed, using placeholder");
                                            imgElement.src = "https://via.placeholder.com/80?text=No+Image";
                                            imgElement.onerror = null;
                                          };
                                          return;
                                        }
                                        
                                        // Final fallback
                                        imgElement.src = "https://via.placeholder.com/80?text=No+Image";
                                      }}
                                    />
                                  ) : task.image ? (
                                    <img
                                      src={`/view_image/uploads/${task.image}`}
                                      alt="Garbage detection"
                                      className="h-full w-full object-cover"
                                      onError={(e) => {
                                        (e.target as HTMLImageElement).src = "https://via.placeholder.com/80?text=No+Image";
                                      }}
                                    />
                                  ) : (
                                    <div className="h-full w-full flex items-center justify-center bg-gray-800">
                                      <ImageIcon className="h-8 w-8 text-gray-600" />
                                    </div>
                                  )}
                                </div>
                                <div className="flex-1">
                                  <div className="flex items-center justify-between mb-1">
                                    <div className="font-medium text-gray-200">{task.class}</div>
                                    <Badge className="bg-green-500/20 text-green-500 hover:bg-green-500/30">
                                      Cleaned
                      </Badge>
                    </div>
                                  <div className="text-sm text-gray-400">
                                    <div className="flex items-center gap-1 mb-1">
                                      <MapPin className="h-3.5 w-3.5" />
                                      <button 
                                        onClick={(e) => {
                                          e.stopPropagation();
                                          handleLocationClick(task.location || "Unknown location");
                                        }} 
                                        className="text-gray-400 hover:text-blue-400 hover:underline"
                                      >
                                        {task.location || "Unknown location"}
                                      </button>
                      </div>
                                    <div className="flex items-center gap-1">
                        <Clock className="h-3.5 w-3.5" />
                                      <span>Cleaned: {task.cleaned_at ? formatFullDateTime(task.cleaned_at) : "Unknown"}</span>
                                    </div>
                                  </div>
                                  {task.notes && (
                                    <div className="mt-2 text-sm text-gray-400">
                                      <p className="text-gray-500">Notes:</p>
                                      <p className="text-gray-300">{task.notes}</p>
                                    </div>
                                  )}
                                </div>
                              </div>
                            </div>
                          </motion.div>
                        ))
                    ) : (
                      <div className="text-center py-12 text-gray-500">
                        <div className="rounded-full bg-gray-800/80 p-4 mx-auto mb-4 w-16 h-16 flex items-center justify-center">
                          <CheckCircle2 className="h-8 w-8 text-gray-600" />
                        </div>
                        <h3 className="text-gray-400 font-medium mb-1">No Completed Tasks</h3>
                        <p className="text-gray-500">You haven't completed any tasks yet.</p>
                      </div>
                    )}
                      </div>
                    </CardContent>
                  </Card>
          </TabsContent>
        </Tabs>
        )}
      </main>

      {/* Map Dialog */}
      <Dialog open={showMap} onOpenChange={setShowMap}>
        <DialogContent className="sm:max-w-[800px] max-h-[90vh]">
          <DialogHeader>
            <DialogTitle>Location: {mapLocation.name}</DialogTitle>
            {mapLocation.coords && (
              <DialogDescription>
                Coordinates: {mapLocation.coords}
              </DialogDescription>
            )}
          </DialogHeader>
          {mapLocation.coords ? (
            <div className="h-[500px] w-full border border-gray-800 rounded-md overflow-hidden">
              <iframe 
                title="Location Map"
                className="w-full h-full"
                src={`https://www.openstreetmap.org/export/embed.html?bbox=${
                  parseFloat(mapLocation.coords.split(',')[1]) - 0.01},${
                  parseFloat(mapLocation.coords.split(',')[0]) - 0.01},${
                  parseFloat(mapLocation.coords.split(',')[1]) + 0.01},${
                  parseFloat(mapLocation.coords.split(',')[0]) + 0.01
                }&layer=mapnik&marker=${
                  mapLocation.coords.split(',')[0]},${
                  mapLocation.coords.split(',')[1]
                }`}
                allowFullScreen
              />
            </div>
          ) : (
            <div className="h-[200px] w-full flex items-center justify-center border border-gray-800 rounded-md bg-gray-900">
              <div className="text-center p-6">
                <MapPin className="h-12 w-12 text-gray-600 mx-auto mb-4" />
                <p className="text-gray-400">No coordinates available for this location.</p>
                <p className="text-sm text-gray-500 mt-2">The location "{mapLocation.name}" doesn't have precise coordinates for map display.</p>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}
