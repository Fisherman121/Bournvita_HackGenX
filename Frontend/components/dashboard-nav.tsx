"use client"
import Link from "next/link"
import { usePathname } from "next/navigation"
import { motion } from "framer-motion"
import { BarChart3, ClipboardList, FileText, Home, LogOut, Settings, Users } from "lucide-react"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarTrigger,
} from "@/components/ui/sidebar"
import { cn } from "@/lib/utils"

export function DashboardNav() {
  const pathname = usePathname()

  const routes = [
    {
      title: "Dashboard",
      icon: Home,
      href: "/dashboard",
      variant: "default",
    },
    {
      title: "Tasks",
      icon: ClipboardList,
      href: "/dashboard/tasks",
      variant: "default",
    },
    {
      title: "Janitors",
      icon: Users,
      href: "/dashboard/janitors",
      variant: "default",
    },
    {
      title: "Reports",
      icon: FileText,
      href: "/dashboard/reports",
      variant: "default",
    },
    {
      title: "Analytics",
      icon: BarChart3,
      href: "/dashboard/analytics",
      variant: "default",
    },
    {
      title: "Settings",
      icon: Settings,
      href: "/dashboard/settings",
      variant: "default",
    },
  ]

  return (
    <Sidebar className="border-r border-gray-800">
      <SidebarHeader className="flex h-16 items-center border-b border-gray-800 px-4">
        <Link href="/dashboard" className="flex items-center gap-2">
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
          <span className="text-lg font-semibold text-white">EcoTrack</span>
        </Link>
        <div className="ml-auto md:hidden">
          <SidebarTrigger />
        </div>
      </SidebarHeader>
      <SidebarContent>
        <SidebarMenu>
          {routes.map((route) => (
            <SidebarMenuItem key={route.href}>
              <SidebarMenuButton
                asChild
                isActive={pathname === route.href}
                className={cn(
                  "transition-all",
                  pathname === route.href ? "bg-green-900/30 text-green-500" : "text-gray-400 hover:text-white",
                )}
              >
                <Link href={route.href}>
                  <route.icon className="h-5 w-5" />
                  <span>{route.title}</span>
                  {pathname === route.href && (
                    <motion.div
                      layoutId="sidebar-indicator"
                      className="absolute left-0 top-0 h-full w-1 bg-green-500"
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      transition={{ duration: 0.2 }}
                    />
                  )}
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
          ))}
        </SidebarMenu>
      </SidebarContent>
      <SidebarFooter className="border-t border-gray-800 p-4">
        <div className="flex items-center gap-3">
          <Avatar>
            <AvatarImage src="/placeholder.svg?height=40&width=40" alt="User" />
            <AvatarFallback className="bg-green-900 text-green-50">AD</AvatarFallback>
          </Avatar>
          <div className="flex flex-col">
            <span className="text-sm font-medium text-gray-200">Admin User</span>
            <span className="text-xs text-gray-400">admin@ecotrack.com</span>
          </div>
          <Button variant="ghost" size="icon" className="ml-auto text-gray-400 hover:text-white">
            <LogOut className="h-5 w-5" />
            <span className="sr-only">Log out</span>
          </Button>
        </div>
      </SidebarFooter>
    </Sidebar>
  )
}
