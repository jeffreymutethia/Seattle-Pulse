"use client";

import { useState, useEffect } from "react";
import { locationService } from "../services/location-service";
import { LocationSuggestion } from "../types/story";

interface DetectedLocation {
  address: string;
  latitude: number;
  longitude: number;
}

export function useLocation(locationQuery: string) {
  const [locationLoading, setLocationLoading] = useState(false);
  const [suggestionsLoading, setSuggestionsLoading] = useState(false);
  const [suggestions, setSuggestions] = useState<LocationSuggestion[]>([]);
  const [selectedSuggestion, setSelectedSuggestion] =
    useState<LocationSuggestion | null>(null);
  const [isLocationConfirmed, setIsLocationConfirmed] = useState(false);
  const [autoDetectDeclined, setAutoDetectDeclined] = useState(false);

  useEffect(() => {
    const query = locationQuery.trim();
    
    // Don't search if a location is already confirmed/selected
    if (isLocationConfirmed && selectedSuggestion) {
      return;
    }
    
    if (query.length > 2) {
      setSuggestionsLoading(true);
      const timer = setTimeout(async () => {
        try {
          const results = await locationService.searchLocations(query);
          setSuggestions(results);
        } catch (error) {
          console.error("Error fetching suggestions:", error);
          setSuggestions([]);
        } finally {
          setSuggestionsLoading(false);
        }
      }, 500);
      return () => clearTimeout(timer);
    } else {
      setSuggestions([]);
    }
  }, [locationQuery, isLocationConfirmed, selectedSuggestion]);

  useEffect(() => {
    // If user manually changes the location text and it doesn't match the selected suggestion,
    // clear the selection and confirmation
    if (
      selectedSuggestion &&
      locationQuery.trim().toLowerCase() !==
        selectedSuggestion.dropdownValue.toLowerCase()
    ) {
      setSelectedSuggestion(null);
      setIsLocationConfirmed(false);
      setSuggestions([]); // Clear suggestions when user starts typing something different
    }
  }, [locationQuery, selectedSuggestion]);

  const detectCurrentLocation = (): Promise<DetectedLocation> => {
    return new Promise((resolve, reject) => {
      setLocationLoading(true);
      if ("geolocation" in navigator) {
        navigator.geolocation.getCurrentPosition(
          async (position) => {
            const { latitude, longitude } = position.coords;
            try {
              const address = await locationService.getAddressFromCoords(
                latitude,
                longitude
              );
              setLocationLoading(false);
              resolve({ address, latitude, longitude });
            } catch (error) {
              setLocationLoading(false);
              reject(error);
            }
          },
          (error) => {
            console.error("Error fetching location:", error.message);
            setLocationLoading(false);
            reject(error);
          }
        );
      } else {
        console.error("Geolocation is not supported by this browser.");
        setLocationLoading(false);
        reject(new Error("Geolocation not supported"));
      }
    });
  };

  return {
    locationLoading,
    suggestionsLoading,
    suggestions,
    setSuggestions,
    selectedSuggestion,
    setSelectedSuggestion,
    isLocationConfirmed,
    setIsLocationConfirmed,
    autoDetectDeclined,
    setAutoDetectDeclined,
    detectCurrentLocation,
  };
}
