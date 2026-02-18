import { useState, useCallback } from 'react';
import { searchLocations, searchHomeLocation } from '@/app/services/location';
import { debounce } from 'lodash';
import { OptionsOrGroups, GroupBase } from 'react-select';

interface LocationResult {
  location_label: string;
  latitude: number;
  longitude: number;
  raw: {
    display_name: string;
    address: {
      city?: string;
      town?: string;
      village?: string;
      suburb?: string;
      state?: string;
      country?: string;
      [key: string]: string | undefined;
    };
  };
}

interface LocationOption {
  value: string;
  label: string;
  data: LocationResult;
}

interface HomeLocationOption {
  value: string;
  label: string;
  isPreset?: boolean;
  city?: string;
}

const getLocationLabel = (location: LocationResult): string => {
  const address = location.raw.address;
  
  // Try to get the city name from various possible fields
  const cityName = address.city || address.town || address.village || address.suburb;
  
  if (cityName) {
    // If we have a city name, format it with state and country if available
    const parts = [cityName];
    if (address.state) parts.push(address.state);
    if (address.country) parts.push(address.country);
    return parts.join(', ');
  }
  
  // Fallback to the display name if no city is found
  return location.raw.display_name;
};

export const useLocationSearch = () => {
  const [isLoading, setIsLoading] = useState(false);

  const loadOptions = useCallback(
    debounce(async (
      inputValue: string,
      callback: (options: OptionsOrGroups<LocationOption, GroupBase<LocationOption>>) => void
    ) => {
      if (!inputValue) {
        callback([]);
        return;
      }

      setIsLoading(true);
      try {
        const data = await searchLocations(inputValue);
        const options = data.results.map((location) => ({
          value: location.location_label,
          label: getLocationLabel(location),
          data: location
        }));
        callback(options);
      } catch (error) {
        console.error('Error fetching locations:', error);
        callback([]);
      } finally {
        setIsLoading(false);
      }
    }, 500),
    []
  );

  return { loadOptions, isLoading };
};

// New hook for neighborhood location search with visual hierarchy
export const useHomeLocationSearch = () => {
  const [isLoading, setIsLoading] = useState(false);

  // Hard-coded launch set as specified in the requirements - always show these first
  const launchSet: HomeLocationOption[] = [
    { value: 'Seattle', label: 'Seattle', isPreset: true },
    { value: 'Capitol Hill', label: 'Capitol Hill', isPreset: true },
    { value: 'Ballard', label: 'Ballard', isPreset: true },
    { value: 'U District', label: 'U District', isPreset: true },
    
  ];

  const debouncedSearch = useCallback(
    debounce(async (
      inputValue: string,
      callback: (options: OptionsOrGroups<HomeLocationOption, GroupBase<HomeLocationOption>>) => void
    ) => {
      
      // Always start with launch set for any input (including empty)
      let options = [...launchSet];

      // If there's input, filter the launch set first
      if (inputValue && inputValue.trim()) {
        const filteredLaunchSet = launchSet.filter(option =>
          option.label.toLowerCase().includes(inputValue.toLowerCase())
        );

        // If input doesn't match any launch set items, search via API
        if (filteredLaunchSet.length === 0 || inputValue.trim().length > 2) {
          setIsLoading(true);
          try {
            const data = await searchHomeLocation(inputValue.trim());
            
            // Convert API results to dropdown options
            const searchOptions: HomeLocationOption[] = data.results?.map(result => ({
              value: result.dropdown_value,
              // Use dropdown_value as the visible label per requirement
              label: result.dropdown_value,
              isPreset: false,
              // Prefer the city field for feed queries
              city: result.raw?.address?.city || result.raw?.address?.town || result.raw?.address?.village || undefined,
            })) || [];

            // Filter out duplicates from launch set using a Set for performance
            const presetValues = new Set(launchSet.map(preset => preset.value.toLowerCase()));
            const uniqueSearchOptions = searchOptions.filter(searchOption =>
              !presetValues.has(searchOption.value.toLowerCase())
            );

            // Combine filtered launch set with unique search results
            options = [...filteredLaunchSet, ...uniqueSearchOptions];
            
          } catch (error) {
            console.error('Error fetching neighborhood:', error);
            // Fall back to filtered launch set on error
            options = filteredLaunchSet;
          } finally {
            setIsLoading(false);
          }
        } else {
          // Just use filtered launch set
          options = filteredLaunchSet;
        }
      }

      callback(options);
    }, 800), // Increased delay to 800ms to prevent excessive API calls
    []
  );

  const loadOptions = useCallback((
    inputValue: string,
    callback: (options: OptionsOrGroups<HomeLocationOption, GroupBase<HomeLocationOption>>) => void
  ) => {
    debouncedSearch(inputValue, callback);
  }, [debouncedSearch]);

  return { loadOptions, isLoading, launchSet };
}; 