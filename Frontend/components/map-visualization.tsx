"use client"

import type React from "react"

import { useRef, useState } from "react"
import { motion } from "framer-motion"
import { Layers, MapPin, Maximize2, Minimize2, Search, ZoomIn, ZoomOut } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { cn } from "@/lib/utils"

// Sample data for garbage locations
const garbageLocations = [
  {
    id: "G-001",
    location: "Downtown, Main Street",
    coordinates: { lat: 40.7128, lng: -74.006 },
    status: "Pending",
    type: "Plastic",
  },
  {
    id: "G-002",
    location: "Westside Park",
    coordinates: { lat: 40.7138, lng: -74.016 },
    status: "Assigned",
    type: "General Waste",
  },
  {
    id: "G-003",
    location: "East Avenue",
    coordinates: { lat: 40.7148, lng: -73.996 },
    status: "Resolved",
    type: "Paper",
  },
  {
    id: "G-004",
    location: "North Boulevard",
    coordinates: { lat: 40.7158, lng: -74.001 },
    status: "Assigned",
    type: "Glass",
  },
  {
    id: "G-005",
    location: "South Market",
    coordinates: { lat: 40.7118, lng: -74.011 },
    status: "Pending",
    type: "Metal",
  },
  {
    id: "G-006",
    location: "Central Park",
    coordinates: { lat: 40.7108, lng: -73.991 },
    status: "Resolved",
    type: "Organic",
  },
]

interface MapVisualizationProps {
  className?: string
  fullScreen?: boolean
  onToggleFullScreen?: () => void
  showControls?: boolean
  showSearch?: boolean
  showFilters?: boolean
  onMarkerClick?: (location: any) => void
}

export function MapVisualization({
  className,
  fullScreen = false,
  onToggleFullScreen,
  showControls = true,
  showSearch = true,
  showFilters = true,
  onMarkerClick,
}: MapVisualizationProps) {
  const mapRef = useRef<HTMLDivElement>(null)
  const [zoom, setZoom] = useState(13)
  const [center, setCenter] = useState({ lat: 40.7128, lng: -74.006 })
  const [searchQuery, setSearchQuery] = useState("")
  const [statusFilter, setStatusFilter] = useState("all")
  const [typeFilter, setTypeFilter] = useState("all")
  const [selectedMarker, setSelectedMarker] = useState<string | null>(null)
  const [isDragging, setIsDragging] = useState(false)
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 })
  const [mapOffset, setMapOffset] = useState({ x: 0, y: 0 })

  // Filter locations based on search and filters
  const filteredLocations = garbageLocations.filter((location) => {
    if (searchQuery && !location.location.toLowerCase().includes(searchQuery.toLowerCase())) {
      return false
    }
    if (statusFilter !== "all" && location.status.toLowerCase() !== statusFilter) {
      return false
    }
    if (typeFilter !== "all" && location.type.toLowerCase() !== typeFilter) {
      return false
    }
    return true
  })

  // Handle map drag
  const handleMouseDown = (e: React.MouseEvent) => {
    setIsDragging(true)
    setDragStart({ x: e.clientX, y: e.clientY })
  }

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!isDragging) return
    const dx = e.clientX - dragStart.x
    const dy = e.clientY - dragStart.y
    setMapOffset((prev) => ({ x: prev.x + dx, y: prev.y + dy }))
    setDragStart({ x: e.clientX, y: e.clientY })
  }

  const handleMouseUp = () => {
    setIsDragging(false)
  }

  // Handle zoom
  const handleZoomIn = () => {
    setZoom((prev) => Math.min(prev + 1, 18))
  }

  const handleZoomOut = () => {
    setZoom((prev) => Math.max(prev - 1, 10))
  }

  // Handle marker click
  const handleMarkerClick = (location: any) => {
    setSelectedMarker(location.id === selectedMarker ? null : location.id)
    if (onMarkerClick) {
      onMarkerClick(location)
    }
  }

  // Calculate marker positions based on coordinates, zoom, and offset
  const getMarkerPosition = (coordinates: { lat: number; lng: number }) => {
    const scale = Math.pow(2, zoom - 10)
    const x = (coordinates.lng - center.lng) * scale * 1000 + mapOffset.x
    const y = (center.lat - coordinates.lat) * scale * 1000 + mapOffset.y
    return { x, y }
  }

  return (
    <Card
      className={cn(
        "relative overflow-hidden bg-gray-900/50 border-gray-800",
        fullScreen ? "fixed inset-4 z-50" : "h-[400px]",
        className,
      )}
    >
      {showSearch && (
        <div className="absolute left-4 right-4 top-4 z-10 flex flex-col gap-2 sm:flex-row">
          <div className="relative flex-1">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-gray-500" />
            <Input
              type="search"
              placeholder="Search locations..."
              className="w-full bg-gray-800/80 pl-9 text-gray-200 focus-visible:ring-green-500"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          {showFilters && (
            <>
              <Select value={statusFilter} onValueChange={setStatusFilter}>
                <SelectTrigger className="w-full bg-gray-800/80 text-gray-200 focus:ring-green-500 sm:w-[150px]">
                  <SelectValue placeholder="Status" />
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
                  <SelectItem value="resolved" className="text-gray-200">
                    Resolved
                  </SelectItem>
                </SelectContent>
              </Select>
              <Select value={typeFilter} onValueChange={setTypeFilter}>
                <SelectTrigger className="w-full bg-gray-800/80 text-gray-200 focus:ring-green-500 sm:w-[150px]">
                  <SelectValue placeholder="Type" />
                </SelectTrigger>
                <SelectContent className="bg-gray-900 border-gray-800">
                  <SelectItem value="all" className="text-gray-200">
                    All Types
                  </SelectItem>
                  <SelectItem value="plastic" className="text-gray-200">
                    Plastic
                  </SelectItem>
                  <SelectItem value="paper" className="text-gray-200">
                    Paper
                  </SelectItem>
                  <SelectItem value="glass" className="text-gray-200">
                    Glass
                  </SelectItem>
                  <SelectItem value="metal" className="text-gray-200">
                    Metal
                  </SelectItem>
                  <SelectItem value="organic" className="text-gray-200">
                    Organic
                  </SelectItem>
                  <SelectItem value="general waste" className="text-gray-200">
                    General Waste
                  </SelectItem>
                </SelectContent>
              </Select>
            </>
          )}
        </div>
      )}

      {showControls && (
        <div className="absolute bottom-4 right-4 z-10 flex flex-col gap-2">
          <Button
            variant="secondary"
            size="icon"
            className="h-8 w-8 rounded-full bg-gray-800/80 text-gray-200 hover:bg-gray-700"
            onClick={handleZoomIn}
          >
            <ZoomIn className="h-4 w-4" />
            <span className="sr-only">Zoom In</span>
          </Button>
          <Button
            variant="secondary"
            size="icon"
            className="h-8 w-8 rounded-full bg-gray-800/80 text-gray-200 hover:bg-gray-700"
            onClick={handleZoomOut}
          >
            <ZoomOut className="h-4 w-4" />
            <span className="sr-only">Zoom Out</span>
          </Button>
          <Button
            variant="secondary"
            size="icon"
            className="h-8 w-8 rounded-full bg-gray-800/80 text-gray-200 hover:bg-gray-700"
            onClick={onToggleFullScreen}
          >
            {fullScreen ? <Minimize2 className="h-4 w-4" /> : <Maximize2 className="h-4 w-4" />}
            <span className="sr-only">{fullScreen ? "Exit Fullscreen" : "Fullscreen"}</span>
          </Button>
          <Button
            variant="secondary"
            size="icon"
            className="h-8 w-8 rounded-full bg-gray-800/80 text-gray-200 hover:bg-gray-700"
          >
            <Layers className="h-4 w-4" />
            <span className="sr-only">Layers</span>
          </Button>
        </div>
      )}

      <div
        ref={mapRef}
        className="h-full w-full cursor-grab active:cursor-grabbing"
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
      >
        {/* Map background - in a real app, this would be a real map library like Google Maps, Mapbox, or Leaflet */}
        <div className="absolute inset-0 bg-[url('/placeholder.svg?height=800&width=1200')] bg-cover bg-center opacity-50">
          <div className="absolute inset-0 bg-gradient-to-br from-gray-900/80 via-gray-800/50 to-gray-900/80"></div>
        </div>

        {/* Grid lines */}
        <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.05)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.05)_1px,transparent_1px)] bg-[size:50px_50px] [transform:translate3d(var(--tw-translate-x),var(--tw-translate-y),0)_rotate(var(--tw-rotate))_skewX(var(--tw-skew-x))_skewY(var(--tw-skew-y))_scaleX(var(--tw-scale-x))_scaleY(var(--tw-scale-y))]"></div>

        {/* Markers */}
        {filteredLocations.map((location) => {
          const position = getMarkerPosition(location.coordinates)
          return (
            <motion.div
              key={location.id}
              className="absolute z-20 transform -translate-x-1/2 -translate-y-1/2"
              style={{ left: `calc(50% + ${position.x}px)`, top: `calc(50% + ${position.y}px)` }}
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ duration: 0.3 }}
            >
              <div
                className={cn("group cursor-pointer", selectedMarker === location.id && "z-30")}
                onClick={() => handleMarkerClick(location)}
              >
                <div
                  className={cn(
                    "flex h-8 w-8 items-center justify-center rounded-full shadow-lg transition-all duration-200",
                    location.status === "Pending" && "bg-yellow-500 text-yellow-950",
                    location.status === "Assigned" && "bg-blue-500 text-blue-950",
                    location.status === "Resolved" && "bg-green-500 text-green-950",
                    selectedMarker === location.id ? "scale-125" : "group-hover:scale-110",
                  )}
                >
                  <MapPin className="h-4 w-4" />
                </div>
                {selectedMarker === location.id && (
                  <div className="absolute left-1/2 top-full z-30 mt-2 w-48 -translate-x-1/2 rounded-md border border-gray-800 bg-gray-900 p-2 shadow-xl">
                    <div className="text-sm font-medium text-white">{location.id}</div>
                    <div className="text-xs text-gray-400">{location.location}</div>
                    <div className="mt-1 flex items-center justify-between">
                      <span
                        className={cn(
                          "text-xs",
                          location.status === "Pending" && "text-yellow-500",
                          location.status === "Assigned" && "text-blue-500",
                          location.status === "Resolved" && "text-green-500",
                        )}
                      >
                        {location.status}
                      </span>
                      <span className="text-xs text-gray-400">{location.type}</span>
                    </div>
                  </div>
                )}
              </div>
            </motion.div>
          )
        })}
      </div>
    </Card>
  )
}
