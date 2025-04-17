import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import Link from "next/link";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-4 bg-gradient-to-b from-gray-900 to-black">
      <Card className="w-full max-w-md bg-gray-800 border-gray-700">
        <CardHeader className="border-b border-gray-700">
          <CardTitle className="text-2xl text-white">Garbage Detector Dashboard</CardTitle>
          <CardDescription className="text-gray-400">
            Connect to your Flask backend and manage detection tasks
          </CardDescription>
        </CardHeader>
        <CardContent className="pt-6 space-y-4">
          <div className="rounded-md bg-amber-900/30 border border-amber-700/50 p-4">
            <h3 className="font-medium text-amber-500 mb-2">Flask API Connection</h3>
            <p className="text-gray-300 text-sm mb-4">
              To use this application, make sure your Flask API is running at:
              <code className="ml-2 px-2 py-1 bg-black/30 rounded text-amber-300 text-xs">
                http://localhost:8080
              </code>
            </p>
            <div className="text-xs text-gray-400">
              <p className="mb-1">• Run your Flask app with: <code className="text-green-400">python app.py</code></p>
              <p className="mb-1">• Ensure it's accessible from this application</p>
              <p>• Check the server logs if you're having connection issues</p>
            </div>
          </div>
          
          <div className="grid gap-2 mt-4">
            <Button asChild className="bg-green-600 hover:bg-green-700 text-white">
              <Link href="/janitor">
                Janitor Dashboard
              </Link>
            </Button>
            
            <Button asChild variant="outline" className="border-gray-600 text-gray-300 hover:bg-gray-700">
              <Link href="/api/flask-check" target="_blank">
                Test Flask Connection
              </Link>
            </Button>

            <Button asChild variant="ghost" className="text-gray-400 hover:text-white hover:bg-gray-700">
              <Link href="/dashboard">
                Admin Dashboard
              </Link>
            </Button>
          </div>
        </CardContent>
        <CardFooter className="border-t border-gray-700 flex justify-between">
          <p className="text-xs text-gray-500">Flask API must be running for the app to work</p>
        </CardFooter>
      </Card>
    </main>
  );
}
