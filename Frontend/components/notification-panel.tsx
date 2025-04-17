"use client"

import { useState, useEffect } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { Bell } from "lucide-react"
import { Button } from "@/components/ui/button"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Separator } from "@/components/ui/separator"
import { cn } from "@/lib/utils"

type Notification = {
  id: string
  title: string
  description: string
  time: string
  read: boolean
  type: "detection" | "assignment" | "completion"
}

export function NotificationPanel() {
  const [isOpen, setIsOpen] = useState(false)
  const [notifications, setNotifications] = useState<Notification[]>([
    {
      id: "1",
      title: "New garbage detected",
      description: "Garbage detected at Downtown, Main Street",
      time: "Just now",
      read: false,
      type: "detection",
    },
    {
      id: "2",
      title: "Task assigned",
      description: "Task #1234 assigned to John Doe",
      time: "5 minutes ago",
      read: false,
      type: "assignment",
    },
    {
      id: "3",
      title: "Task completed",
      description: "Task #1230 marked as completed by Jane Smith",
      time: "1 hour ago",
      read: true,
      type: "completion",
    },
    {
      id: "4",
      title: "New garbage detected",
      description: "Garbage detected at Westside Park",
      time: "2 hours ago",
      read: true,
      type: "detection",
    },
  ])

  const unreadCount = notifications.filter((n) => !n.read).length

  // Close panel when clicking outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      const target = e.target as HTMLElement
      if (isOpen && !target.closest("[data-notification-panel]")) {
        setIsOpen(false)
      }
    }

    document.addEventListener("mousedown", handleClickOutside)
    return () => document.removeEventListener("mousedown", handleClickOutside)
  }, [isOpen])

  const markAsRead = (id: string) => {
    setNotifications(notifications.map((n) => (n.id === id ? { ...n, read: true } : n)))
  }

  const markAllAsRead = () => {
    setNotifications(notifications.map((n) => ({ ...n, read: true })))
  }

  return (
    <div className="relative" data-notification-panel>
      <Button
        variant="ghost"
        size="icon"
        className="relative text-gray-400 hover:text-white"
        onClick={() => setIsOpen(!isOpen)}
      >
        <Bell className="h-5 w-5" />
        {unreadCount > 0 && (
          <span className="absolute -right-1 -top-1 flex h-5 w-5 items-center justify-center rounded-full bg-green-500 text-xs font-medium text-white">
            {unreadCount}
          </span>
        )}
        <span className="sr-only">Notifications</span>
      </Button>

      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 10 }}
            transition={{ duration: 0.2 }}
            className="absolute right-0 top-12 z-50 w-80 rounded-lg border border-gray-800 bg-gray-900 shadow-lg"
          >
            <div className="flex items-center justify-between p-4">
              <h3 className="text-lg font-medium text-white">Notifications</h3>
              {unreadCount > 0 && (
                <Button
                  variant="ghost"
                  size="sm"
                  className="text-xs text-gray-400 hover:text-white"
                  onClick={markAllAsRead}
                >
                  Mark all as read
                </Button>
              )}
            </div>
            <Separator className="bg-gray-800" />
            <ScrollArea className="h-[350px]">
              {notifications.length > 0 ? (
                <div className="flex flex-col">
                  {notifications.map((notification) => (
                    <div
                      key={notification.id}
                      className={cn(
                        "flex cursor-pointer flex-col gap-1 p-4 transition-colors hover:bg-gray-800/50",
                        !notification.read && "bg-gray-800/20",
                      )}
                      onClick={() => markAsRead(notification.id)}
                    >
                      <div className="flex items-start justify-between">
                        <div className="flex items-center gap-2">
                          <div
                            className={cn(
                              "rounded-full p-1",
                              notification.type === "detection" && "bg-yellow-500/20",
                              notification.type === "assignment" && "bg-blue-500/20",
                              notification.type === "completion" && "bg-green-500/20",
                            )}
                          >
                            {notification.type === "detection" && (
                              <svg
                                className="h-3 w-3 text-yellow-500"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                              >
                                <path
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                  strokeWidth={2}
                                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                                />
                              </svg>
                            )}
                            {notification.type === "assignment" && (
                              <svg
                                className="h-3 w-3 text-blue-500"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                              >
                                <path
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                  strokeWidth={2}
                                  d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                                />
                              </svg>
                            )}
                            {notification.type === "completion" && (
                              <svg
                                className="h-3 w-3 text-green-500"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                              >
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                              </svg>
                            )}
                          </div>
                          <span className="font-medium text-gray-200">{notification.title}</span>
                        </div>
                        {!notification.read && <div className="h-2 w-2 rounded-full bg-green-500" />}
                      </div>
                      <p className="text-sm text-gray-400">{notification.description}</p>
                      <span className="text-xs text-gray-500">{notification.time}</span>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="flex h-full items-center justify-center p-4">
                  <p className="text-center text-sm text-gray-400">No notifications yet</p>
                </div>
              )}
            </ScrollArea>
            <Separator className="bg-gray-800" />
            <div className="p-2">
              <Button
                variant="ghost"
                size="sm"
                className="w-full justify-center text-sm text-gray-400 hover:text-white"
                onClick={() => setIsOpen(false)}
              >
                View all notifications
              </Button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
