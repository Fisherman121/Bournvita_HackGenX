"use client"

import { useState } from "react"
import { Search, X } from "lucide-react"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Label } from "@/components/ui/label"

interface ReassignTaskModalProps {
  isOpen: boolean
  onClose: () => void
  taskId: string
  currentAssignee?: string
}

// Sample data for janitors
const janitors = [
  { id: "1", name: "John Doe", avatar: "/placeholder.svg?height=40&width=40", activeTasks: 3 },
  { id: "2", name: "Jane Smith", avatar: "/placeholder.svg?height=40&width=40", activeTasks: 2 },
  { id: "3", name: "Mike Johnson", avatar: "/placeholder.svg?height=40&width=40", activeTasks: 4 },
  { id: "4", name: "Sarah Williams", avatar: "/placeholder.svg?height=40&width=40", activeTasks: 1 },
  { id: "5", name: "David Brown", avatar: "/placeholder.svg?height=40&width=40", activeTasks: 2 },
  { id: "6", name: "Emily Davis", avatar: "/placeholder.svg?height=40&width=40", activeTasks: 0 },
]

export function ReassignTaskModal({ isOpen, onClose, taskId, currentAssignee }: ReassignTaskModalProps) {
  const [searchQuery, setSearchQuery] = useState("")
  const [selectedJanitor, setSelectedJanitor] = useState("")
  const [isLoading, setIsLoading] = useState(false)

  const filteredJanitors = janitors.filter((janitor) => {
    if (searchQuery) {
      return janitor.name.toLowerCase().includes(searchQuery.toLowerCase())
    }
    return true
  })

  const handleReassign = () => {
    if (!selectedJanitor) {
      alert("Please select a janitor")
      return
    }

    setIsLoading(true)
    // Simulate API call
    setTimeout(() => {
      setIsLoading(false)
      alert(`Task ${taskId} reassigned to ${janitors.find((j) => j.id === selectedJanitor)?.name}`)
      onClose()
    }, 1000)
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-md bg-gray-900 border-gray-800 p-0 text-gray-200">
        <DialogHeader className="p-6 pb-0">
          <div className="flex items-center justify-between">
            <div>
              <DialogTitle className="text-xl text-white">Reassign Task</DialogTitle>
              <DialogDescription className="text-gray-400">
                {taskId} - Currently assigned to {currentAssignee || "No one"}
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

        <div className="p-6 space-y-4">
          <div className="relative">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-gray-500" />
            <Input
              type="search"
              placeholder="Search janitors..."
              className="w-full bg-gray-800/50 pl-9 text-gray-200 focus-visible:ring-green-500"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>

          <div className="rounded-md border border-gray-800">
            <RadioGroup value={selectedJanitor} onValueChange={setSelectedJanitor}>
              <div className="max-h-[300px] overflow-y-auto">
                {filteredJanitors.length > 0 ? (
                  filteredJanitors.map((janitor) => (
                    <div
                      key={janitor.id}
                      className="flex items-center justify-between border-b border-gray-800 last:border-0 p-3"
                    >
                      <div className="flex items-center gap-3">
                        <RadioGroupItem
                          value={janitor.id}
                          id={`janitor-${janitor.id}`}
                          className="border-gray-700 text-green-500"
                        />
                        <Label htmlFor={`janitor-${janitor.id}`} className="flex items-center gap-3 cursor-pointer">
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
                            <div className="text-xs text-gray-400">{janitor.activeTasks} active tasks</div>
                          </div>
                        </Label>
                      </div>
                      <Badge
                        className={
                          janitor.activeTasks === 0
                            ? "bg-green-500/20 text-green-500"
                            : janitor.activeTasks < 3
                              ? "bg-blue-500/20 text-blue-500"
                              : "bg-yellow-500/20 text-yellow-500"
                        }
                      >
                        {janitor.activeTasks === 0
                          ? "Available"
                          : janitor.activeTasks < 3
                            ? "Light Load"
                            : "Heavy Load"}
                      </Badge>
                    </div>
                  ))
                ) : (
                  <div className="flex h-20 items-center justify-center">
                    <p className="text-sm text-gray-400">No janitors found</p>
                  </div>
                )}
              </div>
            </RadioGroup>
          </div>
        </div>

        <div className="flex items-center justify-end gap-2 border-t border-gray-800 p-6">
          <Button
            variant="outline"
            className="border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white"
            onClick={onClose}
          >
            Cancel
          </Button>
          <Button
            className="bg-green-600 hover:bg-green-500 text-white"
            onClick={handleReassign}
            disabled={!selectedJanitor || isLoading}
          >
            {isLoading ? (
              <>
                <svg className="mr-2 h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path
                    className="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  />
                </svg>
                Reassigning...
              </>
            ) : (
              "Reassign Task"
            )}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
