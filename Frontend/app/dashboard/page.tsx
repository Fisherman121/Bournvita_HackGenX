"use client"

import { useState, useEffect } from "react"
import { motion } from "framer-motion"
import { Filter, MoreHorizontal, Search, X, MapPin, Calendar, User, BarChart2, CheckCircle } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card"
import { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem } from "@/components/ui/dropdown-menu"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { cn } from "@/lib/utils"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"

// Define the types for our detection data
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

// Add a new function to parse location coordinates
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

// Add a new interface for staff members
interface StaffMember {
  id: string;
  name: string;
  role: string;
  available: boolean;
}

// Mock data for staff members - in a real app, this would come from the API
const staffMembers: StaffMember[] = [
  { id: "1", name: "John Doe", role: "Janitor", available: true },
  { id: "2", name: "Jane Smith", role: "Cleaner", available: true },
  { id: "3", name: "Mike Johnson", role: "Supervisor", available: false },
  { id: "4", name: "Sarah Williams", role: "Janitor", available: true },
];

export default function DashboardPage() {
  const [logs, setLogs] = useState<DetectionLog[]>([]);
  const [filter, setFilter] = useState("all")
  const [searchQuery, setSearchQuery] = useState("")
  const [isMapFullScreen, setIsMapFullScreen] = useState(false)
  const [selectedLog, setSelectedLog] = useState<DetectionLog | null>(null)
  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false)
  const [isReassignModalOpen, setIsReassignModalOpen] = useState(false)
  const [selectedTaskId, setSelectedTaskId] = useState("")
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  
  // New state variables for enhanced functionality
  const [mapLocation, setMapLocation] = useState<{name: string; coords: string} | null>(null)
  const [showMap, setShowMap] = useState(false)
  const [selectedStaff, setSelectedStaff] = useState<string>("")
  const [assignmentNote, setAssignmentNote] = useState<string>("")
  const [detectionsByType, setDetectionsByType] = useState<Record<string, number>>({})
  const [detectionsByZone, setDetectionsByZone] = useState<Record<string, number>>({})

  // Calculate statistics for reports and analytics
  const calculateStatistics = (logsData: DetectionLog[]) => {
    // Calculate detections by type
    const byType: Record<string, number> = {};
    logsData.forEach(log => {
      const type = log.class || "Unknown";
      byType[type] = (byType[type] || 0) + 1;
    });
    setDetectionsByType(byType);
    
    // Calculate detections by zone
    const byZone: Record<string, number> = {};
    logsData.forEach(log => {
      const zone = log.zone_name || "Unknown Zone";
      byZone[zone] = (byZone[zone] || 0) + 1;
    });
    setDetectionsByZone(byZone);
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
      
      // Debug log
      console.log("Fetched all detection logs:", data);
      
      setLogs(data);
      
      // Calculate statistics for real-time analytics
      calculateStatistics(data);
    } catch (err) {
      console.error("Error fetching logs:", err);
      setError(err instanceof Error ? err.message : "Failed to fetch logs");
    } finally {
      setIsLoading(false);
    }
  };

  // Update the status of a detection log
  const updateLogStatus = async (timestamp: string, status: string, assignedTo?: string) => {
    try {
      const response = await fetch(`/api/update-status`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          timestamp,
          status,
          cleanedBy: assignedTo || "Admin Dashboard",
          notes: `Status updated to ${status} by admin`
        }),
      });
      
      if (!response.ok) {
        throw new Error(`Failed to update status: ${response.status} ${response.statusText}`);
      }
      
      // Update local logs state
      setLogs(logs.map(log => 
        log.timestamp === timestamp 
          ? { ...log, status, cleaned_by: assignedTo || "Admin Dashboard", cleaned_at: new Date().toISOString() } 
          : log
      ));
      
      // Show success message
      alert(`Log has been marked as ${status}`);
      
      // Refresh the logs
      fetchDetectionLogs();
      
    } catch (err) {
      console.error("Error updating log status:", err);
      alert("Failed to update log status. Please try again.");
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

  const filteredLogs = logs.filter((log) => {
    if (filter !== "all" && log.status && log.status.toLowerCase() !== filter) {
      return false
    }

    if (searchQuery) {
      const query = searchQuery.toLowerCase()
      return (
        log.location.toLowerCase().includes(query) ||
        log.class.toLowerCase().includes(query) ||
        (log.status && log.status.toLowerCase().includes(query))
      )
    }

    return true
  })

  const handleViewDetails = (log: DetectionLog) => {
    setSelectedLog(log)
    setIsDetailsModalOpen(true)
  }

  const handleAssignTask = (log: DetectionLog) => {
    setSelectedLog(log)
    setIsReassignModalOpen(true)
  }

  const handleMarkAsResolved = (log: DetectionLog) => {
    updateLogStatus(log.timestamp, "cleaned");
  }

  // Get counts for dashboard stats
  const pendingLogs = logs.filter(log => !log.status || log.status.toLowerCase() === "pending").length;
  const assignedLogs = logs.filter(log => log.status && log.status.toLowerCase() === "assigned").length;
  const cleanedLogs = logs.filter(log => log.status && log.status.toLowerCase() === "cleaned").length;
  const totalLogs = logs.length;

  // New function to handle showing location on map
  const handleShowLocation = (location: string) => {
    const parsedLocation = parseLocation(location);
    if (parsedLocation) {
      setMapLocation(parsedLocation);
      setShowMap(true);
    } else {
      alert("No valid location coordinates found");
    }
  };
  
  // New function to handle assigning a task
  const handleAssignSubmit = () => {
    if (!selectedLog || !selectedStaff) {
      alert("Please select a staff member");
      return;
    }
    
    // Call API to update the log status
    updateLogStatus(selectedLog.timestamp, "assigned", staffMembers.find(s => s.id === selectedStaff)?.name);
    
    // Reset and close modal
    setSelectedStaff("");
    setAssignmentNote("");
    setIsReassignModalOpen(false);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-white">Dashboard</h1>
          <p className="text-gray-400">Monitor and manage garbage detection in real-time.</p>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row">
          <div className="relative">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-gray-500" />
            <Input
              type="search"
              placeholder="Search logs..."
              className="w-full bg-gray-800/50 pl-9 text-gray-200 focus-visible:ring-green-500 sm:w-[200px] md:w-[260px]"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <Select value={filter} onValueChange={setFilter}>
            <SelectTrigger className="w-full bg-gray-800/50 text-gray-200 focus:ring-green-500 sm:w-[150px]">
              <div className="flex items-center gap-2">
                <Filter className="h-4 w-4" />
                <SelectValue placeholder="Filter" />
              </div>
            </SelectTrigger>
            <SelectContent className="bg-gray-900 border-gray-800">
              <SelectItem value="all" className="text-gray-200">
                All Status
              </SelectItem>
              <SelectItem value="pending" className="text-gray-200">
                Pending
              </SelectItem>
              <SelectItem value="assigned" className="text-gray-200">
                Assigned
              </SelectItem>
              <SelectItem value="cleaned" className="text-gray-200">
                Cleaned
              </SelectItem>
            </SelectContent>
          </Select>
          <Button 
            variant="outline" 
            onClick={fetchDetectionLogs} 
            className="bg-gray-800/50 text-gray-200 border-gray-700 hover:bg-gray-700"
          >
            Refresh
          </Button>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card className="bg-gray-800/50 border-gray-700">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-gray-400">Total Detections</CardTitle>
          </CardHeader>
          <div className="p-4 text-2xl font-bold text-white">{totalLogs}</div>
        </Card>
        <Card className="bg-gray-800/50 border-gray-700">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-gray-400">Pending Tasks</CardTitle>
          </CardHeader>
          <div className="p-4 text-2xl font-bold text-yellow-400">
            {pendingLogs}
          </div>
        </Card>
        <Card className="bg-gray-800/50 border-gray-700">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-gray-400">Assigned Tasks</CardTitle>
          </CardHeader>
          <div className="p-4 text-2xl font-bold text-blue-400">
            {assignedLogs}
          </div>
        </Card>
        <Card className="bg-gray-800/50 border-gray-700">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-gray-400">Cleaned Tasks</CardTitle>
          </CardHeader>
          <div className="p-4 text-2xl font-bold text-green-400">
            {cleanedLogs}
          </div>
        </Card>
      </div>

      {isLoading && (
        <div className="flex items-center justify-center p-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-500"></div>
          <span className="ml-3 text-gray-400">Loading data...</span>
        </div>
      )}

      {error && (
        <div className="bg-red-900/20 border border-red-700 text-red-400 p-4 rounded-lg">
          <h3 className="font-semibold mb-2">Error Loading Data</h3>
          <p>{error}</p>
        </div>
      )}

      {!isLoading && !error && (
        <div className="rounded-lg border border-gray-700 bg-gray-800/50">
          <div className="p-6">
            <h2 className="text-xl font-semibold text-white mb-6">Garbage Detection Logs</h2>
            <div className="overflow-auto max-h-[800px]">
              <table className="w-full border-collapse">
                <thead>
                  <tr className="border-b border-gray-700">
                    <th className="text-left text-xs font-semibold text-gray-400 py-3 px-4">Image</th>
                    <th className="text-left text-xs font-semibold text-gray-400 py-3 px-4">Type</th>
                    <th className="text-left text-xs font-semibold text-gray-400 py-3 px-4">Location</th>
                    <th className="text-left text-xs font-semibold text-gray-400 py-3 px-4">Time</th>
                    <th className="text-left text-xs font-semibold text-gray-400 py-3 px-4">Status</th>
                    <th className="text-left text-xs font-semibold text-gray-400 py-3 px-4">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-700">
                  {filteredLogs.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="text-center py-8 text-gray-400">
                        No detection logs found matching your criteria
                      </td>
                    </tr>
                  ) : (
                    filteredLogs.map((log, index) => (
                      <motion.tr
                        key={`${log.timestamp}-${log.class}-${index}`}
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.3 }}
                        className="hover:bg-gray-700/50"
                      >
                        <td className="py-4 px-4">
                          <div className="w-16 h-16 rounded-md overflow-hidden bg-gray-700">
                            {log.image_path ? (
                              <img
                                src={`/view_image/${log.image_path}`}
                                alt={`Detected ${log.class}`}
                                className="w-full h-full object-cover"
                                onError={(e) => {
                                  const imgElement = e.target as HTMLImageElement;
                                  imgElement.src = "https://via.placeholder.com/80?text=No+Image";
                                }}
                              />
                            ) : (
                              <div className="w-full h-full flex items-center justify-center text-gray-500">
                                No image
                              </div>
                            )}
                          </div>
                        </td>
                        <td className="py-4 px-4">
                          <div className="font-medium text-white">{log.class}</div>
                          <div className="text-sm text-gray-400">
                            {Math.round(log.confidence * 100)}% confidence
                          </div>
                        </td>
                        <td className="py-4 px-4">
                          <div className="text-gray-200">{log.location}</div>
                          <div className="text-xs text-gray-400">
                            {log.zone_name || "Unknown zone"} • {log.camera_id || "Unknown camera"}
                          </div>
                        </td>
                        <td className="py-4 px-4">
                          <div className="text-gray-200">
                            {new Date(log.timestamp).toLocaleTimeString([], {
                              hour: "2-digit",
                              minute: "2-digit",
                            })}
                          </div>
                          <div className="text-xs text-gray-400">
                            {new Date(log.timestamp).toLocaleDateString()}
                          </div>
                        </td>
                        <td className="py-4 px-4">
                          <Badge
                            className={cn("font-medium", {
                              "bg-yellow-600/20 text-yellow-400 hover:bg-yellow-600/30":
                                !log.status || log.status.toLowerCase() === "pending",
                              "bg-blue-600/20 text-blue-400 hover:bg-blue-600/30":
                                log.status && log.status.toLowerCase() === "assigned",
                              "bg-green-600/20 text-green-400 hover:bg-green-600/30":
                                log.status && log.status.toLowerCase() === "cleaned",
                            })}
                          >
                            {log.status ? log.status.charAt(0).toUpperCase() + log.status.slice(1) : "Pending"}
                          </Badge>
                          {log.cleaned_by && (
                            <div className="text-xs text-gray-400 mt-1">
                              by {log.cleaned_by}
                            </div>
                          )}
                        </td>
                        <td className="py-4 px-4">
                          <div className="flex items-center gap-2">
                            <Button
                              size="sm"
                              variant="ghost"
                              className="h-8 px-2 text-gray-200 hover:text-white hover:bg-gray-700"
                              onClick={() => handleViewDetails(log)}
                            >
                              View
                            </Button>
                            {(!log.status || log.status.toLowerCase() === "pending") && (
                              <Button
                                size="sm"
                                variant="ghost"
                                className="h-8 px-2 text-blue-400 hover:text-blue-300 hover:bg-blue-900/20"
                                onClick={() => handleAssignTask(log)}
                              >
                                Assign
                              </Button>
                            )}
                            {(!log.status || log.status.toLowerCase() !== "cleaned") && (
                              <Button
                                size="sm"
                                variant="ghost"
                                className="h-8 px-2 text-green-400 hover:text-green-300 hover:bg-green-900/20"
                                onClick={() => handleMarkAsResolved(log)}
                              >
                                Mark Cleaned
                              </Button>
                            )}
                          </div>
                        </td>
                      </motion.tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Add Location Map Dialog */}
      <Dialog open={showMap} onOpenChange={setShowMap}>
        <DialogContent className="sm:max-w-[800px] max-h-[90vh]">
          <DialogHeader>
            <DialogTitle>Location: {mapLocation?.name}</DialogTitle>
            <DialogDescription>
              {mapLocation?.coords && `Coordinates: ${mapLocation.coords}`}
            </DialogDescription>
          </DialogHeader>
          <div className="h-[500px] w-full border border-gray-800 rounded-md overflow-hidden">
            {mapLocation?.coords ? (
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
            ) : (
              <div className="h-full w-full flex items-center justify-center bg-gray-900">
                <div className="text-center p-6">
                  <MapPin className="h-12 w-12 text-gray-600 mx-auto mb-4" />
                  <p className="text-gray-400">No coordinates available for this location.</p>
                </div>
              </div>
            )}
          </div>
        </DialogContent>
      </Dialog>
      
      {/* Add View Details Modal */}
      <Dialog open={isDetailsModalOpen} onOpenChange={setIsDetailsModalOpen}>
        <DialogContent className="sm:max-w-[600px]">
          <DialogHeader>
            <DialogTitle>Detection Details</DialogTitle>
            <DialogDescription>
              Complete information about the selected detection
            </DialogDescription>
          </DialogHeader>
          
          {selectedLog && (
            <div className="grid gap-6">
              <div className="flex flex-col sm:flex-row gap-4">
                <div className="w-full sm:w-1/2">
                  {selectedLog.image_path ? (
                    <div className="relative h-[200px] w-full overflow-hidden rounded-md border border-gray-700">
                      <img
                        src={`/view_image/${selectedLog.image_path}`}
                        alt={`Detected ${selectedLog.class}`}
                        className="h-full w-full object-cover"
                        onError={(e) => {
                          const imgElement = e.target as HTMLImageElement;
                          imgElement.src = "https://via.placeholder.com/300x200?text=No+Image";
                        }}
                      />
                    </div>
                  ) : (
                    <div className="flex h-[200px] w-full items-center justify-center rounded-md border border-gray-700 bg-gray-800">
                      <span className="text-gray-500">No image available</span>
                    </div>
                  )}
                </div>
                
                <div className="w-full sm:w-1/2 space-y-3">
                  <div>
                    <h3 className="text-sm font-medium text-gray-400">Detection Type</h3>
                    <p className="text-lg font-semibold text-white">{selectedLog.class}</p>
                  </div>
                  
                  <div>
                    <h3 className="text-sm font-medium text-gray-400">Confidence</h3>
                    <p className="text-lg font-semibold text-white">{Math.round(selectedLog.confidence * 100)}%</p>
                  </div>
                  
                  <div>
                    <h3 className="text-sm font-medium text-gray-400">Status</h3>
                    <Badge
                      className={cn("mt-1 font-medium", {
                        "bg-yellow-600/20 text-yellow-400": !selectedLog.status || selectedLog.status.toLowerCase() === "pending",
                        "bg-blue-600/20 text-blue-400": selectedLog.status && selectedLog.status.toLowerCase() === "assigned",
                        "bg-green-600/20 text-green-400": selectedLog.status && selectedLog.status.toLowerCase() === "cleaned",
                      })}
                    >
                      {selectedLog.status ? selectedLog.status.charAt(0).toUpperCase() + selectedLog.status.slice(1) : "Pending"}
                    </Badge>
                  </div>
                </div>
              </div>
              
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
                <div>
                  <h3 className="text-sm font-medium text-gray-400 mb-1">Location</h3>
                  <div className="flex items-start">
                    <MapPin className="h-5 w-5 text-gray-500 mr-2 mt-0.5" />
                    <div>
                      <p className="text-white">{selectedLog.location}</p>
                      <Button 
                        variant="link" 
                        className="p-0 h-auto text-blue-400 text-sm"
                        onClick={() => handleShowLocation(selectedLog.location)}
                      >
                        View on map
                      </Button>
                    </div>
                  </div>
                </div>
                
                <div>
                  <h3 className="text-sm font-medium text-gray-400 mb-1">Date & Time</h3>
                  <div className="flex items-start">
                    <Calendar className="h-5 w-5 text-gray-500 mr-2 mt-0.5" />
                    <p className="text-white">{new Date(selectedLog.timestamp).toLocaleString()}</p>
                  </div>
                </div>
                
                <div>
                  <h3 className="text-sm font-medium text-gray-400 mb-1">Zone</h3>
                  <p className="text-white">{selectedLog.zone_name || "Unknown zone"}</p>
                </div>
                
                <div>
                  <h3 className="text-sm font-medium text-gray-400 mb-1">Camera ID</h3>
                  <p className="text-white">{selectedLog.camera_id || "Unknown camera"}</p>
                </div>
              </div>
              
              {(selectedLog.status === "cleaned" || selectedLog.status === "assigned") && (
                <div className="pt-2">
                  <h3 className="text-sm font-medium text-gray-400 mb-1">
                    {selectedLog.status === "cleaned" ? "Cleaned by" : "Assigned to"}
                  </h3>
                  <div className="flex items-start">
                    <User className="h-5 w-5 text-gray-500 mr-2 mt-0.5" />
                    <div>
                      <p className="text-white">{selectedLog.cleaned_by || "Unknown"}</p>
                      {selectedLog.cleaned_at && (
                        <p className="text-sm text-gray-400">
                          {selectedLog.status === "cleaned" ? "Cleaned on " : "Assigned on "}
                          {new Date(selectedLog.cleaned_at).toLocaleString()}
                        </p>
                      )}
                    </div>
                  </div>
                </div>
              )}
              
              {selectedLog.notes && (
                <div className="pt-2">
                  <h3 className="text-sm font-medium text-gray-400 mb-1">Notes</h3>
                  <p className="text-white bg-gray-800/50 p-3 rounded-md border border-gray-700">
                    {selectedLog.notes}
                  </p>
                </div>
              )}
            </div>
          )}
          
          <DialogFooter>
            <Button
              onClick={() => setIsDetailsModalOpen(false)}
              className="bg-gray-800 text-white hover:bg-gray-700"
            >
              Close
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
      
      {/* Add Assign Task Modal */}
      <Dialog open={isReassignModalOpen} onOpenChange={setIsReassignModalOpen}>
        <DialogContent className="sm:max-w-[500px]">
          <DialogHeader>
            <DialogTitle>Assign Task</DialogTitle>
            <DialogDescription>
              Assign this task to a staff member for cleaning
            </DialogDescription>
          </DialogHeader>
          
          {selectedLog && (
            <div className="grid gap-4 py-4">
              <div className="flex items-center gap-4">
                <div className="h-16 w-16 overflow-hidden rounded-md">
                  {selectedLog.image_path ? (
                    <img
                      src={`/view_image/${selectedLog.image_path}`}
                      alt={`Detected ${selectedLog.class}`}
                      className="h-full w-full object-cover"
                      onError={(e) => {
                        const imgElement = e.target as HTMLImageElement;
                        imgElement.src = "https://via.placeholder.com/80?text=No+Image";
                      }}
                    />
                  ) : (
                    <div className="flex h-full w-full items-center justify-center bg-gray-800">
                      <span className="text-gray-500">No image</span>
                    </div>
                  )}
                </div>
                <div>
                  <h3 className="font-medium text-white">{selectedLog.class}</h3>
                  <p className="text-sm text-gray-400">{selectedLog.location}</p>
                  <p className="text-xs text-gray-500">
                    {new Date(selectedLog.timestamp).toLocaleString()}
                  </p>
                </div>
              </div>
              
              <div className="grid gap-2">
                <Label htmlFor="staff" className="text-gray-400">
                  Assign to Staff Member
                </Label>
                <Select value={selectedStaff} onValueChange={setSelectedStaff}>
                  <SelectTrigger
                    id="staff"
                    className="w-full bg-gray-800/50 border-gray-700 text-gray-200"
                  >
                    <SelectValue placeholder="Select staff member" />
                  </SelectTrigger>
                  <SelectContent className="bg-gray-900 border-gray-800">
                    {staffMembers.map((staff) => (
                      <SelectItem
                        key={staff.id}
                        value={staff.id}
                        disabled={!staff.available}
                        className="text-gray-200"
                      >
                        {staff.name} - {staff.role}
                        {!staff.available && " (Unavailable)"}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              
              <div className="grid gap-2">
                <Label htmlFor="notes" className="text-gray-400">
                  Assignment Notes
                </Label>
                <Textarea
                  id="notes"
                  placeholder="Add notes or instructions for this assignment"
                  className="bg-gray-800/50 border-gray-700 text-gray-200 resize-none"
                  value={assignmentNote}
                  onChange={(e) => setAssignmentNote(e.target.value)}
                />
              </div>
            </div>
          )}
          
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setIsReassignModalOpen(false)}
              className="bg-gray-800 text-gray-200 border-gray-700"
            >
              Cancel
            </Button>
            <Button 
              onClick={handleAssignSubmit} 
              className="bg-blue-600 text-white hover:bg-blue-700"
            >
              Assign Task
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
      
      {/* Add Real-time Analytics */}
      {!isLoading && !error && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card className="bg-gray-800/50 border-gray-700">
            <CardHeader>
              <CardTitle className="text-lg font-semibold text-white">
                <div className="flex items-center">
                  <BarChart2 className="h-5 w-5 mr-2" /> 
                  Detections by Type
                </div>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {Object.entries(detectionsByType).map(([type, count]) => (
                  <div key={type} className="space-y-1">
                    <div className="flex items-center justify-between">
                      <span className="text-gray-200">{type}</span>
                      <span className="text-gray-400">{count}</span>
                    </div>
                    <div className="h-2 w-full overflow-hidden rounded-full bg-gray-700">
                      <div
                        className="h-full bg-green-600"
                        style={{ width: `${(count / logs.length) * 100}%` }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
          
          <Card className="bg-gray-800/50 border-gray-700">
            <CardHeader>
              <CardTitle className="text-lg font-semibold text-white">
                <div className="flex items-center">
                  <MapPin className="h-5 w-5 mr-2" /> 
                  Detections by Zone
                </div>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {Object.entries(detectionsByZone).map(([zone, count]) => (
                  <div key={zone} className="space-y-1">
                    <div className="flex items-center justify-between">
                      <span className="text-gray-200">{zone}</span>
                      <span className="text-gray-400">{count}</span>
                    </div>
                    <div className="h-2 w-full overflow-hidden rounded-full bg-gray-700">
                      <div
                        className="h-full bg-blue-600"
                        style={{ width: `${(count / logs.length) * 100}%` }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
}
