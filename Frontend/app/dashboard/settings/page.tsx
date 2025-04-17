"use client"

import { useState } from "react"
import { motion } from "framer-motion"
import { BellOff, HelpCircle, Info, LogOut, Moon, Save, Shield, Sun, User, Download } from "lucide-react"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Switch } from "@/components/ui/switch"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Textarea } from "@/components/ui/textarea"

export default function SettingsPage() {
  const [theme, setTheme] = useState("dark")
  const [notificationsEnabled, setNotificationsEnabled] = useState(true)
  const [emailNotifications, setEmailNotifications] = useState(true)
  const [pushNotifications, setPushNotifications] = useState(true)
  const [language, setLanguage] = useState("en")
  const [timeFormat, setTimeFormat] = useState("24h")
  const [mapProvider, setMapProvider] = useState("google")
  const [isLoading, setIsLoading] = useState(false)

  const handleSaveProfile = () => {
    setIsLoading(true)
    // Simulate API call
    setTimeout(() => {
      setIsLoading(false)
      alert("Profile settings saved successfully!")
    }, 1000)
  }

  const handleSaveNotifications = () => {
    setIsLoading(true)
    // Simulate API call
    setTimeout(() => {
      setIsLoading(false)
      alert("Notification settings saved successfully!")
    }, 1000)
  }

  const handleSaveAppearance = () => {
    setIsLoading(true)
    // Simulate API call
    setTimeout(() => {
      setIsLoading(false)
      alert("Appearance settings saved successfully!")
    }, 1000)
  }

  const handleSaveSecurity = () => {
    setIsLoading(true)
    // Simulate API call
    setTimeout(() => {
      setIsLoading(false)
      alert("Security settings saved successfully!")
    }, 1000)
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-white">Settings</h1>
        <p className="text-gray-400">Manage your account settings and preferences.</p>
      </div>

      <Tabs defaultValue="profile" className="space-y-4">
        <TabsList className="bg-gray-800/50">
          <TabsTrigger
            value="profile"
            className="data-[state=active]:bg-green-900/30 data-[state=active]:text-green-500"
          >
            Profile
          </TabsTrigger>
          <TabsTrigger
            value="notifications"
            className="data-[state=active]:bg-green-900/30 data-[state=active]:text-green-500"
          >
            Notifications
          </TabsTrigger>
          <TabsTrigger
            value="appearance"
            className="data-[state=active]:bg-green-900/30 data-[state=active]:text-green-500"
          >
            Appearance
          </TabsTrigger>
          <TabsTrigger
            value="security"
            className="data-[state=active]:bg-green-900/30 data-[state=active]:text-green-500"
          >
            Security
          </TabsTrigger>
        </TabsList>

        <TabsContent value="profile" className="space-y-4">
          <Card className="bg-gray-900/50 border-gray-800">
            <CardHeader>
              <CardTitle>Profile Information</CardTitle>
              <CardDescription>Update your personal information and profile settings.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex flex-col items-center space-y-4 sm:flex-row sm:items-start sm:space-x-4 sm:space-y-0">
                <div className="relative">
                  <Avatar className="h-24 w-24">
                    <AvatarImage src="/placeholder.svg?height=96&width=96" alt="Profile" />
                    <AvatarFallback className="bg-green-900 text-green-50 text-xl">AD</AvatarFallback>
                  </Avatar>
                  <Button
                    size="sm"
                    className="absolute -bottom-2 -right-2 h-8 w-8 rounded-full bg-green-600 p-0 text-white hover:bg-green-500"
                  >
                    <User className="h-4 w-4" />
                    <span className="sr-only">Change Avatar</span>
                  </Button>
                </div>
                <div className="space-y-1 text-center sm:text-left">
                  <h3 className="text-lg font-medium text-white">Admin User</h3>
                  <p className="text-sm text-gray-400">admin@ecotrack.com</p>
                  <Badge className="bg-green-500/20 text-green-500 hover:bg-green-500/30">Administrator</Badge>
                </div>
              </div>

              <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="first-name" className="text-gray-300">
                    First Name
                  </Label>
                  <Input
                    id="first-name"
                    defaultValue="Admin"
                    className="bg-gray-800/50 border-gray-700 text-gray-200 focus-visible:ring-green-500"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="last-name" className="text-gray-300">
                    Last Name
                  </Label>
                  <Input
                    id="last-name"
                    defaultValue="User"
                    className="bg-gray-800/50 border-gray-700 text-gray-200 focus-visible:ring-green-500"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="email" className="text-gray-300">
                    Email
                  </Label>
                  <Input
                    id="email"
                    type="email"
                    defaultValue="admin@ecotrack.com"
                    className="bg-gray-800/50 border-gray-700 text-gray-200 focus-visible:ring-green-500"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="phone" className="text-gray-300">
                    Phone Number
                  </Label>
                  <Input
                    id="phone"
                    type="tel"
                    defaultValue="+1 (555) 123-4567"
                    className="bg-gray-800/50 border-gray-700 text-gray-200 focus-visible:ring-green-500"
                  />
                </div>
                <div className="space-y-2 sm:col-span-2">
                  <Label htmlFor="bio" className="text-gray-300">
                    Bio
                  </Label>
                  <Textarea
                    id="bio"
                    defaultValue="System administrator for the EcoTrack waste management platform."
                    className="min-h-[100px] bg-gray-800/50 border-gray-700 text-gray-200 focus-visible:ring-green-500"
                  />
                </div>
              </div>
            </CardContent>
            <CardFooter className="border-t border-gray-800 flex justify-between">
              <Button
                variant="outline"
                className="border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white"
              >
                Cancel
              </Button>
              <Button
                className="bg-green-600 hover:bg-green-500 text-white"
                onClick={handleSaveProfile}
                disabled={isLoading}
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
                    Saving...
                  </>
                ) : (
                  <>
                    <Save className="mr-2 h-4 w-4" />
                    Save Changes
                  </>
                )}
              </Button>
            </CardFooter>
          </Card>

          <Card className="bg-gray-900/50 border-gray-800">
            <CardHeader>
              <CardTitle>Role & Permissions</CardTitle>
              <CardDescription>Manage your role and access permissions.</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex items-center justify-between rounded-md border border-gray-800 bg-gray-800/30 p-4">
                  <div className="space-y-0.5">
                    <div className="text-sm font-medium text-white">Administrator</div>
                    <div className="text-xs text-gray-400">Full access to all system features and settings</div>
                  </div>
                  <Badge className="bg-green-500/20 text-green-500">Active</Badge>
                </div>

                <div className="space-y-3">
                  <Label className="text-gray-300">Access Permissions</Label>
                  <div className="space-y-2">
                    {[
                      { name: "Dashboard Access", description: "View and interact with the main dashboard" },
                      { name: "Task Management", description: "Create, assign, and manage tasks" },
                      { name: "User Management", description: "Add, edit, and remove users" },
                      { name: "System Settings", description: "Configure system-wide settings" },
                      { name: "Analytics & Reports", description: "View and export analytics and reports" },
                    ].map((permission, i) => (
                      <div key={i} className="flex items-center justify-between rounded-md border border-gray-800 p-3">
                        <div>
                          <div className="text-sm font-medium text-gray-200">{permission.name}</div>
                          <div className="text-xs text-gray-500">{permission.description}</div>
                        </div>
                        <Switch defaultChecked disabled />
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="notifications" className="space-y-4">
          <Card className="bg-gray-900/50 border-gray-800">
            <CardHeader>
              <CardTitle>Notification Preferences</CardTitle>
              <CardDescription>Configure how and when you receive notifications.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label className="text-base text-gray-200">Enable Notifications</Label>
                  <p className="text-sm text-gray-500">Receive notifications about system events</p>
                </div>
                <Switch checked={notificationsEnabled} onCheckedChange={setNotificationsEnabled} />
              </div>

              {notificationsEnabled && (
                <motion.div
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: "auto" }}
                  exit={{ opacity: 0, height: 0 }}
                  transition={{ duration: 0.3 }}
                  className="space-y-4 rounded-md border border-gray-800 bg-gray-800/30 p-4"
                >
                  <div className="flex items-center justify-between">
                    <div className="space-y-0.5">
                      <Label className="text-sm text-gray-200">Email Notifications</Label>
                      <p className="text-xs text-gray-500">Receive notifications via email</p>
                    </div>
                    <Switch checked={emailNotifications} onCheckedChange={setEmailNotifications} />
                  </div>

                  <div className="flex items-center justify-between">
                    <div className="space-y-0.5">
                      <Label className="text-sm text-gray-200">Push Notifications</Label>
                      <p className="text-xs text-gray-500">Receive notifications in the browser</p>
                    </div>
                    <Switch checked={pushNotifications} onCheckedChange={setPushNotifications} />
                  </div>

                  <div className="space-y-2">
                    <Label className="text-sm text-gray-200">Notification Types</Label>
                    <div className="space-y-2">
                      {[
                        { type: "New Garbage Detection", description: "When new garbage is detected by the system" },
                        { type: "Task Assignment", description: "When a task is assigned to a janitor" },
                        { type: "Task Status Change", description: "When a task status is updated" },
                        { type: "Task Completion", description: "When a task is marked as completed" },
                        { type: "System Alerts", description: "Important system alerts and notifications" },
                      ].map((item, i) => (
                        <div
                          key={i}
                          className="flex items-center justify-between rounded-md border border-gray-800 p-3"
                        >
                          <div>
                            <div className="text-sm font-medium text-gray-200">{item.type}</div>
                            <div className="text-xs text-gray-500">{item.description}</div>
                          </div>
                          <Switch defaultChecked />
                        </div>
                      ))}
                    </div>
                  </div>
                </motion.div>
              )}

              <div className="space-y-2">
                <Label className="text-gray-300">Notification Frequency</Label>
                <RadioGroup defaultValue="realtime">
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="realtime" id="realtime" className="border-gray-700 text-green-500" />
                    <Label htmlFor="realtime" className="text-gray-200">
                      Real-time
                    </Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="hourly" id="hourly" className="border-gray-700 text-green-500" />
                    <Label htmlFor="hourly" className="text-gray-200">
                      Hourly Digest
                    </Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="daily" id="daily" className="border-gray-700 text-green-500" />
                    <Label htmlFor="daily" className="text-gray-200">
                      Daily Digest
                    </Label>
                  </div>
                </RadioGroup>
              </div>
            </CardContent>
            <CardFooter className="border-t border-gray-800 flex justify-between">
              <Button
                variant="outline"
                className="border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white"
              >
                Reset to Defaults
              </Button>
              <Button
                className="bg-green-600 hover:bg-green-500 text-white"
                onClick={handleSaveNotifications}
                disabled={isLoading}
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
                    Saving...
                  </>
                ) : (
                  <>
                    <Save className="mr-2 h-4 w-4" />
                    Save Changes
                  </>
                )}
              </Button>
            </CardFooter>
          </Card>
        </TabsContent>

        <TabsContent value="appearance" className="space-y-4">
          <Card className="bg-gray-900/50 border-gray-800">
            <CardHeader>
              <CardTitle>Appearance Settings</CardTitle>
              <CardDescription>Customize the look and feel of the application.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label className="text-gray-300">Theme</Label>
                <div className="grid grid-cols-3 gap-4">
                  <div
                    className={`cursor-pointer rounded-md border p-4 transition-colors ${
                      theme === "light"
                        ? "border-green-500 bg-green-900/20"
                        : "border-gray-800 bg-gray-800/30 hover:bg-gray-800/50"
                    }`}
                    onClick={() => setTheme("light")}
                  >
                    <div className="flex flex-col items-center gap-2">
                      <Sun className="h-6 w-6 text-gray-300" />
                      <span className="text-sm font-medium text-gray-200">Light</span>
                    </div>
                  </div>
                  <div
                    className={`cursor-pointer rounded-md border p-4 transition-colors ${
                      theme === "dark"
                        ? "border-green-500 bg-green-900/20"
                        : "border-gray-800 bg-gray-800/30 hover:bg-gray-800/50"
                    }`}
                    onClick={() => setTheme("dark")}
                  >
                    <div className="flex flex-col items-center gap-2">
                      <Moon className="h-6 w-6 text-gray-300" />
                      <span className="text-sm font-medium text-gray-200">Dark</span>
                    </div>
                  </div>
                  <div
                    className={`cursor-pointer rounded-md border p-4 transition-colors ${
                      theme === "system"
                        ? "border-green-500 bg-green-900/20"
                        : "border-gray-800 bg-gray-800/30 hover:bg-gray-800/50"
                    }`}
                    onClick={() => setTheme("system")}
                  >
                    <div className="flex flex-col items-center gap-2">
                      <svg className="h-6 w-6 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                        />
                      </svg>
                      <span className="text-sm font-medium text-gray-200">System</span>
                    </div>
                  </div>
                </div>
              </div>

              <div className="space-y-2">
                <Label className="text-gray-300">Language</Label>
                <Select value={language} onValueChange={setLanguage}>
                  <SelectTrigger className="bg-gray-800/50 border-gray-700 text-gray-200 focus:ring-green-500">
                    <SelectValue placeholder="Select language" />
                  </SelectTrigger>
                  <SelectContent className="bg-gray-900 border-gray-800">
                    <SelectItem value="en" className="text-gray-200">
                      English
                    </SelectItem>
                    <SelectItem value="es" className="text-gray-200">
                      Spanish
                    </SelectItem>
                    <SelectItem value="fr" className="text-gray-200">
                      French
                    </SelectItem>
                    <SelectItem value="de" className="text-gray-200">
                      German
                    </SelectItem>
                    <SelectItem value="zh" className="text-gray-200">
                      Chinese
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label className="text-gray-300">Time Format</Label>
                <RadioGroup value={timeFormat} onValueChange={setTimeFormat}>
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="12h" id="12h" className="border-gray-700 text-green-500" />
                    <Label htmlFor="12h" className="text-gray-200">
                      12-hour (1:30 PM)
                    </Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="24h" id="24h" className="border-gray-700 text-green-500" />
                    <Label htmlFor="24h" className="text-gray-200">
                      24-hour (13:30)
                    </Label>
                  </div>
                </RadioGroup>
              </div>

              <div className="space-y-2">
                <Label className="text-gray-300">Map Provider</Label>
                <Select value={mapProvider} onValueChange={setMapProvider}>
                  <SelectTrigger className="bg-gray-800/50 border-gray-700 text-gray-200 focus:ring-green-500">
                    <SelectValue placeholder="Select map provider" />
                  </SelectTrigger>
                  <SelectContent className="bg-gray-900 border-gray-800">
                    <SelectItem value="google" className="text-gray-200">
                      Google Maps
                    </SelectItem>
                    <SelectItem value="mapbox" className="text-gray-200">
                      Mapbox
                    </SelectItem>
                    <SelectItem value="osm" className="text-gray-200">
                      OpenStreetMap
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
            <CardFooter className="border-t border-gray-800 flex justify-between">
              <Button
                variant="outline"
                className="border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white"
              >
                Reset to Defaults
              </Button>
              <Button
                className="bg-green-600 hover:bg-green-500 text-white"
                onClick={handleSaveAppearance}
                disabled={isLoading}
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
                    Saving...
                  </>
                ) : (
                  <>
                    <Save className="mr-2 h-4 w-4" />
                    Save Changes
                  </>
                )}
              </Button>
            </CardFooter>
          </Card>
        </TabsContent>

        <TabsContent value="security" className="space-y-4">
          <Card className="bg-gray-900/50 border-gray-800">
            <CardHeader>
              <CardTitle>Security Settings</CardTitle>
              <CardDescription>Manage your account security and authentication options.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="current-password" className="text-gray-300">
                  Current Password
                </Label>
                <Input
                  id="current-password"
                  type="password"
                  placeholder="••••••••"
                  className="bg-gray-800/50 border-gray-700 text-gray-200 focus-visible:ring-green-500"
                />
              </div>
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="new-password" className="text-gray-300">
                    New Password
                  </Label>
                  <Input
                    id="new-password"
                    type="password"
                    placeholder="••••••••"
                    className="bg-gray-800/50 border-gray-700 text-gray-200 focus-visible:ring-green-500"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="confirm-password" className="text-gray-300">
                    Confirm New Password
                  </Label>
                  <Input
                    id="confirm-password"
                    type="password"
                    placeholder="••••••••"
                    className="bg-gray-800/50 border-gray-700 text-gray-200 focus-visible:ring-green-500"
                  />
                </div>
              </div>

              <div className="rounded-md border border-gray-800 bg-gray-800/30 p-4">
                <div className="flex items-center gap-3">
                  <Shield className="h-5 w-5 text-green-500" />
                  <div className="text-sm font-medium text-gray-200">Password Requirements</div>
                </div>
                <div className="mt-2 space-y-1 text-xs text-gray-400">
                  <p>• Minimum 8 characters long</p>
                  <p>• At least one uppercase letter</p>
                  <p>• At least one lowercase letter</p>
                  <p>• At least one number</p>
                  <p>• At least one special character</p>
                </div>
              </div>

              <div className="space-y-2">
                <Label className="text-gray-300">Two-Factor Authentication</Label>
                <div className="rounded-md border border-gray-800 bg-gray-800/30 p-4">
                  <div className="flex items-center justify-between">
                    <div className="space-y-0.5">
                      <div className="text-sm font-medium text-gray-200">Enable Two-Factor Authentication</div>
                      <div className="text-xs text-gray-500">Add an extra layer of security to your account</div>
                    </div>
                    <Switch defaultChecked={false} />
                  </div>
                </div>
              </div>

              <div className="space-y-2">
                <Label className="text-gray-300">Session Management</Label>
                <div className="space-y-2">
                  <div className="rounded-md border border-gray-800 bg-gray-800/30 p-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="text-sm font-medium text-gray-200">Current Session</div>
                        <div className="text-xs text-gray-500">Chrome on Windows • 192.168.1.1</div>
                        <div className="mt-1 text-xs text-green-500">Active now</div>
                      </div>
                      <Badge className="bg-green-500/20 text-green-500">Current</Badge>
                    </div>
                  </div>
                  <div className="rounded-md border border-gray-800 bg-gray-800/30 p-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="text-sm font-medium text-gray-200">Previous Session</div>
                        <div className="text-xs text-gray-500">Safari on macOS • 192.168.1.2</div>
                        <div className="mt-1 text-xs text-gray-500">Last active: 2 days ago</div>
                      </div>
                      <Button
                        variant="outline"
                        size="sm"
                        className="border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white"
                      >
                        Revoke
                      </Button>
                    </div>
                  </div>
                </div>
              </div>
            </CardContent>
            <CardFooter className="border-t border-gray-800 flex justify-between">
              <Button
                variant="outline"
                className="border-gray-700 bg-gray-800 text-gray-200 hover:bg-gray-700 hover:text-white"
              >
                <LogOut className="mr-2 h-4 w-4" />
                Sign Out of All Devices
              </Button>
              <Button
                className="bg-green-600 hover:bg-green-500 text-white"
                onClick={handleSaveSecurity}
                disabled={isLoading}
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
                    Saving...
                  </>
                ) : (
                  <>
                    <Save className="mr-2 h-4 w-4" />
                    Save Changes
                  </>
                )}
              </Button>
            </CardFooter>
          </Card>

          <Card className="bg-gray-900/50 border-gray-800">
            <CardHeader>
              <CardTitle>Account Actions</CardTitle>
              <CardDescription>Manage your account status and data.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="rounded-md border border-yellow-500/20 bg-yellow-500/5 p-4">
                <div className="flex items-start gap-3">
                  <Info className="h-5 w-5 text-yellow-500" />
                  <div>
                    <div className="text-sm font-medium text-yellow-500">Export Your Data</div>
                    <div className="mt-1 text-xs text-gray-400">
                      Download a copy of all your personal data and activity history.
                    </div>
                    <Button
                      size="sm"
                      variant="outline"
                      className="mt-2 border-yellow-500/20 bg-yellow-500/10 text-yellow-500 hover:bg-yellow-500/20"
                    >
                      <Download className="mr-2 h-3 w-3" />
                      Export Data
                    </Button>
                  </div>
                </div>
              </div>

              <div className="rounded-md border border-red-500/20 bg-red-500/5 p-4">
                <div className="flex items-start gap-3">
                  <HelpCircle className="h-5 w-5 text-red-500" />
                  <div>
                    <div className="text-sm font-medium text-red-500">Deactivate Account</div>
                    <div className="mt-1 text-xs text-gray-400">
                      Temporarily disable your account. You can reactivate it later.
                    </div>
                    <Button
                      size="sm"
                      variant="outline"
                      className="mt-2 border-red-500/20 bg-red-500/10 text-red-500 hover:bg-red-500/20"
                    >
                      Deactivate Account
                    </Button>
                  </div>
                </div>
              </div>

              <div className="rounded-md border border-red-500/20 bg-red-500/5 p-4">
                <div className="flex items-start gap-3">
                  <BellOff className="h-5 w-5 text-red-500" />
                  <div>
                    <div className="text-sm font-medium text-red-500">Delete Account</div>
                    <div className="mt-1 text-xs text-gray-400">
                      Permanently delete your account and all associated data. This action cannot be undone.
                    </div>
                    <Button
                      size="sm"
                      variant="outline"
                      className="mt-2 border-red-500/20 bg-red-500/10 text-red-500 hover:bg-red-500/20"
                    >
                      Delete Account
                    </Button>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
