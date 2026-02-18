import { apiClient } from "../api/api-client";
import { LocationSuggestion } from "../types/story";

export const locationService = {
  async getAddressFromCoords(lat: number, lon: number): Promise<string> {
    try {
      const response = await fetch(
        `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json`
      );
      const data = await response.json();
      return data.display_name || "";
    } catch (error) {
      console.error("Error fetching address:", error);
      return "";
    }
  },

  async searchLocations(query: string): Promise<LocationSuggestion[]> {
    try {
      const data = await apiClient.get<{
        results: {
          dropdown_value: string;
          home_location_label: string;
          latitude: number;
          longitude: number;
          raw?: unknown;
        }[];
        success: string;
        total_results: number;
      }>(
        `/content/search_home_location?query=${encodeURIComponent(query)}`
      );

      return (data.results || []).map((item) => ({
        label: item.home_location_label || item.dropdown_value,
        dropdownValue: item.dropdown_value,
        latitude: item.latitude,
        longitude: item.longitude,
      }));
    } catch (error) {
      console.error("Error fetching suggestions:", error);
      return [];
    }
  },
};
