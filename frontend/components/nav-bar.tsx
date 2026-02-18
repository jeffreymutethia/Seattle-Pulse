/* eslint-disable @typescript-eslint/no-unused-vars */
/* eslint-disable @typescript-eslint/no-explicit-any */
"use client";

import React, { useState, useEffect } from "react";
import { MapPin, Bell, MessageCircleIcon, ChevronDown, Search, Menu, Settings, LogOut } from "lucide-react";
import { Button } from "./ui/button";
import { usePathname, useRouter } from "next/navigation";
import { cn } from "@/lib/utils";
import dynamic from "next/dynamic";
import { useNotificationContext } from "@/app/context/notification-context";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  DropdownMenuSeparator,
} from "./ui/dropdown-menu";
import { Input } from "./ui/input";
import { useHomeLocationSearch } from "@/app/hooks/use-location-search";
import { AuthPopup } from "./auth/auth-popup";
import Image from "next/image";
import { apiClient } from "@/app/api/api-client";

// Dynamic import outside component to prevent re-creation
const SearchWithResults = dynamic(() => import("./search-component"), {
  ssr: false,
  loading: () => null,
});

// Hard-coded launch set as per specifications
const defaultNeighborhoods = [
  { name: "Seattle", value: "Seattle" },
  { name: "Capitol Hill", value: "Capitol Hill" },
  { name: "Ballard", value: "Ballard" },
  { name: "U District", value: "U District" },
  { name: "Outside Seattle", value: "Outside Seattle" },
];

const NavBar = ({
  title = "Feed",
  showLocationSelector = true,
  showSearch = true,
  location = "Seattle",
  showNotification = true,
  showMessage = true,
  onLocationChange = () => {},
  isAuthenticated = false,
}: {
  title?: string;
  showLocationSelector?: boolean;
  showSearch?: boolean;
  location?: string;
  showNotification?: boolean;
  showMessage?: boolean;
  onLocationChange?: (location: string) => void;
  isAuthenticated?: boolean;
}) => {
  const router = useRouter();
  const [searchReady, setSearchReady] = useState(false);
  
  useEffect(() => {
    const run = () => setSearchReady(true);
    if (typeof (window as any).requestIdleCallback === "function") {
      (window as any).requestIdleCallback(run);
    } else {
      setTimeout(run, 100);
    }
  }, []);

  // Keyboard detection for mobile
  useEffect(() => {
    const handleResize = () => {
      const initialHeight = window.innerHeight;
      const currentHeight = window.innerHeight;
      const heightDifference = initialHeight - currentHeight;
      
      // If height decreased significantly, keyboard is likely open
      setIsKeyboardOpen(heightDifference > 150);
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);
  const pathname = usePathname();
  const { notificationCount } = useNotificationContext();
  const { loadOptions, isLoading, launchSet } = useHomeLocationSearch();
  
  const getInitialLocation = () => {
    if (typeof window !== "undefined") {
      const savedLocation = sessionStorage.getItem("feedLocation");
      if (savedLocation) {
        return savedLocation;
      }
    }
    return location;
  };
  
  const [selectedNeighborhood, setSelectedNeighborhood] = useState(getInitialLocation());
  const [searchTerm, setSearchTerm] = useState("");
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [showAuthPopup, setShowAuthPopup] = useState(false);
  const [isKeyboardOpen, setIsKeyboardOpen] = useState(false);

  const handleNeighborhoodChange = (neighborhood: string) => {
   
    setSelectedNeighborhood(neighborhood);
    setIsDropdownOpen(false);
    setSearchTerm("");
    setSearchResults([]);
    onLocationChange(neighborhood);
  };

  const handleNeighborhoodSelect = (option: any) => {
    const displayLabel = option?.label ?? ""; // dropdown_value per hook mapping
    // Use the full dropdown_value (label) for API calls, not just the city
    // The API expects the full location string like "Seattle, WA" not just "Seattle"
    const locationToUse = option?.value || displayLabel;
    setSelectedNeighborhood(displayLabel);
    setIsDropdownOpen(false);
    setSearchTerm("");
    setSearchResults([]);
    // Pass the full location string to the API, not just the city
    onLocationChange(locationToUse);
  };

  // Update selected neighborhood when location prop changes
  useEffect(() => {
    // Check for saved location first, then use prop
    const savedLocation = typeof window !== "undefined" 
      ? sessionStorage.getItem("feedLocation") 
      : null;
    const locationToUse = savedLocation || location;
    
    // For display, show a readable version of the location
    // If it's a long location string, show just the main part (first part before comma)
    // But keep the full string for API calls
    const displayName = locationToUse.includes(',') 
      ? locationToUse.split(',')[0].trim() 
      : locationToUse;
    setSelectedNeighborhood(displayName);
  }, [location]);

  const extractCityName = (locationLabel: string): string => {
    const cityName = locationLabel.split(',')[0].trim();
    return cityName;
  };

  // Handle search functionality for location selector
  const handleLocationSearch = (term: string) => {
    setSearchTerm(term);
    if (term.trim()) {
      loadOptions(term.trim(), (options) => {
        setSearchResults(Array.isArray(options) ? options : []);
      });
    } else {
      setSearchResults([]);
    }
  };

  // Handle location search input changes
  const handleLocationInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    handleLocationSearch(e.target.value);
  };

  const handleLogout = async () => {
    try {
      await apiClient.post("/auth/logout");
      sessionStorage.removeItem("user");
      router.push("/");
    } catch (error) {
      console.error("Logout failed:", error);
    }
  };

  // Component to handle search with auth check
  const SearchWrapper = () => {
    if (!isAuthenticated) {
      return (
        <div 
          className="w-full cursor-pointer"
          onClick={() => setShowAuthPopup(true)}
        >
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground pointer-events-none" />
            <div className="w-full md:w-[530px] pl-9 rounded-full border border-[#ABB0B9] bg-background px-3 py-2 transition-all duration-200 outline-none focus:border-gray-400 focus:ring-1 focus:ring-gray-400 cursor-pointer">
              <span className="text-muted-foreground">Search</span>
            </div>
          </div>
        </div>
      );
    }
    return <SearchWithResults />;
  };

  return (
    <div className="space-y-6">
      {/* Desktop Layout */}
      <div className="hidden md:grid grid-cols-3 items-center mb-4">
        {/* Left: Title */}
        <div className="flex items-center">
          <h1 className="text-2xl font-bold text-black">{title}</h1>
        </div>
        {/* Center: Search Box */}
        <div className="flex justify-center">
          {showSearch && (
            <div className="w-full max-w-md">
              {searchReady ? <SearchWrapper /> : <div className="h-10" />}
            </div>
          )}
        </div>
        {/* Right: Buttons - Only show if authenticated */}
        <div className="flex items-center justify-end">
          {isAuthenticated && (
            <div className="flex gap-4">
              {showNotification && (
                <Button
                  onClick={() => router.push(`/notification`)}
                  size="icon"
                  variant="ghost"
                  className={cn(
                    "relative rounded-full bg-white w-11 h-11 border-[#E2E8F0] border-2",
                    pathname === "/notification"
                      ? "bg-[#000000] hover:bg-black"
                      : ""
                  )}
                >
                  <Bell
                    className={cn(
                      "h-5 w-5",
                      pathname === "/notification" ? "text-white" : "text-black"
                    )}
                  />
                  {notificationCount > 0 && (
                    <span className="absolute -right-1 -top-0.5 h-4 w-4 rounded-full bg-red-500 text-[10px] font-medium text-white flex items-center justify-center">
                      {notificationCount}
                    </span>
                  )}
                </Button>
              )}
              {showMessage && (
                <Button
                  onClick={() => router.push(`/message`)}
                  size="icon"
                  variant="ghost"
                  className={cn(
                    "relative rounded-full bg-white w-11 h-11 border-[#E2E8F0] border-2",
                    pathname === "/message"
                      ? "bg-[#000000] hover:bg-black"
                      : ""
                  )}
                >
                  <MessageCircleIcon
                    className={cn(
                      "h-5 w-5",
                      pathname === "/message" ? "text-white" : "text-black"
                    )}
                  />
                </Button>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Mobile Layout */}
      <div className="md:hidden">
        {/* Title and Buttons Row */}
        <div className="flex items-center justify-between mb-4">
          <Image 
          src="https://seattlepulse-logos.s3.us-east-1.amazonaws.com/Seattle+Pulse_Logo/sp_full+color/sp_full+color_light+background/sp_logo_color_light_bg_1024px_PNG24.png" alt="Seattle Pulse" width={56} height={56} className="object-contain"
          />
          <div className="flex gap-4">
            {/* Message Icon - Always visible */}
            {showNotification && (
              <Button
                onClick={() => {
                  if (isAuthenticated) {
                    router.push(`/message`);
                  } else {
                    setShowAuthPopup(true);
                  }
                }}
                size="icon"
                variant="ghost"
                className={cn(
                  "relative rounded-full bg-white w-11 h-11 border-[#E2E8F0] border-2",
                  pathname === "/message"
                    ? "bg-[#000000] hover:bg-black"
                    : ""
                )}
              >
                <Image
                  src="/Dialog.png"
                  alt="Dialog"
                  width={20}
                  height={20}
                  className={cn(
                    "h-5 w-5",
                    pathname === "/message" ? "filter invert" : ""
                  )}
                />
                {isAuthenticated && notificationCount > 0 && (
                  <span className="absolute -right-1 -top-0.5 h-4 w-4 rounded-full bg-red-500 text-[10px] font-medium text-white flex items-center justify-center">
                    {notificationCount}
                  </span>
                )}
              </Button>
            )}
            
            {/* More Menu - Always visible */}
            {showMessage && (
              <>
                {isAuthenticated ? (
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button
                        size="icon"
                        variant="ghost"
                        className={cn(
                          "relative rounded-full bg-white w-11 h-11 border-[#E2E8F0] border-2"
                        )}
                        aria-label="More"
                      >
                        <Menu className="h-5 w-5 text-black" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end" className="w-56">
                      <DropdownMenuItem onClick={() => router.push(`/setting`)}>
                        <Settings className="mr-2 h-4 w-4" />
                        <span>Settings</span>
                      </DropdownMenuItem>
                      <DropdownMenuSeparator />
                      <DropdownMenuItem onClick={handleLogout} className="text-red-600 focus:text-red-600">
                        <LogOut className="mr-2 h-4 w-4" />
                        <span>Logout</span>
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                ) : (
                  <Button
                    onClick={() => setShowAuthPopup(true)}
                    size="icon"
                    variant="ghost"
                    className={cn(
                      "relative rounded-full bg-white w-11 h-11 border-[#E2E8F0] border-2"
                    )}
                    aria-label="More"
                  >
                    <Menu className="h-5 w-5 text-black" />
                  </Button>
                )}
              </>
            )}
          </div>
        </div>
        {/* Centered Search Box */}
        {showSearch && (
          <div className="flex justify-center mb-4 px-4">
            <div className="w-full max-w-md">
              {searchReady ? <SearchWrapper /> : <div className="h-10" />}
            </div>
          </div>
        )}
      </div>

      {/* Neighborhood Filter with Dropdown - Show for all users on landing page */}
      {showLocationSelector && (
        <div className="flex items-center justify-center gap-2 mb-6 pb-3">
          <MapPin className="h-4 w-4 text-muted-foreground" />
          <span className="text-muted-foreground text-base">
            Happening in
          </span>
          <DropdownMenu open={isDropdownOpen} onOpenChange={setIsDropdownOpen}>
            <DropdownMenuTrigger asChild>
              <Button
                variant="ghost"
                className="font-semibold text-base flex items-center gap-2"
              >
                {selectedNeighborhood}
                <ChevronDown className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent 
              align="center" 
              className={cn(
                "p-2 md:w-64 w-[calc(100vw-2rem)] max-w-sm",
                isKeyboardOpen && "fixed bottom-4 left-1/2 transform -translate-x-1/2 max-h-[50vh] overflow-y-auto"
              )}
              side="bottom"
              sideOffset={4}
              avoidCollisions={true}
              onCloseAutoFocus={(e) => e.preventDefault()}
              style={isKeyboardOpen ? { position: 'fixed', zIndex: 9999 } : {}}
            >
              {/* Search Input */}
              <div className="relative mb-2">
                <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Choose a neighborhood"
                  value={searchTerm}
                  onChange={handleLocationInputChange}
                  className="pl-8 h-8 text-sm focus:ring-2 focus:ring-blue-500"
                  autoFocus={false}
                  onKeyDown={(e) => {
                    // Allow all keys including space
                    e.stopPropagation();
                  }}
                />
              </div>
              
              {/* Default Neighborhoods */}
              {(!searchTerm || searchTerm.length <= 2) && (
                <>
                  {defaultNeighborhoods.map((neighborhood) => (
                    <DropdownMenuItem
                      key={neighborhood.value}
                      onClick={() => handleNeighborhoodChange(neighborhood.name)}
                      className={cn(
                        "cursor-pointer text-sm py-2 px-3 rounded-md hover:bg-gray-100 transition-colors",
                        selectedNeighborhood === neighborhood.name && "bg-gray-100 font-medium"
                      )}
                    >
                      {neighborhood.name}
                    </DropdownMenuItem>
                  ))}
                </>
              )}

              {/* Search Results */}
              {searchTerm && searchTerm.length > 2 && (
                <>
                  {searchResults.length > 0 && <DropdownMenuSeparator />}
                  {searchResults.map((result: any, index: number) => (
                    <DropdownMenuItem
                      key={`search-${index}`}
                      onClick={() => handleNeighborhoodSelect(result)}
                      className="cursor-pointer text-sm py-2 px-3 rounded-md hover:bg-gray-100 transition-colors"
                    >
                      {result.label}
                    </DropdownMenuItem>
                  ))}
                  {searchTerm.length > 2 && searchResults.length === 0 && !isLoading && (
                    <DropdownMenuItem disabled className="text-sm text-muted-foreground">
                      No neighborhoods found
                    </DropdownMenuItem>
                  )}
                  {isLoading && (
                    <DropdownMenuItem disabled className="text-sm text-muted-foreground">
                      Searching...
                    </DropdownMenuItem>
                  )}
                </>
              )}
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      )}

      {/* Auth Popup for non-authenticated users */}
      <AuthPopup
        isOpen={showAuthPopup}
        onClose={() => setShowAuthPopup(false)}
        action="interact"
      />
    </div>
  );
};

export default NavBar;