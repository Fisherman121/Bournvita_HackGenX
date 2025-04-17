import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { Menu, X, LayoutDashboard, ListChecks, Camera, MapPin, ChevronUp } from 'lucide-react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from './ui/dropdown-menu';
import { cn } from '@/lib/utils';

const Header = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container flex h-14 items-center justify-between">
        <div className="flex items-center ml-16 sm:ml-20 md:ml-0">
          <button
            className="inline-flex h-10 w-10 items-center justify-center rounded-md border border-slate-400 bg-white p-1 text-slate-700 shadow-sm hover:bg-slate-100 hover:text-slate-900 mr-2 relative z-[1100]"
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            aria-label="Toggle menu"
          >
            {isMenuOpen ? (
              <X className="h-6 w-6" />
            ) : (
              <Menu className="h-6 w-6" />
            )}
          </button>
          <span className="text-lg font-semibold">Garbage Cleaner</span>
        </div>
        
        {/* Removed the horizontal navigation */}
      </div>

      {isMenuOpen && (
        <div className="absolute left-0 top-14 w-full border-b bg-background z-50 shadow-md">
          <div className="container py-3 ml-16 sm:ml-20 md:ml-0">
            <div className="flex flex-col space-y-1">
              <Link
                to="/"
                className="flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md hover:bg-accent hover:text-accent-foreground"
                onClick={() => setIsMenuOpen(false)}
              >
                <LayoutDashboard className="h-4 w-4" />
                Dashboard
              </Link>
              <Link
                to="/tasks"
                className="flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md hover:bg-accent hover:text-accent-foreground"
                onClick={() => setIsMenuOpen(false)}
              >
                <ListChecks className="h-4 w-4" />
                Tasks
              </Link>
              <Link
                to="/camera"
                className="flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md hover:bg-accent hover:text-accent-foreground"
                onClick={() => setIsMenuOpen(false)}
              >
                <Camera className="h-4 w-4" />
                Camera
              </Link>
              <div className="px-4 py-2">
                <div className="flex items-center gap-2 text-sm font-medium mb-2">
                  <MapPin className="h-4 w-4" />
                  Zones
                </div>
                <div className="flex flex-col space-y-1 pl-6">
                  <Link
                    to="/zones/1"
                    className="text-sm hover:bg-accent hover:text-accent-foreground px-2 py-1 rounded-md"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    Zone 1
                  </Link>
                  <Link
                    to="/zones/2"
                    className="text-sm hover:bg-accent hover:text-accent-foreground px-2 py-1 rounded-md"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    Zone 2
                  </Link>
                  <Link
                    to="/zones/3"
                    className="text-sm hover:bg-accent hover:text-accent-foreground px-2 py-1 rounded-md"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    Zone 3
                  </Link>
                </div>
              </div>
              <div className="mt-4 pt-4 border-t">
                <button
                  className="flex items-center justify-center gap-2 w-full px-4 py-3 text-sm font-medium rounded-md bg-gray-100 hover:bg-gray-200 text-gray-700"
                  onClick={() => setIsMenuOpen(false)}
                >
                  <ChevronUp className="h-4 w-4" />
                  Close Menu
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </header>
  );
};

export default Header; 