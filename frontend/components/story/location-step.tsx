"use client";

import { useEffect, useState } from "react";
import { MapPin } from "lucide-react";
import { MapContainer, TileLayer, Marker, useMap } from "react-leaflet";
import L from "leaflet";

import { LocationSuggestion } from "@/app/types/story";
import "leaflet/dist/leaflet.css";

interface LocationStepProps {
  location: string;
  locationLoading: boolean;
  suggestionsLoading: boolean;
  suggestions: LocationSuggestion[];
  errorMessage?: string | null;
  onLocationChange: (location: string) => void;
  onSuggestionSelect: (suggestion: LocationSuggestion) => void;
}

function RecenterMap({ position }: { position: [number, number] }) {
  const map = useMap();
  useEffect(() => {
    map.setView(position, 13);
  }, [position, map]);
  return null;
}

export default function LocationStep({
  location,
  locationLoading,
  suggestionsLoading,
  suggestions,
  errorMessage,
  onLocationChange,
  onSuggestionSelect,
}: LocationStepProps) {
  const [userPosition, setUserPosition] = useState<[number, number] | null>(
    null
  );
  const [isLoading, setIsLoading] = useState(true);

  // Create marker icon only once
  const markerIcon = L.icon({
    iconUrl: "https://unpkg.com/leaflet@1.9.3/dist/images/marker-icon.png",
    shadowUrl: "https://unpkg.com/leaflet@1.9.3/dist/images/marker-shadow.png",
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowSize: [41, 41]
  });

  useEffect(() => {
    let isMounted = true; // Prevent state updates if component unmounts
    
    // Try to get cached position first
    const cachedPosition = sessionStorage.getItem('userPosition');
    if (cachedPosition) {
      try {
        const [lat, lng] = JSON.parse(cachedPosition);
        if (isMounted) {
          setUserPosition([lat, lng]);
          setIsLoading(false);
        }
        return;
      } catch (error) {
        console.warn('Invalid cached position:', error);
        sessionStorage.removeItem('userPosition');
      }
    }

    // Get current position with better error handling
    if (navigator.geolocation) {
      // Set a timeout for geolocation to prevent indefinite loading
      const timeoutId = setTimeout(() => {
        if (isMounted) {
          console.warn('Geolocation timeout, using fallback');
          const fallbackPosition = [47.6062, -122.3321] as [number, number];
          setUserPosition(fallbackPosition);
          sessionStorage.setItem('userPosition', JSON.stringify(fallbackPosition));
          setIsLoading(false);
        }
      }, 8000); // 8 second timeout

      navigator.geolocation.getCurrentPosition(
        (pos) => {
          clearTimeout(timeoutId);
          if (isMounted) {
            const position = [pos.coords.latitude, pos.coords.longitude] as [number, number];
            setUserPosition(position);
            sessionStorage.setItem('userPosition', JSON.stringify(position));
            setIsLoading(false);
          }
        },
        (error) => {
          clearTimeout(timeoutId);
          console.warn('Geolocation error:', error.message);
          if (isMounted) {
            // Fallback to Seattle coordinates
            const fallbackPosition = [47.6062, -122.3321] as [number, number];
            setUserPosition(fallbackPosition);
            sessionStorage.setItem('userPosition', JSON.stringify(fallbackPosition));
            setIsLoading(false);
          }
        },
        {
          enableHighAccuracy: false, // Changed to false for faster response
          timeout: 7000, // Reduced timeout
          maximumAge: 300000 // 5 minutes
        }
      );
    } else {
      // Fallback if geolocation is not supported
      if (isMounted) {
        const fallbackPosition = [47.6062, -122.3321] as [number, number];
        setUserPosition(fallbackPosition);
        sessionStorage.setItem('userPosition', JSON.stringify(fallbackPosition));
        setIsLoading(false);
      }
    }

    return () => {
      isMounted = false;
    };
  }, []);

  return (
    <>
      {/* MOBILE: stacked map + input */}
      <div className="md:hidden px-4 space-y-4">
        <div className="mb-6 pt-6">
          <h2 className="text-center text-xl text-[#0C1024] font-bold mb-2">
            Tag Location
          </h2>
          <p className="text-center text-sm text-[#5D6778]">
            Add your location or the location of your post
          </p>
        </div>

        {/* Map */}
        <div className="w-full h-64 rounded-2xl overflow-hidden bg-gray-100">
          {!isLoading && userPosition ? (
            <MapContainer
              center={userPosition}
              zoom={13}
              scrollWheelZoom={false}
              style={{ height: "100%", width: "100%" }}
              key={`mobile-${userPosition[0]}-${userPosition[1]}`}
            >
              <TileLayer
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                attribution='&copy; OpenStreetMap contributors'
              />
              <Marker position={userPosition} icon={markerIcon} />
              <RecenterMap position={userPosition} />
            </MapContainer>
          ) : (
            <div className="h-full w-full flex items-center justify-center">
              <p className="text-gray-500 text-sm">
                {isLoading ? "Loading map..." : "Failed to load map"}
              </p>
            </div>
          )}
        </div>

        {/* Input */}
        <div className="relative">
          <MapPin
            className="absolute left-4 top-4 text-gray-500"
            size={20}
          />
          <input
            type="text"
            className="w-full h-12 pl-12 pr-4 border-2 border-[#ABB0B9] rounded-3xl"
            placeholder="Enter your location"
            value={location}
            onChange={(e) => onLocationChange(e.target.value)}
          />
          {locationLoading && (
            <div className="absolute inset-0 flex items-center justify-center bg-white bg-opacity-70 rounded-3xl">
              <p className="text-sm text-gray-500">
                Loading auto‑location...
              </p>
            </div>
          )}
          {suggestionsLoading && (
            <div className="absolute right-4 top-4">
              <p className="text-sm text-gray-500">Searching...</p>
            </div>
          )}
          {suggestions.length > 0 && (
            <div className="absolute bg-white border border-gray-300 rounded-md mt-2 w-full z-10 max-h-40 overflow-y-auto shadow-lg">
              {suggestions.map((s, idx) => (
                <div
                  key={idx}
                  className="px-4 py-2 hover:bg-gray-100 cursor-pointer"
                  onClick={() => onSuggestionSelect(s)}
                >
                  <p className="text-sm font-medium text-gray-900">
                    {s.label}
                  </p>
                  <p className="text-xs text-gray-500">{s.dropdownValue}</p>
                </div>
              ))}
            </div>
          )}
          {errorMessage && (
            <p className="mt-2 text-xs text-red-600">{errorMessage}</p>
          )}
        </div>
      </div>

      {/* DESKTOP: exactly your original code, untouched */}
      <div className="hidden md:block">
        <div className="mb-8 py-6">
          <h2 className="mb-2 text-center text-xl text-[#0C1024] font-bold">
            Tag Location
          </h2>
          <p className="text-center text-[#5D6778] text-sm">
            Add your location or the location of your post
          </p>
        </div>

        {/* Map & Input container */}
        <div className="flex gap-4" style={{ width: "934px", height: "486px" }}>
          {/* Map side */}
          <div className="w-1/2 h-full overflow-hidden rounded-2xl">
            {!isLoading && userPosition ? (
              <MapContainer
                center={userPosition}
                zoom={13}
                scrollWheelZoom={false}
                style={{ height: "100%", width: "100%" }}
                key={`desktop-${userPosition[0]}-${userPosition[1]}`}
              >
                <TileLayer
                  url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                  attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                />
                <Marker position={userPosition} icon={markerIcon} />
                <RecenterMap position={userPosition} />
              </MapContainer>
            ) : (
              <div className="h-full w-full flex items-center justify-center bg-gray-100 rounded-xl">
                {isLoading ? (
                  <div className="flex flex-col items-center space-y-2">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
                    <p className="text-gray-500 text-sm">Getting your location...</p>
                  </div>
                ) : (
                  <p className="text-gray-500 text-sm">Failed to load map</p>
                )}
              </div>
            )}
          </div>

          {/* Location input & suggestions */}
          <div className="w-1/2 relative">
            <div className="relative w-full rounded-3xl h-12">
              <MapPin
                className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500"
                size={20}
              />
              <input
                type="text"
                style={{
                  borderWidth: "2px",
                  borderColor: "#ABB0B9",
                  borderRadius: "1.5rem",
                  paddingLeft: "3rem",
                }}
                className="w-full h-full py-3 pl-12"
                placeholder="Enter your location"
                value={location}
                onChange={(e) => onLocationChange(e.target.value)}
              />
              {locationLoading && (
                <div className="absolute inset-0 flex items-center justify-center bg-white bg-opacity-70 rounded-3xl">
                  <p className="text-sm text-gray-500">
                    Loading auto‑location...
                  </p>
                </div>
              )}
              {suggestionsLoading && (
                <div className="absolute right-4 top-1/2 -translate-y-1/2">
                  <p className="text-sm text-gray-500">Searching...</p>
                </div>
              )}
            </div>

            {suggestions.length > 0 && (
              <div className="absolute bg-white border border-gray-300 rounded-md mt-2 w-full z-10 max-h-48 overflow-y-auto shadow-lg">
                {suggestions.map((s, index) => (
                  <div
                    key={index}
                    className="px-4 py-2 hover:bg-gray-100 cursor-pointer"
                    onClick={() => onSuggestionSelect(s)}
                  >
                    <p className="text-sm font-medium text-gray-900">
                      {s.label}
                    </p>
                    <p className="text-xs text-gray-500">{s.dropdownValue}</p>
                  </div>
                ))}
              </div>
            )}
            {errorMessage && (
              <p className="mt-3 text-xs text-red-600">{errorMessage}</p>
            )}
          </div>
        </div>
      </div>
    </>
  );
}
