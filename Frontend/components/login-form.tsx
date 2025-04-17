"use client"

import type React from "react"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { motion } from "framer-motion"
import { Loader2 } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"

export function LoginForm() {
  const router = useRouter()
  const [isLoading, setIsLoading] = useState(false)
  const [role, setRole] = useState<string>("")
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [error, setError] = useState("")

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")

    if (!email || !password || !role) {
      setError("Please fill in all fields")
      return
    }

    setIsLoading(true)

    // Simulate API call
    setTimeout(() => {
      setIsLoading(false)

      // Redirect based on role
      if (role === "janitor") {
        router.push("/janitor")
      } else {
        router.push("/dashboard")
      }
    }, 1500)
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="rounded-xl bg-black/20 backdrop-blur-lg border border-gray-800 shadow-xl p-6 w-full"
    >
      <div className="flex flex-col space-y-2 text-center mb-6">
        <h1 className="text-2xl font-semibold tracking-tight text-white">Smart Waste Management</h1>
        <p className="text-sm text-gray-400">Sign in to access your dashboard</p>
      </div>

      {error && (
        <div className="bg-red-500/10 border border-red-500/50 rounded-md p-3 mb-4">
          <p className="text-sm text-red-500">{error}</p>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="role" className="text-gray-300">
            Role
          </Label>
          <Select value={role} onValueChange={setRole}>
            <SelectTrigger id="role" className="bg-gray-900/50 border-gray-700 text-gray-200 focus:ring-green-500">
              <SelectValue placeholder="Select your role" />
            </SelectTrigger>
            <SelectContent className="bg-gray-900 border-gray-700">
              <SelectItem value="admin" className="text-gray-200 focus:bg-green-800/20">
                <div className="flex items-center gap-2">
                  <div className="bg-blue-500/20 p-1 rounded-md">
                    <svg className="h-4 w-4 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                      />
                    </svg>
                  </div>
                  Admin
                </div>
              </SelectItem>
              <SelectItem value="supervisor" className="text-gray-200 focus:bg-green-800/20">
                <div className="flex items-center gap-2">
                  <div className="bg-green-500/20 p-1 rounded-md">
                    <svg className="h-4 w-4 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                      />
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                      />
                    </svg>
                  </div>
                  Supervisor
                </div>
              </SelectItem>
              <SelectItem value="janitor" className="text-gray-200 focus:bg-green-800/20">
                <div className="flex items-center gap-2">
                  <div className="bg-yellow-500/20 p-1 rounded-md">
                    <svg className="h-4 w-4 text-yellow-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                      />
                    </svg>
                  </div>
                  Janitor
                </div>
              </SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="space-y-2">
          <Label htmlFor="email" className="text-gray-300">
            Email
          </Label>
          <Input
            id="email"
            type="email"
            placeholder="name@example.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="bg-gray-900/50 border-gray-700 text-gray-200 focus:ring-green-500"
            required
          />
        </div>

        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label htmlFor="password" className="text-gray-300">
              Password
            </Label>
            <button type="button" className="text-xs text-green-500 hover:text-green-400">
              Forgot password?
            </button>
          </div>
          <Input
            id="password"
            type="password"
            placeholder="••••••••"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="bg-gray-900/50 border-gray-700 text-gray-200 focus:ring-green-500"
            required
          />
        </div>

        <Button
          type="submit"
          className="w-full bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-500 hover:to-emerald-500 text-white"
          disabled={isLoading}
        >
          {isLoading ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Signing in...
            </>
          ) : (
            "Sign In"
          )}
        </Button>
      </form>
    </motion.div>
  )
}
