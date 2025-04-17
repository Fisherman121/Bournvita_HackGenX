"use client"

import { useState, useEffect } from "react"
import { motion } from "framer-motion"
import { BarChart3, Calendar, Download, LineChart, PieChart, RefreshCcw } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { MapVisualization } from "@/components/map-visualization"

// Define the types for analytics data
interface DetectionLog {
  timestamp: string;
  class: string;
  confidence: number;
  image_path?: string;
  location: string;
  status: string;
  zone_name?: string;
  camera_id?: string;
}

interface AnalyticsData {
  totalDetections: number;
  completionRate: number;
  avgResponseTime: number;
  detectionTrend: number[];
  wasteDistribution: Record<string, number>;
  locationHotspots: {name: string; count: number}[];
  detectionsByDay: Record<string, number>;
  detectionsByHour: number[];
}

export default function AnalyticsPage() {
  const [dateRange, setDateRange] = useState("7d")
  const [isMapFullScreen, setIsMapFullScreen] = useState(false)
  const [analyticsData, setAnalyticsData] = useState<AnalyticsData>({
    totalDetections: 0,
    completionRate: 0,
    avgResponseTime: 0,
    detectionTrend: [0, 0, 0, 0, 0, 0, 0],
    wasteDistribution: {},
    locationHotspots: [],
    detectionsByDay: {},
    detectionsByHour: Array(24).fill(0)
  })
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Function to calculate analytics from detection logs
  const calculateAnalytics = (logs: DetectionLog[]): AnalyticsData => {
    // Calculate basic metrics
    const totalDetections = logs.length;
    const cleanedTasks = logs.filter(log => log.status === "cleaned").length;
    const completionRate = totalDetections > 0 ? (cleanedTasks / totalDetections) * 100 : 0;
    
    // Calculate average response time (mock for now, would need cleaned_at timestamp)
    // In a real implementation, you would calculate the time difference between detection and cleaning
    const avgResponseTime = 1.8; // hours
    
    // Calculate detection trend (last 7 days)
    const today = new Date();
    const last7Days = Array(7).fill(0).map((_, i) => {
      const date = new Date();
      date.setDate(today.getDate() - (6 - i));
      return date.toISOString().split('T')[0];
    });
    
    const detectionsByDate: Record<string, number> = {};
    logs.forEach(log => {
      const date = new Date(log.timestamp).toISOString().split('T')[0];
      detectionsByDate[date] = (detectionsByDate[date] || 0) + 1;
    });
    
    const detectionTrend = last7Days.map(date => detectionsByDate[date] || 0);
    
    // Calculate waste distribution
    const wasteDistribution: Record<string, number> = {};
    logs.forEach(log => {
      const type = log.class;
      wasteDistribution[type] = (wasteDistribution[type] || 0) + 1;
    });
    
    // Calculate location hotspots
    const locationCounts: Record<string, number> = {};
    logs.forEach(log => {
      const location = log.location;
      locationCounts[location] = (locationCounts[location] || 0) + 1;
    });
    
    const locationHotspots = Object.entries(locationCounts)
      .map(([name, count]) => ({ name, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);
    
    // Calculate detections by day of week
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const detectionsByDay: Record<string, number> = {};
    
    dayNames.forEach(day => {
      detectionsByDay[day] = 0;
    });
    
    logs.forEach(log => {
      const dayOfWeek = dayNames[new Date(log.timestamp).getDay()];
      detectionsByDay[dayOfWeek] = (detectionsByDay[dayOfWeek] || 0) + 1;
    });
    
    // Calculate detections by hour
    const detectionsByHour = Array(24).fill(0);
    logs.forEach(log => {
      const hour = new Date(log.timestamp).getHours();
      detectionsByHour[hour]++;
    });
    
    return {
      totalDetections,
      completionRate,
      avgResponseTime,
      detectionTrend,
      wasteDistribution,
      locationHotspots,
      detectionsByDay,
      detectionsByHour
    };
  };

  // Fetch detection logs from the API
  const fetchAnalyticsData = async () => {
    setIsLoading(true);
    setError(null);
    
    try {
      // Fetch detection logs
      const response = await fetch(`/api/logs?range=${dateRange}`);
      
      if (!response.ok) {
        throw new Error(`Failed to fetch logs: ${response.status} ${response.statusText}`);
      }
      
      const logs = await response.json();
      
      // Calculate analytics
      const analytics = calculateAnalytics(logs);
      setAnalyticsData(analytics);
      
    } catch (err) {
      console.error("Error fetching analytics data:", err);
      setError(err instanceof Error ? err.message : "Failed to fetch analytics data");
    } finally {
      setIsLoading(false);
    }
  };

  // Load analytics data when component mounts or date range changes
  useEffect(() => {
    fetchAnalyticsData();
    
    // Set up automatic refresh every 60 seconds
    const interval = setInterval(fetchAnalyticsData, 60000);
    
    // Clean up interval on unmount
    return () => clearInterval(interval);
  }, [dateRange]);

  // Format percentage for display
  const formatPercentage = (value: number) => {
    return `${Math.round(value)}%`;
  };

  // Format response time for display
  const formatResponseTime = (hours: number) => {
    const wholeHours = Math.floor(hours);
    const minutes = Math.round((hours - wholeHours) * 60);
    
    if (minutes === 0) {
      return `${wholeHours} hour${wholeHours !== 1 ? 's' : ''}`;
    }
    
    return `${wholeHours} hour${wholeHours !== 1 ? 's' : ''} ${minutes} min`;
  };

  // Find the top waste type
  const getTopWasteType = () => {
    const entries = Object.entries(analyticsData.wasteDistribution);
    if (entries.length === 0) return "N/A";
    
    entries.sort((a, b) => b[1] - a[1]);
    return entries[0][0];
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-white">Analytics</h1>
          <p className="text-gray-400">Analyze garbage detection and collection performance.</p>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row">
          <Select value={dateRange} onValueChange={setDateRange}>
            <SelectTrigger className="w-full bg-gray-800/50 text-gray-200 focus:ring-green-500 sm:w-[150px]">
              <div className="flex items-center gap-2">
                <Calendar className="h-4 w-4" />
                <SelectValue placeholder="Date Range" />
              </div>
            </SelectTrigger>
            <SelectContent className="bg-gray-900 border-gray-800">
              <SelectItem value="24h" className="text-gray-200">
                Last 24 Hours
              </SelectItem>
              <SelectItem value="7d" className="text-gray-200">
                Last 7 Days
              </SelectItem>
              <SelectItem value="30d" className="text-gray-200">
                Last 30 Days
              </SelectItem>
              <SelectItem value="90d" className="text-gray-200">
                Last 90 Days
              </SelectItem>
              <SelectItem value="custom" className="text-gray-200">
                Custom Range
              </SelectItem>
            </SelectContent>
          </Select>
          <Button
            variant="outline"
            className="border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white"
            onClick={fetchAnalyticsData}
          >
            <RefreshCcw className="mr-2 h-4 w-4" />
            Refresh Data
          </Button>
          <Button
            variant="outline"
            className="border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white"
          >
            <Download className="mr-2 h-4 w-4" />
            Export
          </Button>
        </div>
      </div>

      {isLoading && (
        <div className="flex items-center justify-center p-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-500"></div>
          <span className="ml-3 text-gray-400">Loading analytics data...</span>
        </div>
      )}

      {error && (
        <div className="bg-red-900/20 border border-red-700 text-red-400 p-4 rounded-lg">
          <h3 className="font-semibold mb-2">Error Loading Data</h3>
          <p>{error}</p>
        </div>
      )}

      {!isLoading && !error && (
        <>
          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            <Card className="bg-gray-900/50 border-gray-800">
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-gray-400">Total Detections</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-white">{analyticsData.totalDetections}</div>
                <p className="text-xs text-green-500">+12% from previous period</p>
              </CardContent>
            </Card>
            <Card className="bg-gray-900/50 border-gray-800">
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-gray-400">Completion Rate</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-white">{formatPercentage(analyticsData.completionRate)}</div>
                <p className="text-xs text-green-500">+5% from previous period</p>
              </CardContent>
            </Card>
            <Card className="bg-gray-900/50 border-gray-800">
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-gray-400">Avg. Response Time</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-white">{formatResponseTime(analyticsData.avgResponseTime)}</div>
                <p className="text-xs text-green-500">-15 minutes from previous period</p>
              </CardContent>
            </Card>
          </div>

          <Tabs defaultValue="overview" className="space-y-4">
            <TabsList className="bg-gray-800/50">
              <TabsTrigger
                value="overview"
                className="data-[state=active]:bg-green-900/30 data-[state=active]:text-green-500"
              >
                Overview
              </TabsTrigger>
              <TabsTrigger
                value="detections"
                className="data-[state=active]:bg-green-900/30 data-[state=active]:text-green-500"
              >
                Detections
              </TabsTrigger>
              <TabsTrigger
                value="performance"
                className="data-[state=active]:bg-green-900/30 data-[state=active]:text-green-500"
              >
                Performance
              </TabsTrigger>
              <TabsTrigger
                value="locations"
                className="data-[state=active]:bg-green-900/30 data-[state=active]:text-green-500"
              >
                Locations
              </TabsTrigger>
            </TabsList>

            <TabsContent value="overview" className="space-y-4">
              <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
                <Card className="bg-gray-900/50 border-gray-800">
                  <CardHeader>
                    <div className="flex items-center justify-between">
                      <div>
                        <CardTitle>Detection Trend</CardTitle>
                        <CardDescription>Garbage detections over time</CardDescription>
                      </div>
                      <Badge className="bg-blue-500/20 text-blue-500 hover:bg-blue-500/30">
                        <LineChart className="mr-1 h-3 w-3" />
                        Trend
                      </Badge>
                    </div>
                  </CardHeader>
                  <CardContent className="px-2">
                    <div className="h-[300px] w-full">
                      {/* Real data-driven chart */}
                      <div className="flex h-full w-full items-end justify-between gap-2 px-6">
                        {analyticsData.detectionTrend.map((value, i) => {
                          const maxValue = Math.max(...analyticsData.detectionTrend, 1);
                          const percentage = (value / maxValue) * 100;
                          
                          return (
                            <motion.div
                              key={i}
                              className="w-full bg-blue-500 rounded-t-md"
                              initial={{ height: 0 }}
                              animate={{ height: `${percentage}%` }}
                              transition={{ duration: 0.5, delay: i * 0.1 }}
                            />
                          );
                        })}
                      </div>
                      <div className="mt-2 flex justify-between px-6 text-xs text-gray-500">
                        <div>Mon</div>
                        <div>Tue</div>
                        <div>Wed</div>
                        <div>Thu</div>
                        <div>Fri</div>
                        <div>Sat</div>
                        <div>Sun</div>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <Card className="bg-gray-900/50 border-gray-800">
                  <CardHeader>
                    <div className="flex items-center justify-between">
                      <div>
                        <CardTitle>Waste Type Distribution</CardTitle>
                        <CardDescription>Breakdown by waste category</CardDescription>
                      </div>
                      <Badge className="bg-green-500/20 text-green-500 hover:bg-green-500/30">
                        <PieChart className="mr-1 h-3 w-3" />
                        Distribution
                      </Badge>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4 mt-4">
                      {Object.entries(analyticsData.wasteDistribution).length > 0 ? (
                        Object.entries(analyticsData.wasteDistribution)
                          .sort((a, b) => b[1] - a[1])
                          .map(([type, count], index) => {
                            const total = analyticsData.totalDetections;
                            const percentage = total > 0 ? (count / total) * 100 : 0;
                            
                            // Use different colors for different waste types
                            const colors = [
                              "bg-blue-500", "bg-green-500", "bg-yellow-500", 
                              "bg-red-500", "bg-purple-500", "bg-pink-500"
                            ];
                            
                            return (
                              <div key={type} className="space-y-1">
                                <div className="flex items-center justify-between">
                                  <span className="text-gray-200">{type}</span>
                                  <span className="text-gray-400">{count} ({Math.round(percentage)}%)</span>
                                </div>
                                <div className="h-2 w-full overflow-hidden rounded-full bg-gray-700">
                                  <motion.div
                                    className={`h-full ${colors[index % colors.length]}`}
                                    style={{ width: `${percentage}%` }}
                                    initial={{ width: 0 }}
                                    animate={{ width: `${percentage}%` }}
                                    transition={{ duration: 0.5, delay: index * 0.1 }}
                                  />
                                </div>
                              </div>
                            );
                          })
                      ) : (
                        <div className="text-center py-8 text-gray-400">
                          No waste type data available
                        </div>
                      )}
                    </div>
                  </CardContent>
                </Card>
              </div>

              <Card className="bg-gray-900/50 border-gray-800">
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle>Performance by Area</CardTitle>
                      <CardDescription>Response time and completion rate by location</CardDescription>
                    </div>
                    <Badge className="bg-yellow-500/20 text-yellow-500 hover:bg-yellow-500/30">
                      <BarChart3 className="mr-1 h-3 w-3" />
                      Comparison
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent className="px-2">
                  <div className="h-[300px] w-full">
                    {/* In a real app, this would be a chart component */}
                    <div className="flex h-full w-full flex-col justify-between gap-4">
                      {[
                        { area: "Downtown", responseTime: 1.2, completionRate: 95 },
                        { area: "Westside", responseTime: 1.5, completionRate: 90 },
                        { area: "Eastside", responseTime: 1.8, completionRate: 88 },
                        { area: "Northside", responseTime: 2.1, completionRate: 85 },
                        { area: "Southside", responseTime: 2.4, completionRate: 82 },
                      ].map((item, i) => (
                        <div key={item.area} className="flex items-center gap-4">
                          <div className="w-24 text-sm text-gray-300">{item.area}</div>
                          <div className="flex flex-1 flex-col gap-1">
                            <div className="flex items-center gap-2">
                              <div className="text-xs text-gray-500">Response Time</div>
                              <motion.div
                                className="h-2 rounded-full bg-blue-500"
                                initial={{ width: 0 }}
                                animate={{ width: `${(item.responseTime / 3) * 100}%` }}
                                transition={{ duration: 0.5, delay: i * 0.1 }}
                              />
                              <div className="text-xs text-gray-300">{item.responseTime}h</div>
                            </div>
                            <div className="flex items-center gap-2">
                              <div className="text-xs text-gray-500">Completion</div>
                              <motion.div
                                className="h-2 rounded-full bg-green-500"
                                initial={{ width: 0 }}
                                animate={{ width: `${item.completionRate}%` }}
                                transition={{ duration: 0.5, delay: i * 0.1 + 0.2 }}
                              />
                              <div className="text-xs text-gray-300">{item.completionRate}%</div>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="detections" className="space-y-4">
              <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
                <Card className="bg-gray-900/50 border-gray-800 lg:col-span-2">
                  <CardHeader>
                    <div className="flex items-center justify-between">
                      <div>
                        <CardTitle>Detection Accuracy</CardTitle>
                        <CardDescription>AI model confidence over time</CardDescription>
                      </div>
                      <div className="flex items-center gap-2">
                        <Select defaultValue="all">
                          <SelectTrigger className="w-[130px] bg-gray-800/50 text-gray-200 focus:ring-green-500">
                            <SelectValue placeholder="Waste Type" />
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
                          </SelectContent>
                        </Select>
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent className="px-2">
                    <div className="h-[300px] w-full">
                      {/* Line chart for detection accuracy */}
                      <div className="relative h-full w-full">
                        {/* Y-axis labels */}
                        <div className="absolute bottom-0 left-0 top-0 flex flex-col justify-between py-6 text-xs text-gray-500">
                          <div>100%</div>
                          <div>75%</div>
                          <div>50%</div>
                          <div>25%</div>
                          <div>0%</div>
                        </div>

                        {/* Chart area */}
                        <div className="absolute inset-y-0 left-8 right-0">
                          {/* Grid lines */}
                          <div className="absolute inset-0 grid grid-rows-4 gap-0 border-b border-gray-800">
                            {[0, 1, 2, 3].map((i) => (
                              <div key={i} className="border-t border-gray-800" />
                            ))}
                          </div>

                          {/* Line chart */}
                          <svg className="absolute inset-0 h-full w-full" preserveAspectRatio="none">
                            <motion.path
                              d="M0,60 C20,40 40,80 60,60 C80,40 100,50 120,30 C140,10 160,20 180,15 C200,10 220,30 240,20 C260,10 280,30 300,20"
                              fill="none"
                              stroke="#10b981"
                              strokeWidth="2"
                              initial={{ pathLength: 0 }}
                              animate={{ pathLength: 1 }}
                              transition={{ duration: 1.5 }}
                            />
                          </svg>

                          {/* Data points */}
                          {[60, 40, 80, 60, 40, 50, 30, 10, 20, 15, 10, 30, 20, 10, 30, 20].map((value, i) => (
                            <motion.div
                              key={i}
                              className="absolute h-2 w-2 rounded-full bg-green-500 ring-2 ring-green-500/20"
                              style={{ bottom: `${value}%`, left: `${(i / 15) * 100}%` }}
                              initial={{ scale: 0, opacity: 0 }}
                              animate={{ scale: 1, opacity: 1 }}
                              transition={{ delay: i * 0.05, duration: 0.3 }}
                            />
                          ))}
                        </div>

                        {/* X-axis labels */}
                        <div className="absolute bottom-0 left-8 right-0 flex justify-between text-xs text-gray-500">
                          <div>Apr 10</div>
                          <div>Apr 12</div>
                          <div>Apr 14</div>
                          <div>Apr 16</div>
                          <div>Apr 18</div>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <Card className="bg-gray-900/50 border-gray-800">
                  <CardHeader>
                    <CardTitle>Detection Metrics</CardTitle>
                    <CardDescription>Key performance indicators</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      {[
                        { label: "Average Confidence", value: "87%", change: "+2.5%", positive: true },
                        { label: "False Positives", value: "3.2%", change: "-0.8%", positive: true },
                        { label: "Detection Speed", value: "1.2s", change: "-0.3s", positive: true },
                        { label: "Missed Detections", value: "4.5%", change: "+0.7%", positive: false },
                      ].map((metric) => (
                        <div key={metric.label} className="space-y-1">
                          <div className="flex items-center justify-between">
                            <div className="text-sm text-gray-400">{metric.label}</div>
                            <div className="text-sm font-medium text-white">{metric.value}</div>
                          </div>
                          <div className="flex items-center justify-between">
                            <div className="h-2 w-full rounded-full bg-gray-800">
                              <motion.div
                                className="h-2 rounded-full bg-green-500"
                                style={{ width: metric.value.replace("%", "").replace("s", "") + "%" }}
                                initial={{ width: 0 }}
                                animate={{ width: metric.value.replace("%", "").replace("s", "") + "%" }}
                                transition={{ duration: 0.8 }}
                              />
                            </div>
                            <div className={`ml-2 text-xs ${metric.positive ? "text-green-500" : "text-red-500"}`}>
                              {metric.change}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              </div>

              <Card className="bg-gray-900/50 border-gray-800">
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle>Detection Hotspots</CardTitle>
                      <CardDescription>Areas with highest detection frequency</CardDescription>
                    </div>
                    <Button
                      variant="outline"
                      className="border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white"
                    >
                      <Download className="mr-2 h-4 w-4" />
                      Export Data
                    </Button>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="relative overflow-x-auto rounded-md border border-gray-800">
                      <table className="w-full text-left text-sm">
                        <thead className="bg-gray-800/50 text-xs uppercase text-gray-400">
                          <tr>
                            <th scope="col" className="px-4 py-3">
                              Location
                            </th>
                            <th scope="col" className="px-4 py-3">
                              Detections
                            </th>
                            <th scope="col" className="px-4 py-3">
                              Avg. Confidence
                            </th>
                            <th scope="col" className="px-4 py-3">
                              Primary Waste
                            </th>
                            <th scope="col" className="px-4 py-3">
                              Trend
                            </th>
                          </tr>
                        </thead>
                        <tbody>
                          {[
                            {
                              location: "Downtown, Main Street",
                              detections: 187,
                              confidence: "94%",
                              waste: "Plastic",
                              trend: "up",
                            },
                            {
                              location: "Westside Park",
                              detections: 156,
                              confidence: "91%",
                              waste: "General",
                              trend: "up",
                            },
                            { location: "East Avenue", detections: 132, confidence: "89%", waste: "Paper", trend: "down" },
                            {
                              location: "North Boulevard",
                              detections: 124,
                              confidence: "92%",
                              waste: "Glass",
                              trend: "stable",
                            },
                            { location: "South Market", detections: 118, confidence: "87%", waste: "Metal", trend: "up" },
                          ].map((item, i) => (
                            <tr key={i} className="border-b border-gray-800 bg-gray-900/30">
                              <td className="px-4 py-3 font-medium text-gray-300">{item.location}</td>
                              <td className="px-4 py-3 text-gray-300">{item.detections}</td>
                              <td className="px-4 py-3 text-gray-300">{item.confidence}</td>
                              <td className="px-4 py-3">
                                <Badge className="bg-blue-500/20 text-blue-500">{item.waste}</Badge>
                              </td>
                              <td className="px-4 py-3">
                                <Badge
                                  className={`
                                  ${item.trend === "up" ? "bg-green-500/20 text-green-500" : ""}
                                  ${item.trend === "down" ? "bg-red-500/20 text-red-500" : ""}
                                  ${item.trend === "stable" ? "bg-yellow-500/20 text-yellow-500" : ""}
                                `}
                                >
                                  {item.trend === "up" && "↑ Increasing"}
                                  {item.trend === "down" && "↓ Decreasing"}
                                  {item.trend === "stable" && "→ Stable"}
                                </Badge>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="performance" className="space-y-4">
              <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
                <Card className="bg-gray-900/50 border-gray-800 lg:col-span-2">
                  <CardHeader>
                    <div className="flex items-center justify-between">
                      <div>
                        <CardTitle>Janitor Performance</CardTitle>
                        <CardDescription>Task completion metrics by janitor</CardDescription>
                      </div>
                      <div className="flex items-center gap-2">
                        <Select defaultValue="completion">
                          <SelectTrigger className="w-[150px] bg-gray-800/50 text-gray-200 focus:ring-green-500">
                            <SelectValue placeholder="Metric" />
                          </SelectTrigger>
                          <SelectContent className="bg-gray-900 border-gray-800">
                            <SelectItem value="completion" className="text-gray-200">
                              Completion Rate
                            </SelectItem>
                            <SelectItem value="response" className="text-gray-200">
                              Response Time
                            </SelectItem>
                            <SelectItem value="quality" className="text-gray-200">
                              Quality Score
                            </SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      {[
                        {
                          name: "John Doe",
                          avatar: "/placeholder.svg?height=40&width=40",
                          tasks: 42,
                          completion: 95,
                          response: 1.2,
                          quality: 4.8,
                        },
                        {
                          name: "Jane Smith",
                          avatar: "/placeholder.svg?height=40&width=40",
                          tasks: 38,
                          completion: 92,
                          response: 1.4,
                          quality: 4.7,
                        },
                        {
                          name: "Mike Johnson",
                          avatar: "/placeholder.svg?height=40&width=40",
                          tasks: 35,
                          completion: 88,
                          response: 1.6,
                          quality: 4.5,
                        },
                        {
                          name: "Sarah Williams",
                          avatar: "/placeholder.svg?height=40&width=40",
                          tasks: 31,
                          completion: 94,
                          response: 1.3,
                          quality: 4.9,
                        },
                        {
                          name: "David Brown",
                          avatar: "/placeholder.svg?height=40&width=40",
                          tasks: 28,
                          completion: 90,
                          response: 1.5,
                          quality: 4.6,
                        },
                      ].map((janitor, i) => (
                        <div key={i} className="flex items-center gap-4">
                          <div className="flex w-48 items-center gap-3">
                            <img
                              src={janitor.avatar || "/placeholder.svg"}
                              alt={janitor.name}
                              className="h-8 w-8 rounded-full"
                            />
                            <div>
                              <div className="text-sm font-medium text-gray-200">{janitor.name}</div>
                              <div className="text-xs text-gray-500">{janitor.tasks} tasks</div>
                            </div>
                          </div>
                          <div className="flex flex-1 items-center gap-3">
                            <div className="h-2 flex-1 rounded-full bg-gray-800">
                              <motion.div
                                className="h-2 rounded-full bg-green-500"
                                style={{ width: `${janitor.completion}%` }}
                                initial={{ width: 0 }}
                                animate={{ width: `${janitor.completion}%` }}
                                transition={{ duration: 0.8, delay: i * 0.1 }}
                              />
                            </div>
                            <div className="w-12 text-right text-sm font-medium text-gray-300">{janitor.completion}%</div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>

                <Card className="bg-gray-900/50 border-gray-800">
                  <CardHeader>
                    <CardTitle>Task Completion</CardTitle>
                    <CardDescription>Status breakdown</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="flex h-[200px] items-center justify-center">
                      {/* Donut chart */}
                      <div className="relative h-40 w-40">
                        <svg viewBox="0 0 100 100" className="h-full w-full -rotate-90">
                          <circle cx="50" cy="50" r="40" fill="transparent" stroke="#1f2937" strokeWidth="20" />
                          <motion.circle
                            cx="50"
                            cy="50"
                            r="40"
                            fill="transparent"
                            stroke="#10b981"
                            strokeWidth="20"
                            strokeDasharray="251.2"
                            strokeDashoffset="62.8"
                            initial={{ strokeDashoffset: 251.2 }}
                            animate={{ strokeDashoffset: 62.8 }}
                            transition={{ duration: 1 }}
                          />
                        </svg>
                        <div className="absolute inset-0 flex flex-col items-center justify-center">
                          <div className="text-3xl font-bold text-white">75%</div>
                          <div className="text-xs text-gray-400">Completed</div>
                        </div>
                      </div>
                    </div>

                    <div className="mt-4 space-y-2">
                      {[
                        { label: "Completed", value: "75%", color: "bg-green-500" },
                        { label: "In Progress", value: "15%", color: "bg-blue-500" },
                        { label: "Pending", value: "10%", color: "bg-yellow-500" },
                      ].map((item) => (
                        <div key={item.label} className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <div className={`h-3 w-3 rounded-full ${item.color}`} />
                            <div className="text-sm text-gray-300">{item.label}</div>
                          </div>
                          <div className="text-sm font-medium text-gray-300">{item.value}</div>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              </div>

              <Card className="bg-gray-900/50 border-gray-800">
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle>Response Time Analysis</CardTitle>
                      <CardDescription>Average time to complete tasks by priority</CardDescription>
                    </div>
                    <Select defaultValue="all">
                      <SelectTrigger className="w-[130px] bg-gray-800/50 text-gray-200 focus:ring-green-500">
                        <SelectValue placeholder="Area" />
                      </SelectTrigger>
                      <SelectContent className="bg-gray-900 border-gray-800">
                        <SelectItem value="all" className="text-gray-200">
                          All Areas
                        </SelectItem>
                        <SelectItem value="downtown" className="text-gray-200">
                          Downtown
                        </SelectItem>
                        <SelectItem value="westside" className="text-gray-200">
                          Westside
                        </SelectItem>
                        <SelectItem value="eastside" className="text-gray-200">
                          Eastside
                        </SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </CardHeader>
                <CardContent className="px-2">
                  <div className="h-[300px] w-full">
                    {/* Bar chart */}
                    <div className="flex h-full w-full items-end justify-around gap-16 px-10">
                      {[
                        { priority: "High", time: 1.2, color: "bg-red-500" },
                        { priority: "Medium", time: 2.4, color: "bg-yellow-500" },
                        { priority: "Low", time: 3.6, color: "bg-blue-500" },
                      ].map((item, i) => (
                        <div key={i} className="flex w-20 flex-col items-center">
                          <motion.div
                            className={`w-full rounded-t-md ${item.color}`}
                            initial={{ height: 0 }}
                            animate={{ height: `${(item.time / 4) * 100}%` }}
                            transition={{ duration: 0.8, delay: i * 0.2 }}
                          />
                          <div className="mt-2 text-center">
                            <div className="text-sm font-medium text-gray-300">{item.priority}</div>
                            <div className="text-xs text-gray-500">{item.time} hours</div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="locations" className="space-y-4">
              <MapVisualization
                fullScreen={isMapFullScreen}
                onToggleFullScreen={() => setIsMapFullScreen(!isMapFullScreen)}
                className="h-[600px]"
              />

              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                <Card className="bg-gray-900/50 border-gray-800">
                  <CardHeader>
                    <CardTitle>Location Insights</CardTitle>
                    <CardDescription>Garbage detection patterns by area</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      {[
                        { area: "Downtown", detections: 187, change: "+12%", hotspots: 5 },
                        { area: "Westside", detections: 156, change: "+8%", hotspots: 4 },
                        { area: "Eastside", detections: 132, change: "-3%", hotspots: 3 },
                        { area: "Northside", detections: 124, change: "+5%", hotspots: 3 },
                        { area: "Southside", detections: 118, change: "+10%", hotspots: 2 },
                      ].map((area, i) => (
                        <div
                          key={i}
                          className="flex items-center justify-between rounded-md border border-gray-800 bg-gray-800/30 p-3"
                        >
                          <div>
                            <div className="font-medium text-gray-200">{area.area}</div>
                            <div className="text-xs text-gray-500">{area.hotspots} hotspots identified</div>
                          </div>
                          <div className="text-right">
                            <div className="text-lg font-medium text-gray-200">{area.detections}</div>
                            <div className={`text-xs ${area.change.startsWith("+") ? "text-green-500" : "text-red-500"}`}>
                              {area.change} from last period
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>

                <Card className="bg-gray-900/50 border-gray-800">
                  <CardHeader>
                    <CardTitle>Time-based Patterns</CardTitle>
                    <CardDescription>Detection frequency by time of day</CardDescription>
                  </CardHeader>
                  <CardContent className="px-2">
                    <div className="h-[300px] w-full">
                      {/* Line chart for time patterns */}
                      <div className="relative h-full w-full">
                        {/* Y-axis labels */}
                        <div className="absolute bottom-0 left-0 top-0 flex flex-col justify-between py-6 text-xs text-gray-500">
                          <div>High</div>
                          <div>Medium</div>
                          <div>Low</div>
                        </div>

                        {/* Chart area */}
                        <div className="absolute inset-y-0 left-8 right-0">
                          {/* Grid lines */}
                          <div className="absolute inset-0 grid grid-rows-2 gap-0 border-b border-gray-800">
                            {[0, 1].map((i) => (
                              <div key={i} className="border-t border-gray-800" />
                            ))}
                          </div>

                          {/* Line chart */}
                          <svg className="absolute inset-0 h-full w-full" preserveAspectRatio="none">
                            <motion.path
                              d="M0,80 C20,70 40,60 60,30 C80,20 100,10 120,20 C140,30 160,40 180,30 C200,20 220,40 240,60 C260,70 280,80 300,70"
                              fill="none"
                              stroke="#3b82f6"
                              strokeWidth="2"
                              initial={{ pathLength: 0 }}
                              animate={{ pathLength: 1 }}
                              transition={{ duration: 1.5 }}
                            />
                          </svg>
                        </div>

                        {/* X-axis labels */}
                        <div className="absolute bottom-0 left-8 right-0 flex justify-between text-xs text-gray-500">
                          <div>12 AM</div>
                          <div>4 AM</div>
                          <div>8 AM</div>
                          <div>12 PM</div>
                          <div>4 PM</div>
                          <div>8 PM</div>
                        </div>
                      </div>
                    </div>

                    <div className="mt-4 flex items-center justify-center">
                      <div className="rounded-md bg-blue-500/10 p-2 text-center text-sm text-blue-500">
                        Peak detection times: 8 AM - 10 AM and 4 PM - 6 PM
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </div>
            </TabsContent>
          </Tabs>
        </>
      )}
    </div>
  )
}
