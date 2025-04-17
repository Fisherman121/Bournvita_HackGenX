"use client"

import { useState, useRef } from "react"
import { useRouter } from "next/navigation"
import { Camera, ImagePlus, Trash2, Upload, CheckCircle, AlertTriangle, MapPin } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Separator } from "@/components/ui/separator"
import { useToast } from "@/components/ui/use-toast"
import Image from "next/image"

// Waste categories for the dropdown
const wasteCategories = [
  "Plastic",
  "Paper",
  "Glass",
  "Metal",
  "Organic",
  "E-waste",
  "Hazardous",
  "Other"
]

// Severity levels for the dropdown
const severityLevels = [
  { value: "low", label: "Low - Minor issue" },
  { value: "medium", label: "Medium - Requires attention" },
  { value: "high", label: "High - Urgent cleanup needed" },
  { value: "critical", label: "Critical - Hazardous/Emergency" }
]

export default function ReportPage() {
  const { toast } = useToast()
  const router = useRouter()
  const fileInputRef = useRef<HTMLInputElement>(null)
  
  // Form state
  const [location, setLocation] = useState("")
  const [wasteType, setWasteType] = useState("")
  const [severity, setSeverity] = useState("")
  const [description, setDescription] = useState("")
  const [images, setImages] = useState<string[]>([])
  const [imageFiles, setImageFiles] = useState<File[]>([])
  
  // Loading states
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isCameraActive, setIsCameraActive] = useState(false)
  const [cameraError, setCameraError] = useState<string | null>(null)
  const [isGettingLocation, setIsGettingLocation] = useState(false)
  const [locationError, setLocationError] = useState<string | null>(null)
  
  // Video refs
  const videoRef = useRef<HTMLVideoElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  
  // Handle file upload
  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files
    if (!files || files.length === 0) return
    
    const newImageFiles = Array.from(files)
    setImageFiles(prev => [...prev, ...newImageFiles])
    
    // Create preview URLs
    const newImageUrls = newImageFiles.map(file => URL.createObjectURL(file))
    setImages(prev => [...prev, ...newImageUrls])
    
    // Reset file input
    if (fileInputRef.current) fileInputRef.current.value = ""
  }
  
  // Remove image
  const removeImage = (index: number) => {
    const newImages = [...images]
    const newImageFiles = [...imageFiles]
    
    // Revoke object URL to prevent memory leaks
    URL.revokeObjectURL(newImages[index])
    
    newImages.splice(index, 1)
    newImageFiles.splice(index, 1)
    
    setImages(newImages)
    setImageFiles(newImageFiles)
  }
  
  // Start camera
  const startCamera = async () => {
    setCameraError(null)
    setIsCameraActive(true)
    
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ 
        video: { facingMode: "environment" } 
      })
      
      if (videoRef.current) {
        videoRef.current.srcObject = stream
      }
    } catch (err) {
      console.error("Error accessing camera:", err)
      setCameraError("Failed to access camera. Please check permissions or try uploading images instead.")
      setIsCameraActive(false)
    }
  }
  
  // Capture photo
  const capturePhoto = () => {
    if (!videoRef.current || !canvasRef.current) return
    
    const video = videoRef.current
    const canvas = canvasRef.current
    const context = canvas.getContext("2d")
    
    if (!context) return
    
    // Set canvas dimensions to match video
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    
    // Draw video frame to canvas
    context.drawImage(video, 0, 0, canvas.width, canvas.height)
    
    // Convert to image data URL
    const imageDataUrl = canvas.toDataURL("image/jpeg")
    setImages(prev => [...prev, imageDataUrl])
    
    // Convert data URL to File object
    canvas.toBlob((blob) => {
      if (blob) {
        const file = new File([blob], `capture-${Date.now()}.jpg`, { type: "image/jpeg" })
        setImageFiles(prev => [...prev, file])
      }
    }, "image/jpeg", 0.9)
  }
  
  // Stop camera
  const stopCamera = () => {
    if (videoRef.current && videoRef.current.srcObject) {
      const tracks = (videoRef.current.srcObject as MediaStream).getTracks()
      tracks.forEach(track => track.stop())
      videoRef.current.srcObject = null
    }
    
    setIsCameraActive(false)
  }
  
  // Get current location
  const getCurrentLocation = () => {
    if (!navigator.geolocation) {
      setLocationError("Geolocation is not supported by your browser")
      return
    }
    
    setIsGettingLocation(true)
    setLocationError(null)
    
    navigator.geolocation.getCurrentPosition(
      async (position) => {
        try {
          const { latitude, longitude } = position.coords
          
          // Get address from coordinates using reverse geocoding
          // In a real app, you would use a geocoding service like Google Maps, Mapbox, etc.
          // For this demo, we'll just use the coordinates
          let locationText = `Coordinates: ${latitude.toFixed(6)}, ${longitude.toFixed(6)}`
          
          // Try to get a human-readable address using Nominatim OpenStreetMap API
          try {
            const response = await fetch(
              `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&zoom=18&addressdetails=1`,
              { headers: { 'Accept-Language': 'en-US,en' } }
            )
            
            if (response.ok) {
              const data = await response.json()
              if (data && data.display_name) {
                locationText = data.display_name
              }
            }
          } catch (error) {
            console.error("Error getting address:", error)
            // Fall back to coordinates if geocoding fails
          }
          
          setLocation(locationText)
          setIsGettingLocation(false)
        } catch (error) {
          console.error("Error processing location:", error)
          setLocationError("Failed to process your location")
          setIsGettingLocation(false)
        }
      },
      (error) => {
        console.error("Geolocation error:", error)
        let errorMessage = "Failed to get your location"
        
        switch (error.code) {
          case error.PERMISSION_DENIED:
            errorMessage = "Location permission denied. Please enable location access."
            break
          case error.POSITION_UNAVAILABLE:
            errorMessage = "Location information is unavailable."
            break
          case error.TIMEOUT:
            errorMessage = "Location request timed out."
            break
        }
        
        setLocationError(errorMessage)
        setIsGettingLocation(false)
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
    )
  }
  
  // Submit report
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!location || !wasteType || !severity || !description || images.length === 0) {
      toast({
        title: "Missing Information",
        description: "Please fill all fields and add at least one image",
        variant: "destructive"
      })
      return
    }
    
    setIsSubmitting(true)
    
    try {
      // Create form data for multipart/form-data upload
      const formData = new FormData()
      formData.append("location", location)
      formData.append("wasteType", wasteType)
      formData.append("severity", severity)
      formData.append("description", description)
      formData.append("reportType", "janitor")
      formData.append("timestamp", new Date().toISOString())
      
      // Add all image files
      imageFiles.forEach((file, index) => {
        formData.append(`image-${index}`, file)
      })
      
      // Send to API
      const response = await fetch("/api/janitor/reports", {
        method: "POST",
        body: formData,
      })
      
      if (!response.ok) {
        throw new Error(`Failed to submit report: ${response.status} ${response.statusText}`)
      }
      
      toast({
        title: "Report Submitted",
        description: "Your report has been sent to the administrators.",
        variant: "default"
      })
      
      // Reset form after successful submission
      setLocation("")
      setWasteType("")
      setSeverity("")
      setDescription("")
      setImages([])
      setImageFiles([])
      
      // Redirect to dashboard or tasks
      router.push("/janitor/dashboard")
      
    } catch (error) {
      console.error("Error submitting report:", error)
      toast({
        title: "Submission Failed",
        description: "There was an error submitting your report. Please try again.",
        variant: "destructive"
      })
    } finally {
      setIsSubmitting(false)
    }
  }
  
  return (
    <div className="container mx-auto max-w-3xl px-4 py-8">
      <h1 className="mb-2 text-3xl font-bold tracking-tight text-white">Submit Report</h1>
      <p className="mb-8 text-gray-400">Report issues or cleanup needs to the administration</p>
      
      <form onSubmit={handleSubmit}>
        <Card className="bg-gray-900/50 border-gray-800">
          <CardHeader>
            <CardTitle>Issue Report Details</CardTitle>
            <CardDescription>Provide details about the waste or issue you've encountered</CardDescription>
          </CardHeader>
          
          <CardContent className="space-y-6">
            {/* Location Input with Use Current Location button */}
            <div className="space-y-2">
              <Label htmlFor="location" className="text-gray-300">Location</Label>
              <div className="flex gap-2">
                <div className="relative flex-1">
                  <Input
                    id="location"
                    placeholder="Enter precise location (e.g., 'North Entrance, Building 3')"
                    className="bg-gray-800/50 border-gray-700 text-gray-200 focus-visible:ring-green-500 pr-10"
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    required
                  />
                  {location && (
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon"
                      className="absolute right-1 top-1/2 -translate-y-1/2 h-7 w-7 text-gray-400 hover:text-gray-200"
                      onClick={() => setLocation("")}
                    >
                      <span className="sr-only">Clear location</span>
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-4 w-4">
                        <path d="M18 6L6 18M6 6l12 12" />
                      </svg>
                    </Button>
                  )}
                </div>
                <Button
                  type="button"
                  variant="outline"
                  className="border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white whitespace-nowrap"
                  onClick={getCurrentLocation}
                  disabled={isGettingLocation}
                >
                  {isGettingLocation ? (
                    <>
                      <div className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                      Getting...
                    </>
                  ) : (
                    <>
                      <MapPin className="mr-2 h-4 w-4" />
                      Use Current Location
                    </>
                  )}
                </Button>
              </div>
              {locationError && (
                <div className="text-sm text-red-400 mt-1 flex items-center">
                  <AlertTriangle className="h-4 w-4 mr-1" />
                  {locationError}
                </div>
              )}
            </div>
            
            {/* Waste Type Select */}
            <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="waste-type" className="text-gray-300">Waste Type</Label>
                <Select value={wasteType} onValueChange={setWasteType}>
                  <SelectTrigger id="waste-type" className="bg-gray-800/50 border-gray-700 text-gray-200 focus:ring-green-500">
                    <SelectValue placeholder="Select waste type" />
                  </SelectTrigger>
                  <SelectContent className="bg-gray-900 border-gray-800">
                    {wasteCategories.map((category) => (
                      <SelectItem key={category} value={category} className="text-gray-200">
                        {category}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              
              {/* Severity Select */}
              <div className="space-y-2">
                <Label htmlFor="severity" className="text-gray-300">Severity</Label>
                <Select value={severity} onValueChange={setSeverity}>
                  <SelectTrigger id="severity" className="bg-gray-800/50 border-gray-700 text-gray-200 focus:ring-green-500">
                    <SelectValue placeholder="Select severity" />
                  </SelectTrigger>
                  <SelectContent className="bg-gray-900 border-gray-800">
                    {severityLevels.map((level) => (
                      <SelectItem key={level.value} value={level.value} className="text-gray-200">
                        {level.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            
            {/* Description Textarea */}
            <div className="space-y-2">
              <Label htmlFor="description" className="text-gray-300">Description</Label>
              <Textarea
                id="description"
                placeholder="Describe the issue in detail..."
                className="min-h-[120px] bg-gray-800/50 border-gray-700 text-gray-200 focus-visible:ring-green-500"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                required
              />
            </div>
            
            <Separator className="bg-gray-800" />
            
            {/* Image Upload Section */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Label className="text-gray-300">Images</Label>
                <div className="flex gap-2">
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    className="border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white"
                    onClick={() => fileInputRef.current?.click()}
                  >
                    <ImagePlus className="mr-2 h-4 w-4" />
                    Upload
                  </Button>
                  
                  {!isCameraActive ? (
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      className="border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white"
                      onClick={startCamera}
                    >
                      <Camera className="mr-2 h-4 w-4" />
                      Camera
                    </Button>
                  ) : (
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      className="border-gray-700 bg-red-900/50 text-red-200 hover:bg-red-900"
                      onClick={stopCamera}
                    >
                      Stop Camera
                    </Button>
                  )}
                </div>
                
                <input
                  type="file"
                  ref={fileInputRef}
                  onChange={handleFileUpload}
                  accept="image/*"
                  multiple
                  className="hidden"
                />
              </div>
              
              {/* Camera View */}
              {isCameraActive && (
                <div className="space-y-4 rounded-lg border border-gray-800 p-4">
                  {cameraError ? (
                    <div className="flex items-center gap-2 text-red-400">
                      <AlertTriangle className="h-5 w-5" />
                      <span>{cameraError}</span>
                    </div>
                  ) : (
                    <>
                      <div className="relative aspect-video w-full overflow-hidden rounded-md bg-black">
                        <video
                          ref={videoRef}
                          autoPlay
                          playsInline
                          className="h-full w-full object-cover"
                        />
                      </div>
                      <Button
                        type="button"
                        className="w-full bg-green-600 hover:bg-green-500"
                        onClick={capturePhoto}
                      >
                        <Camera className="mr-2 h-4 w-4" />
                        Capture Photo
                      </Button>
                      <canvas ref={canvasRef} className="hidden" />
                    </>
                  )}
                </div>
              )}
              
              {/* Image Previews */}
              {images.length > 0 && (
                <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4">
                  {images.map((image, index) => (
                    <div key={index} className="group relative aspect-square">
                      <Image
                        src={image}
                        alt={`Uploaded image ${index + 1}`}
                        fill
                        className="rounded-md object-cover"
                        sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
                      />
                      <Button
                        type="button"
                        variant="destructive"
                        size="icon"
                        className="absolute right-1 top-1 h-7 w-7 opacity-70 transition-opacity group-hover:opacity-100"
                        onClick={() => removeImage(index)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  ))}
                </div>
              )}
              
              {/* Empty state */}
              {images.length === 0 && !isCameraActive && (
                <div className="flex flex-col items-center justify-center rounded-lg border border-dashed border-gray-700 p-8 text-center">
                  <Upload className="mb-4 h-10 w-10 text-gray-500" />
                  <p className="mb-2 text-sm text-gray-400">
                    Upload images of the issue by clicking the Upload button or using the Camera
                  </p>
                  <p className="text-xs text-gray-500">JPG, PNG or GIF, up to 10MB each</p>
                </div>
              )}
            </div>
          </CardContent>
          
          <CardFooter className="border-t border-gray-800 pt-6">
            <Button
              type="submit"
              className="w-full bg-green-600 hover:bg-green-500"
              disabled={isSubmitting}
            >
              {isSubmitting ? (
                <>
                  <div className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                  Submitting...
                </>
              ) : (
                <>
                  <CheckCircle className="mr-2 h-4 w-4" />
                  Submit Report
                </>
              )}
            </Button>
          </CardFooter>
        </Card>
      </form>
    </div>
  )
} 