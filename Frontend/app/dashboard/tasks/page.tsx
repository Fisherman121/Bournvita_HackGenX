"use client"

import { useState } from "react"
import { motion } from "framer-motion"
import { AlertCircle, ArrowUpDown, Clock, Filter, MoreHorizontal, Search } from "lucide-react"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { cn } from "@/lib/utils"

// Sample data for tasks
const tasks = [
  {
    id: "TASK-1234",
    garbageId: "G-001",
    location: "Downtown, Main Street",
    assignedTo: "John Doe",
    assignedAt: "2023-04-16T10:30:00",
    deadline: "2023-04-16T14:30:00",
    status: "Pending",
    priority: "High",
  },
  {
    id: "TASK-1235",
    garbageId: "G-002",
    location: "Westside Park",
    assignedTo: "Jane Smith",
    assignedAt: "2023-04-16T09:15:00",
    deadline: "2023-04-16T13:15:00",
    status: "In Progress",
    priority: "Medium",
  },
  {
    id: "TASK-1236",
    garbageId: "G-003",
    location: "East Avenue",
    assignedTo: "Mike Johnson",
    assignedAt: "2023-04-16T08:45:00",
    deadline: "2023-04-16T12:45:00",
    status: "Done",
    priority: "Low",
  },
  {
    id: "TASK-1237",
    garbageId: "G-004",
    location: "North Boulevard",
    assignedTo: "Sarah Williams",
    assignedAt: "2023-04-16T11:00:00",
    deadline: "2023-04-16T15:00:00",
    status: "Pending",
    priority: "High",
  },
  {
    id: "TASK-1238",
    garbageId: "G-005",
    location: "South Market",
    assignedTo: "David Brown",
    assignedAt: "2023-04-16T10:00:00",
    deadline: "2023-04-16T14:00:00",
    status: "In Progress",
    priority: "Medium",
  },
  {
    id: "TASK-1239",
    garbageId: "G-006",
    location: "Central Park",
    assignedTo: "Emily Davis",
    assignedAt: "2023-04-16T09:30:00",
    deadline: "2023-04-16T13:30:00",
    status: "Done",
    priority: "Low",
  },
]

// Janitors list
const janitors = [
  { id: "1", name: "John Doe", avatar: "/placeholder.svg?height=40&width=40" },
  { id: "2", name: "Jane Smith", avatar: "/placeholder.svg?height=40&width=40" },
  { id: "3", name: "Mike Johnson", avatar: "/placeholder.svg?height=40&width=40" },
  { id: "4", name: "Sarah Williams", avatar: "/placeholder.svg?height=40&width=40" },
  { id: "5", name: "David Brown", avatar: "/placeholder.svg?height=40&width=40" },
  { id: "6", name: "Emily Davis", avatar: "/placeholder.svg?height=40&width=40" },
]

export default function TasksPage() {
  const [filter, setFilter] = useState("all")
  const [searchQuery, setSearchQuery] = useState("")
  const [sortBy, setSortBy] = useState("deadline")
  const [sortOrder, setSortOrder] = useState("asc")

  const handleSort = (column: string) => {
    if (sortBy === column) {
      setSortOrder(sortOrder === "asc" ? "desc" : "asc")
    } else {
      setSortBy(column)
      setSortOrder("asc")
    }
  }

  const filteredTasks = tasks
    .filter((task) => {
      if (filter !== "all" && task.status.toLowerCase().replace(" ", "-") !== filter) {
        return false
      }

      if (searchQuery) {
        const query = searchQuery.toLowerCase()
        return (
          task.id.toLowerCase().includes(query) ||
          task.location.toLowerCase().includes(query) ||
          task.assignedTo.toLowerCase().includes(query)
        )
      }

      return true
    })
    .sort((a, b) => {
      if (sortBy === "deadline") {
        return sortOrder === "asc"
          ? new Date(a.deadline).getTime() - new Date(b.deadline).getTime()
          : new Date(b.deadline).getTime() - new Date(a.deadline).getTime()
      } else if (sortBy === "priority") {
        const priorityOrder = { High: 3, Medium: 2, Low: 1 }
        return sortOrder === "asc"
          ? priorityOrder[a.priority as keyof typeof priorityOrder] -
              priorityOrder[b.priority as keyof typeof priorityOrder]
          : priorityOrder[b.priority as keyof typeof priorityOrder] -
              priorityOrder[a.priority as keyof typeof priorityOrder]
      } else if (sortBy === "assignedAt") {
        return sortOrder === "asc"
          ? new Date(a.assignedAt).getTime() - new Date(b.assignedAt).getTime()
          : new Date(b.assignedAt).getTime() - new Date(a.assignedAt).getTime()
      }
      return 0
    })

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-white">Tasks</h1>
          <p className="text-gray-400">Manage and track garbage collection tasks.</p>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row">
          <div className="relative">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-gray-500" />
            <Input
              type="search"
              placeholder="Search tasks..."
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
              <SelectItem value="in-progress" className="text-gray-200">
                In Progress
              </SelectItem>
              <SelectItem value="done" className="text-gray-200">
                Done
              </SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      <Card className="bg-gray-900/50 border-gray-800 overflow-hidden">
        <CardHeader className="pb-0">
          <CardTitle>Task List</CardTitle>
          <CardDescription>View and manage all garbage collection tasks.</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="rounded-md border border-gray-800">
            <Table>
              <TableHeader className="bg-gray-900">
                <TableRow className="border-gray-800 hover:bg-gray-900">
                  <TableHead className="text-gray-400">Task ID</TableHead>
                  <TableHead className="text-gray-400">Location</TableHead>
                  <TableHead className="text-gray-400">
                    <button className="flex items-center gap-1" onClick={() => handleSort("priority")}>
                      Priority
                      <ArrowUpDown className="h-3 w-3" />
                    </button>
                  </TableHead>
                  <TableHead className="text-gray-400">Assigned To</TableHead>
                  <TableHead className="text-gray-400">
                    <button className="flex items-center gap-1" onClick={() => handleSort("deadline")}>
                      Deadline
                      <ArrowUpDown className="h-3 w-3" />
                    </button>
                  </TableHead>
                  <TableHead className="text-gray-400">Status</TableHead>
                  <TableHead className="text-gray-400 text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredTasks.length > 0 ? (
                  filteredTasks.map((task, index) => (
                    <motion.tr
                      key={task.id}
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ duration: 0.2, delay: index * 0.05 }}
                      className="border-gray-800 bg-gray-900/30 hover:bg-gray-800/50"
                    >
                      <TableCell className="font-medium text-gray-300">
                        {task.id}
                        <div className="text-xs text-gray-500">{task.garbageId}</div>
                      </TableCell>
                      <TableCell className="text-gray-300">{task.location}</TableCell>
                      <TableCell>
                        <Badge
                          className={cn(
                            task.priority === "High" && "bg-red-500/20 text-red-500 hover:bg-red-500/30",
                            task.priority === "Medium" && "bg-yellow-500/20 text-yellow-500 hover:bg-yellow-500/30",
                            task.priority === "Low" && "bg-blue-500/20 text-blue-500 hover:bg-blue-500/30",
                          )}
                        >
                          {task.priority}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Avatar className="h-6 w-6">
                            <AvatarImage src="/placeholder.svg?height=24&width=24" alt={task.assignedTo} />
                            <AvatarFallback className="bg-green-900 text-green-50 text-xs">
                              {task.assignedTo
                                .split(" ")
                                .map((n) => n[0])
                                .join("")}
                            </AvatarFallback>
                          </Avatar>
                          <span className="text-gray-300">{task.assignedTo}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-1 text-gray-300">
                          <Clock className="h-3.5 w-3.5 text-gray-400" />
                          <span>{formatDate(task.deadline)}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Select defaultValue={task.status.toLowerCase().replace(" ", "-")}>
                          <SelectTrigger
                            className={cn(
                              "h-8 w-[110px] border-0 focus:ring-0",
                              task.status === "Pending" && "bg-yellow-500/20 text-yellow-500",
                              task.status === "In Progress" && "bg-blue-500/20 text-blue-500",
                              task.status === "Done" && "bg-green-500/20 text-green-500",
                            )}
                          >
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent className="bg-gray-900 border-gray-800">
                            <SelectItem value="pending" className="text-yellow-500">
                              Pending
                            </SelectItem>
                            <SelectItem value="in-progress" className="text-blue-500">
                              In Progress
                            </SelectItem>
                            <SelectItem value="done" className="text-green-500">
                              Done
                            </SelectItem>
                          </SelectContent>
                        </Select>
                      </TableCell>
                      <TableCell className="text-right">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="icon" className="h-8 w-8 text-gray-400">
                              <MoreHorizontal className="h-4 w-4" />
                              <span className="sr-only">Actions</span>
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end" className="bg-gray-900 border-gray-800">
                            <DropdownMenuItem className="text-gray-200">View Details</DropdownMenuItem>
                            <DropdownMenuItem className="text-gray-200">Reassign Task</DropdownMenuItem>
                            <DropdownMenuItem className="text-gray-200">Mark as Done</DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </TableCell>
                    </motion.tr>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={7} className="h-24 text-center">
                      <div className="flex flex-col items-center gap-2 text-center">
                        <AlertCircle className="h-8 w-8 text-gray-500" />
                        <h3 className="text-lg font-medium text-gray-300">No tasks found</h3>
                        <p className="text-sm text-gray-500">No tasks match your current filters.</p>
                      </div>
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <Card className="bg-gray-900/50 border-gray-800">
          <CardHeader>
            <CardTitle>Task Summary</CardTitle>
            <CardDescription>Overview of current task status</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="grid grid-cols-3 gap-4">
                <div className="rounded-lg bg-gray-800/50 p-4 text-center">
                  <div className="text-2xl font-bold text-white">
                    {tasks.filter((t) => t.status === "Pending").length}
                  </div>
                  <div className="mt-1 text-sm text-yellow-500">Pending</div>
                </div>
                <div className="rounded-lg bg-gray-800/50 p-4 text-center">
                  <div className="text-2xl font-bold text-white">
                    {tasks.filter((t) => t.status === "In Progress").length}
                  </div>
                  <div className="mt-1 text-sm text-blue-500">In Progress</div>
                </div>
                <div className="rounded-lg bg-gray-800/50 p-4 text-center">
                  <div className="text-2xl font-bold text-white">{tasks.filter((t) => t.status === "Done").length}</div>
                  <div className="mt-1 text-sm text-green-500">Done</div>
                </div>
              </div>

              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Priority Distribution</span>
                </div>
                <div className="space-y-2">
                  {[
                    {
                      priority: "High",
                      count: tasks.filter((t) => t.priority === "High").length,
                      total: tasks.length,
                      color: "bg-red-500",
                    },
                    {
                      priority: "Medium",
                      count: tasks.filter((t) => t.priority === "Medium").length,
                      total: tasks.length,
                      color: "bg-yellow-500",
                    },
                    {
                      priority: "Low",
                      count: tasks.filter((t) => t.priority === "Low").length,
                      total: tasks.length,
                      color: "bg-blue-500",
                    },
                  ].map((item) => (
                    <div key={item.priority} className="space-y-1">
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-300">{item.priority}</span>
                        <span className="text-sm text-gray-400">{item.count} tasks</span>
                      </div>
                      <div className="h-2 w-full rounded-full bg-gray-800">
                        <div
                          className={`h-2 rounded-full ${item.color}`}
                          style={{ width: `${(item.count / item.total) * 100}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-gray-900/50 border-gray-800">
          <CardHeader>
            <CardTitle>Available Janitors</CardTitle>
            <CardDescription>Janitors available for task assignment</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {janitors.map((janitor) => (
                <div
                  key={janitor.id}
                  className="flex items-center justify-between rounded-lg border border-gray-800 bg-gray-800/30 p-3 hover:bg-gray-800/50"
                >
                  <div className="flex items-center gap-3">
                    <Avatar>
                      <AvatarImage src={janitor.avatar || "/placeholder.svg"} alt={janitor.name} />
                      <AvatarFallback className="bg-green-900 text-green-50">
                        {janitor.name
                          .split(" ")
                          .map((n) => n[0])
                          .join("")}
                      </AvatarFallback>
                    </Avatar>
                    <div>
                      <div className="font-medium text-gray-200">{janitor.name}</div>
                      <div className="text-xs text-gray-400">
                        {tasks.filter((t) => t.assignedTo === janitor.name && t.status !== "Done").length} active tasks
                      </div>
                    </div>
                  </div>
                  <Button
                    size="sm"
                    variant="outline"
                    className="border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white"
                  >
                    Assign
                  </Button>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
