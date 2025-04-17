"use client"

import { useState } from "react"
import { Clock, Download, MapPin, X } from "lucide-react"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { cn } from "@/lib/utils"
import { MapVisualization } from "@/components/map-visualization"

interface ViewDetailsModalProps {
  isOpen: boolean
  onClose: () => void
  data: any
  type: "garbage" | "task" | "report"
}

export function ViewDetailsModal({ isOpen, onClose, data, type }: ViewDetailsModalProps) {
  const [activeTab, setActiveTab] = useState("details")
  const [taskStatus, setTaskStatus] = useState(data?.status || "Pending")

  const formatDate = (dateString: string) => {
    if (!dateString) return ""
    const date = new Date(dateString)
    return date.toLocaleString([], {
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    })
  }

  const handleStatusChange = (status: string) => {
    setTaskStatus(status)
    // In a real app, this would update the status in the backend
    alert(`Status updated to ${status}`)
  }

  const handleAssignTask = () => {
    // In a real app, this would open an assignment dialog or perform the assignment
    alert("Task assignment functionality would open here")
  }

  const handleDownloadReport = () => {
    // In a real app, this would download a report
    alert("Report download functionality would trigger here")
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-4xl bg-gray-900 border-gray-800 p-0 text-gray-200">
        <DialogHeader className="p-6 pb-0">
          <div className="flex items-center justify-between">
            <div>
              <DialogTitle className="text-xl text-white">
                {type === "garbage" && "Garbage Detection Details"}
                {type === "task" && "Task Details"}
                {type === "report" && "Report Details"}
              </DialogTitle>
              <DialogDescription className="text-gray-400">
                {data?.id} - {data?.location}
              </DialogDescription>
            </div>
            <Button
              variant="ghost"
              size="icon"
              className="absolute right-4 top-4 h-8 w-8 rounded-full text-gray-400 hover:text-white"
              onClick={onClose}
            >
              <X className="h-4 w-4" />
              <span className="sr-only">Close</span>
            </Button>
          </div>
        </DialogHeader>

        <Tabs value={activeTab} onValueChange={setActiveTab} className="px-6">
          <TabsList className="bg-gray-800/50 mb-4">
            <TabsTrigger
              value="details"
              className="data-[state=active]:bg-green-900/30 data-[state=active]:text-green-500"
            >
              Details
            </TabsTrigger>
            <TabsTrigger
              value="location"
              className="data-[state=active]:bg-green-900/30 data-[state=active]:text-green-500"
            >
              Location
            </TabsTrigger>
            <TabsTrigger
              value="history"
              className="data-[state=active]:bg-green-900/30 data-[state=active]:text-green-500"
            >
              History
            </TabsTrigger>
          </TabsList>

          <TabsContent value="details" className="space-y-4">
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
              <div>
                <div className="overflow-hidden rounded-lg border border-gray-800">
                  <img
                    src={data?.image || "/placeholder.svg?height=300&width=400"}
                    alt={`Image for ${data?.id}`}
                    className="aspect-video w-full object-cover"
                  />
                </div>
                {type === "report" && data?.afterImage && (
                  <div className="mt-2 overflow-hidden rounded-lg border border-gray-800">
                    <img
                      src={data?.afterImage || "/placeholder.svg?height=300&width=400"}
                      alt={`After cleanup for ${data?.id}`}
                      className="aspect-video w-full object-cover"
                    />
                    <div className="bg-gray-800/50 p-2 text-center text-xs text-gray-400">After Cleanup</div>
                  </div>
                )}
              </div>

              <div className="space-y-4">
                <div className="rounded-lg border border-gray-800 bg-gray-800/30 p-4">
                  <h3 className="mb-2 font-medium text-white">Information</h3>
                  <div className="space-y-2">
                    <div className="flex justify-between border-b border-gray-800 pb-2">
                      <span className="text-sm text-gray-400">ID</span>
                      <span className="text-sm font-medium text-gray-200">{data?.id}</span>
                    </div>
                    <div className="flex justify-between border-b border-gray-800 pb-2">
                      <span className="text-sm text-gray-400">Location</span>
                      <span className="text-sm font-medium text-gray-200">{data?.location}</span>
                    </div>
                    <div className="flex justify-between border-b border-gray-800 pb-2">
                      <span className="text-sm text-gray-400">
                        {type === "garbage" && "Detected At"}
                        {type === "task" && "Assigned At"}
                        {type === "report" && "Completed At"}
                      </span>
                      <span className="text-sm font-medium text-gray-200">
                        {formatDate(data?.time || data?.assignedAt || data?.completedAt)}
                      </span>
                    </div>
                    {type === "task" && (
                      <div className="flex justify-between border-b border-gray-800 pb-2">
                        <span className="text-sm text-gray-400">Deadline</span>
                        <span className="text-sm font-medium text-gray-200">{formatDate(data?.deadline)}</span>
                      </div>
                    )}
                    {(type === "task" || type === "report") && (
                      <div className="flex justify-between border-b border-gray-800 pb-2">
                        <span className="text-sm text-gray-400">Assigned To</span>
                        <div className="flex items-center gap-2">
                          <Avatar className="h-5 w-5">
                            <AvatarImage src="/placeholder.svg?height=20&width=20" alt={data?.assignedTo} />
                            <AvatarFallback className="bg-green-900 text-green-50 text-xs">
                              {data?.assignedTo
                                ?.split(" ")
                                .map((n: string) => n[0])
                                .join("")}
                            </AvatarFallback>
                          </Avatar>
                          <span className="text-sm font-medium text-gray-200">{data?.assignedTo}</span>
                        </div>
                      </div>
                    )}
                    <div className="flex justify-between pb-2">
                      <span className="text-sm text-gray-400">Status</span>
                      <Badge
                        className={cn(
                          data?.status === "Pending" && "bg-yellow-500/20 text-yellow-500",
                          data?.status === "Assigned" && "bg-blue-500/20 text-blue-500",
                          data?.status === "In Progress" && "bg-blue-500/20 text-blue-500",
                          data?.status === "Resolved" && "bg-green-500/20 text-green-500",
                          data?.status === "Completed" && "bg-green-500/20 text-green-500",
                          data?.status === "Verified" && "bg-green-500/20 text-green-500",
                          data?.status === "Pending Verification" && "bg-yellow-500/20 text-yellow-500",
                        )}
                      >
                        {data?.status}
                      </Badge>
                    </div>
                  </div>
                </div>

                {type === "task" && (
                  <div className="rounded-lg border border-gray-800 bg-gray-800/30 p-4">
                    <h3 className="mb-2 font-medium text-white">Actions</h3>
                    <div className="space-y-3">
                      <div className="space-y-2">
                        <span className="text-sm text-gray-400">Update Status</span>
                        <Select value={taskStatus} onValueChange={handleStatusChange}>
                          <SelectTrigger className="bg-gray-800/50 border-gray-700 text-gray-200 focus:ring-green-500">
                            <SelectValue placeholder="Select status" />
                          </SelectTrigger>
                          <SelectContent className="bg-gray-900 border-gray-800">
                            <SelectItem value="Pending" className="text-gray-200">
                              Pending
                            </SelectItem>
                            <SelectItem value="In Progress" className="text-gray-200">
                              In Progress
                            </SelectItem>
                            <SelectItem value="Completed" className="text-gray-200">
                              Completed
                            </SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                      <div className="flex gap-2">
                        <Button className="flex-1 bg-blue-600 hover:bg-blue-500 text-white" onClick={handleAssignTask}>
                          Reassign Task
                        </Button>
                        <Button
                          className="flex-1 bg-green-600 hover:bg-green-500 text-white"
                          onClick={() => handleStatusChange("Completed")}
                        >
                          Mark as Done
                        </Button>
                      </div>
                    </div>
                  </div>
                )}

                {type === "report" && (
                  <div className="rounded-lg border border-gray-800 bg-gray-800/30 p-4">
                    <h3 className="mb-2 font-medium text-white">Report Actions</h3>
                    <div className="space-y-3">
                      <Button
                        className="w-full bg-green-600 hover:bg-green-500 text-white"
                        onClick={handleDownloadReport}
                      >
                        <Download className="mr-2 h-4 w-4" />
                        Download Full Report
                      </Button>
                      {data?.status === "Pending Verification" && (
                        <Button
                          className="w-full bg-blue-600 hover:bg-blue-500 text-white"
                          onClick={() => handleStatusChange("Verified")}
                        >
                          Verify Cleanup
                        </Button>
                      )}
                    </div>
                  </div>
                )}
              </div>
            </div>

            {data?.notes && (
              <div className="rounded-lg border border-gray-800 bg-gray-800/30 p-4">
                <h3 className="mb-2 font-medium text-white">Notes</h3>
                <p className="text-sm text-gray-300">{data.notes}</p>
              </div>
            )}
          </TabsContent>

          <TabsContent value="location">
            <div className="space-y-4">
              <div className="flex items-center gap-2">
                <MapPin className="h-5 w-5 text-gray-400" />
                <span className="text-gray-200">{data?.location}</span>
              </div>
              <MapVisualization className="h-[400px]" showSearch={false} />
            </div>
          </TabsContent>

          <TabsContent value="history">
            <div className="space-y-4">
              <div className="rounded-lg border border-gray-800 bg-gray-800/30 p-4">
                <h3 className="mb-2 font-medium text-white">Activity Timeline</h3>
                <div className="space-y-4">
                  {[
                    {
                      action: type === "garbage" ? "Detected" : type === "task" ? "Created" : "Completed",
                      time: "2023-04-16T10:30:00",
                      user: "System",
                    },
                    {
                      action: "Assigned to John Doe",
                      time: "2023-04-16T10:35:00",
                      user: "Admin User",
                    },
                    {
                      action: "Status changed to In Progress",
                      time: "2023-04-16T11:15:00",
                      user: "John Doe",
                    },
                    ...(type === "report"
                      ? [
                          {
                            action: "Marked as Completed",
                            time: "2023-04-16T13:45:00",
                            user: "John Doe",
                          },
                          {
                            action: "Verification Requested",
                            time: "2023-04-16T13:46:00",
                            user: "System",
                          },
                        ]
                      : []),
                  ].map((activity, i) => (
                    <div key={i} className="relative pl-6">
                      <div className="absolute left-0 top-1 h-3 w-3 rounded-full bg-green-500" />
                      {i < 3 && <div className="absolute bottom-0 left-1.5 top-4 w-px bg-gray-800" />}
                      <div className="space-y-1">
                        <div className="text-sm font-medium text-gray-200">{activity.action}</div>
                        <div className="flex items-center gap-2 text-xs text-gray-500">
                          <Clock className="h-3 w-3" />
                          <span>{formatDate(activity.time)}</span>
                          <span>•</span>
                          <span>{activity.user}</span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </TabsContent>
        </Tabs>

        <div className="flex items-center justify-end gap-2 border-t border-gray-800 p-6">
          <Button
            variant="outline"
            className="border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white"
            onClick={onClose}
          >
            Close
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
