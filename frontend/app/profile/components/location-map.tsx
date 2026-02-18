"use client";

import { useEffect, useState } from "react";
import { MapContainer, TileLayer, Marker } from "react-leaflet";
import MarkerClusterGroup from "react-leaflet-markercluster";
import L from "leaflet";
import { apiClient } from "@/app/api/api-client";

import "leaflet/dist/leaflet.css"
import CommentModal from "@/components/comments/comment-modal"
import { useContentDetails } from "@/app/hooks/use-content-details"
import { useAuth } from "@/app/context/auth-context"
import { useAuthRequired } from "@/app/hooks/use-auth-required"
import { usePosts } from "@/app/hooks/use-posts"

interface UserLocation {
  content_id: number;
  title: string;
  location: string;
  latitude: number;
  longitude: number;
}

interface CenterCoordinates {
  lat: number;
  lng: number;
}

interface ApiResponseData {
  locations: UserLocation[];
  center: {
    latitude: number;
    longitude: number;
  };
}

interface MyMapComponentProps {
  userId: number;
}

const defaultCenter: CenterCoordinates = { lat: 40.7128, lng: -74.006 };
const defaultZoom = 4;

const createCustomIcon = (number: number) => {
  const svgTemplate = `
    <svg width="40" height="50" viewBox="0 0 40 50" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M20 0C8.95431 0 0 8.95431 0 20C0 31.0457 20 50 20 50C20 50 40 31.0457 40 20C40 8.95431 31.0457 0 20 0Z" 
            fill="#2563eb" 
            stroke="black" 
            stroke-width="2"/>
      <text x="20" y="25" 
            font-family="Arial" 
            font-size="14" 
            fill="white" 
            text-anchor="middle" 
            dominant-baseline="middle">${number}</text>
    </svg>
  `;
  const svgUrl = "data:image/svg+xml;base64," + btoa(svgTemplate);

  return new L.Icon({
    iconUrl: svgUrl,
    iconSize: [40, 50],
    iconAnchor: [20, 50],
    popupAnchor: [0, -45],
  });
};

const MyMapComponent = ({ userId }: MyMapComponentProps) => {
  const [locations, setLocations] = useState<UserLocation[]>([])
  const [mapCenter, setMapCenter] = useState<CenterCoordinates>(defaultCenter)
  const [showModal, setShowModal] = useState(false);

  const { isAuthenticated } = useAuth();
  const { requireAuth } = useAuthRequired();

  const {

    handlePostReaction,
  
  } = usePosts();


  const {
    contentDetails,
    loadings: detailLoading,
    error,
    getContentDetails,
  } = useContentDetails();

  useEffect(() => {
    const endpoint = `/content/user/${userId}/locations?page=1&per_page=10`;

    apiClient.get<{ success: string; message: string; data: ApiResponseData }>(endpoint)
      .then((data) => {
        if (data.success === "success") {
          setLocations(data.data.locations);
          if (data.data.center) {
            setMapCenter({
              lat: data.data.center.latitude,
              lng: data.data.center.longitude,
            });
          }
        } else {
          console.error("Error fetching locations:", data.message);
        }
      })
      .catch((err) => {
        console.error("Fetch error:", err);
      });
  }, [userId]);

  if (typeof window === "undefined") return null;

  // const handleMarkerClick = (content_id: number) => {
  //   window.location.href = `/?notification=true&post_id=${content_id}&type=user_content`;
  // };


  return (
    <>
      <div style={{ height: "80vh", width: "100%", position: "relative", zIndex: 1 }}>
        <MapContainer
          center={mapCenter}
          zoom={defaultZoom}
          scrollWheelZoom={true}
          style={{ height: "100%", width: "100%", position: "relative", zIndex: 1 }}
        >
          <TileLayer
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            attribution='&copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a>'
          />

          <MarkerClusterGroup
            chunkedLoading={true}
            maxClusterRadius={60}
            spiderfyOnMaxZoom={true}
            iconCreateFunction={(cluster: { getChildCount: () => number }) => {
              const childCount = cluster.getChildCount();
              const svgTemplate = `
                <svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <circle cx="20" cy="20" r="19" 
                          fill="#2563eb" 
                          stroke="black" 
                          stroke-width="2"/>
                  <text x="20" y="25" 
                        font-family="Arial" 
                        font-size="14" 
                        fill="white" 
                        text-anchor="middle" 
                        dominant-baseline="middle">${childCount}</text>
                </svg>
              `;
              const svgUrl = "data:image/svg+xml;base64," + btoa(svgTemplate);

              return L.divIcon({
                html: `<img src="${svgUrl}" style="width: 40px; height: 40px;">`,
                className: "custom-cluster-icon",
                iconSize: L.point(40, 40),
              });
            }}
          >
            {locations.map((loc) => (
              <Marker
                key={loc.content_id}
                position={[loc.latitude, loc.longitude]}
                icon={createCustomIcon(loc.content_id)}
                eventHandlers={{
                  click: () => {
                    getContentDetails("user_content", loc.content_id);
                    setShowModal(true);
                  },
                }}
              >
                {/* <Popup>
                  <div>
                    <h3>{loc.title}</h3>
                    <p>Location: {loc.location}</p>
                    <p>
                      Latitude: {loc.latitude}, Longitude: {loc.longitude}
                    </p>
                    <p>Click marker to open page for ID: {loc.content_id}</p>
                  </div>
                </Popup> */}
              </Marker>
            ))}
          </MarkerClusterGroup>
        </MapContainer>
      </div>

      <div style={{ position: "relative", zIndex: 10000 }}>
        <CommentModal
          isOpen={showModal}
          onClose={() => setShowModal(false)}
          contentDetails={contentDetails}
          isLoading={detailLoading}
          error={error}
          isAuthenticated={isAuthenticated}
          requireAuth={requireAuth}
          onPostReactionSelect={(postId, reactionType) => {
            requireAuth(() => handlePostReaction(postId, reactionType));
          }}
        />
      </div>
    </>
  );
};

export default MyMapComponent;
