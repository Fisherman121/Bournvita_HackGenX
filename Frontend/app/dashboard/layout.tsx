import type React from "react"
import { DashboardNav } from "@/components/dashboard-nav"
import { NotificationPanel } from "@/components/notification-panel"
import { SidebarProvider } from "@/components/ui/sidebar"

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      <SidebarProvider>
        <div className="flex min-h-screen">
          <DashboardNav />
          <div className="flex-1">
            <header className="sticky top-0 z-30 flex h-16 items-center gap-4 border-b border-gray-800 bg-gray-900/80 backdrop-blur-sm px-6">
              <div className="flex flex-1 items-center justify-end">
                <NotificationPanel />
              </div>
            </header>
            <main className="flex-1 p-6">{children}</main>
          </div>
        </div>
      </SidebarProvider>
    </div>
  )
}
