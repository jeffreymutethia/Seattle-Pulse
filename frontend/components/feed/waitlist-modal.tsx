"use client";

import { useState, useEffect, useRef } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { apiClient } from "@/app/api/api-client";

interface WaitlistModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const SEATTLE_NEIGHBORHOODS = [
  { label: "Seattle", value: "seattle-all" },
  { label: "Capitol Hill", value: "capitol-hill" },
  { label: "Ballard", value: "ballard" },
  { label: "U District", value: "u-district" },
];

interface LocationResult {
  dropdown_value: string;
  home_location_label: string;
  latitude: number;
  longitude: number;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  raw: any;
}

interface LocationSearchResponse {
  success: string;
  results: LocationResult[];
  total_results: number;
  page: number;
  limit: number;
  query: string;
}

export function WaitlistModal({ isOpen, onClose }: WaitlistModalProps) {
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [neighborhood, setNeighborhood] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [hasJoinedWaitlist, setHasJoinedWaitlist] = useState(false);
  
  // Location selector states
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<LocationResult[]>([]);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [searchLoading, setSearchLoading] = useState(false);
  
  const dropdownRef = useRef<HTMLDivElement>(null);
  const timeoutRef = useRef<NodeJS.Timeout | null>(null);
  
  // Search for locations using the API
  const searchLocations = async (query: string): Promise<LocationResult[]> => {
    if (query.trim().length < 2) return [];
    
    try {
      const response = await apiClient.get<LocationSearchResponse>(
        `/content/search_home_location?query=${encodeURIComponent(query)}&limit=10`
      );
      
      if (response.success === "success") {
        return response.results;
      }
      return [];
    } catch (error) {
      console.error("Error searching locations:", error);
      return [];
    }
  };

  // Debounced search
  useEffect(() => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    if (searchQuery.trim().length >= 2) {
      setSearchLoading(true);
      timeoutRef.current = setTimeout(async () => {
        const results = await searchLocations(searchQuery);
        setSearchResults(results);
        setSearchLoading(false);
      }, 500);
    } else {
      setSearchResults([] as LocationResult[]);
      setSearchLoading(false);
    }

    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
    };
  }, [searchQuery]);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsDropdownOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleLocationSelect = (locationLabel: string) => {
    setNeighborhood(locationLabel);
    setIsDropdownOpen(false);
    setSearchQuery("");
    setSearchResults([] as LocationResult[]);
  };

  const getDisplayResults = (searchQuery: string, searchResults: LocationResult[]) => {
    // If no search query, show Seattle neighborhoods
    if (searchQuery.trim().length < 2) {
      return SEATTLE_NEIGHBORHOODS.map(n => ({
        label: n.label,
        value: n.value,
        isSeattleNeighborhood: false
      }));
    }

    // Show API results
    return searchResults.map(result => ({
      label: result.home_location_label,
      value: result.dropdown_value,
      isSeattleNeighborhood: false,
      data: result
    }));
  };

  const LocationDropdown = () => {
    const displayResults = getDisplayResults(searchQuery, searchResults);
    
    return (
      <div className="relative" ref={dropdownRef}>
        <div
          className="h-12 rounded-full border border-input bg-background px-3 py-2 text-sm ring-offset-background cursor-pointer flex items-center justify-between"
          onClick={() => setIsDropdownOpen(!isDropdownOpen)}
        >
          <span className={neighborhood ? "text-foreground" : "text-muted-foreground"}>
            {neighborhood || "Select your neighborhood"}
          </span>
          <svg
            className="h-4 w-4 opacity-50"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M19 9l-7 7-7-7"
            />
          </svg>
        </div>
        
        {isDropdownOpen && (
          <div className="absolute bottom-full left-0 mb-1 w-full bg-white rounded-md border shadow-lg z-[9999] p-2 max-h-60 overflow-y-auto">
            <div className="px-2 mb-2">
              <Input
                placeholder="Search for a location..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full h-10"
                autoFocus
              />
            </div>
            <div>
              {searchLoading && (
                <div className="flex items-center justify-center py-2">
                  <span className="text-sm text-gray-500">Searching...</span>
                </div>
              )}
              
              {!searchLoading && displayResults.length === 0 && searchQuery.trim().length >= 2 && (
                <div className="flex items-center justify-center py-2">
                  <span className="text-sm text-gray-500">No locations found</span>
                </div>
              )}
              
              {!searchLoading && displayResults.map((result, index) => (
                <div
                  key={`${result.value}-${index}`}
                  data-cy={`neighborhood-option-${result.value}`}
                  onClick={() => handleLocationSelect(result.label)}
                  className="flex cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-sm hover:bg-gray-100 transition-colors"
                >
                  <span className="truncate">{result.label}</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    );
  };
  
  // Check if user has already joined waitlist
  useEffect(() => {
    const hasWaitlistCookie = document.cookie
      .split(';')
      .some(cookie => cookie.trim().startsWith('waitlist_signup='));
    setHasJoinedWaitlist(hasWaitlistCookie);
  }, []);
  
  // Manage scroll behavior when modal opens/closes
  useEffect(() => {
    if (isOpen) {
      // Save current scroll position
      const scrollY = window.scrollY;
      
      // Prevent background scrolling when modal is open
      document.body.style.position = 'fixed';
      document.body.style.top = `-${scrollY}px`;
      document.body.style.width = '100%';
    } else {
      // Get the scroll position from the body's top property
      const scrollY = document.body.style.top;
      
      // Reset body styles
      document.body.style.position = '';
      document.body.style.top = '';
      document.body.style.width = '';
      
      // Restore scroll position
      if (scrollY) {
        window.scrollTo(0, parseInt(scrollY.replace('-', '')) || 0);
      }
    }
    
    return () => {
      // Cleanup in case component unmounts while modal is open
      document.body.style.position = '';
      document.body.style.top = '';
      document.body.style.width = '';
    };
  }, [isOpen]);
  
  // Validate phone number format
  const validatePhone = (phone: string) => {
    if (!phone) return true; // Phone is optional
    const phoneRegex = /^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$/;
    return phoneRegex.test(phone);
  };

  // Validate email
  const validateEmail = (email: string) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  };
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    
    // Validate form
    if (!validateEmail(email)) {
      setError("Please enter a valid email address");
      return;
    }
    
    if (phone && !validatePhone(phone)) {
      setError("Please enter a valid phone number");
      return;
    }
    
    setIsLoading(true);
    
    try {
      // Call to the API endpoint using apiClient
       await apiClient.post<{ success: string, message: string, data?: { status: string } }>('/waitlist', { 
        email, 
        phone: phone || undefined, 
        neighborhood: neighborhood || undefined,
        utm_source: "webapp" 
      });

    
      document.cookie = "waitlist_signup=true; path=/; max-age=31536000"; // 1 year
      setSubmitted(true);
      setHasJoinedWaitlist(true);
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    } catch (error: unknown) {
      setError("Already registered—thanks for being an early supporter.");
    } finally {
      setIsLoading(false);
    }
  };
  
  const handleClose = () => {
    // Call parent's onClose function
    onClose();
    
    // Reset state after a short delay
    setTimeout(() => {
      setEmail("");
      setPhone("");
      setNeighborhood("");
      setSubmitted(false);
      setError("");
      setSearchQuery("");
      setSearchResults([] as LocationResult[]);
      setIsDropdownOpen(false);
    }, 300);
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent 
        className="sm:max-w-md flex-col items-center justify-center !rounded-3xl overflow-auto max-h-[90vh] p-6"
        onOpenAutoFocus={(e) => e.preventDefault()}
        onCloseAutoFocus={(e) => e.preventDefault()}
      >
        <DialogHeader className="flex items-center justify-center">
          <DialogTitle className="text-black text-xl">
            {hasJoinedWaitlist ? "You're on the waitlist!" : "Unlock Your Neighborhood’s Inside Scoop"}
          </DialogTitle>
          <DialogDescription className="text-center">
            {hasJoinedWaitlist 
              ? "We'll notify you when Seattle Pulse launches. Stay tuned!"
              : "Join the waitlist to get early access and help shape the app."}
          </DialogDescription>
        </DialogHeader>
        
        {submitted ? (
          <div className="py-6 text-center">
            <div className="mb-4 text-green-500 text-3xl">🎉</div>
            <h2 className="text-lg text-center font-medium mb-3">Thank you!</h2>
            <p className="text-gray-600 mb-6">
              You&apos;re on the waitlist! We&apos;ll notify you when Seattle Pulse launches.
            </p>
            <Button
              className="w-full h-12 rounded-full text-white"
              onClick={handleClose}
            >
              Close
            </Button>
          </div>
        ) : hasJoinedWaitlist ? (
          <div className="py-6 text-center">
            <div className="mb-4 text-green-500 text-3xl">🎉</div>
            <h2 className="text-lg text-center font-medium mb-3">You&apos;re already on the waitlist!</h2>
            <p className="text-gray-600 mb-6">
              We&apos;ll notify you when Seattle Pulse launches. Stay tuned for updates!
            </p>
            <Button
              className="w-full h-12 rounded-full text-white"
              onClick={handleClose}
            >
              Close
            </Button>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="w-full py-4 space-y-4">
            {error && (
              <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-2 rounded-lg text-sm">
                {error}
              </div>
            )}
            
            <div className="space-y-2">
              <Label htmlFor="email">Email address <span className="text-red-500">*</span></Label>
              <Input 
                id="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="your@email.com"
                type="email"
                required
                className="!rounded-3xl !w-full !h-12 !border-[1px]"
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="phone">Phone number (optional)</Label>
              <Input 
                id="phone"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="(123) 456-7890"
                type="tel"
                className="h-12 rounded-full"
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="neighborhood">Neighborhood (optional)</Label>
              <LocationDropdown />
            </div>
            
            <Button 
              type="submit" 
              className="w-full h-12 rounded-full mt-4"
              disabled={isLoading}
            >
              {isLoading ? 
                <div className="flex items-center">
                  <div className="animate-spin h-4 w-4 border-2 border-white rounded-full border-t-transparent mr-2"></div>
                  Processing...
                </div> : 
                "Join Waitlist"
              }
            </Button>
            
            <DialogFooter className="sm:justify-center">
              <p className="text-xs text-center text-gray-500 mt-2">
                By joining, you agree to receive updates about Seattle Pulse.
              </p>
            </DialogFooter>
          </form>
        )}
      </DialogContent>
    </Dialog>
  );
} 