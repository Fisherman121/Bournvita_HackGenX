"use client"

import Link from "next/link"
import { ClipboardList, Plus } from "lucide-react"
import { usePathname } from "next/navigation"

export default function JanitorLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const pathname = usePathname()
  
  // Don't show FAB on the report page itself
  const showReportFab = !pathname.includes('/janitor/report')
  
  return (
    <>
      {children}
      
      {/* Floating Action Button for quick reporting */}
      {showReportFab && (
        <div className="fixed bottom-6 right-6 z-10">
          <Link href="/janitor/report">
            <button 
              className="flex items-center justify-center gap-2 rounded-full bg-green-600 p-4 text-white shadow-lg hover:bg-green-500 transition-colors"
              aria-label="Report an issue"
            >
              <Plus className="h-6 w-6" />
              <span className="sr-only md:not-sr-only md:inline-block">Report</span>
            </button>
          </Link>
        </div>
      )}
    </>
  )
} 