/* eslint-disable @typescript-eslint/no-explicit-any */
import { API_BASE_URL } from '@/lib/config';

interface HomeLocationResult {
  home_location_label: string;
  dropdown_value: string;
  latitude: number;
  longitude: number;
  raw: {
    address: {
      [key: string]: any;
    };
    display_name: string;
  };
}

export interface HomeLocationResponse {
  limit: number;
  page: number;
  query: string;
  results: HomeLocationResult[];
  success: string;
  total_results: number;
}

export const searchHomeLocation = async (query: string): Promise<HomeLocationResponse> => {
  const response = await fetch(
    `${API_BASE_URL}/content/search_home_location?query=${encodeURIComponent(query)}`
  );
  
  if (!response.ok) {
    throw new Error('Failed to fetch neighborhood');
  }
  
  return response.json();
};

// Keep the old interface and function for backward compatibility with other parts of the app
interface LocationResult {
  location_label: string;
  latitude: number;
  longitude: number;
  raw: {
    display_name: string;
    address: {
      neighbourhood?: string;
      city: string;
      state: string;
      country: string;
    };
  };
}

export interface LocationResponse {
  success: string;
  query: string;
  page: number;
  limit: number;
  results: LocationResult[];
  total_results: number;
}

export const searchLocations = async (query: string): Promise<LocationResponse> => {
  const response = await fetch(
    `${API_BASE_URL}/content/search_location_for_upload?query=${encodeURIComponent(query)}`
  );
  
  if (!response.ok) {
    throw new Error('Failed to fetch locations');
  }
  
  return response.json();
}; 