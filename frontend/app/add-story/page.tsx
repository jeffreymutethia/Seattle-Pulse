"use client";

import { useState, useEffect } from "react";
import { ArrowRight, ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useRouter } from "next/navigation";
import NavBar from "@/components/nav-bar";
import { Step, FormData, LocationSuggestion } from "../types/story";
import { useFileUpload } from "../hooks/use-file-upload";
import { useLocation } from "../hooks/use-location";
import { storyService } from "../services/story-service";
import { locationService } from "../services/location-service";
import { trackEvent } from "@/lib/mixpanel";
import UploadMediaStep from "../../components/story/upload-media-step";
import CaptionStep from "../../components/story/caption-step";
import LocationStep from "../../components/story/location-step";
import PreviewStep from "../../components/story/preview-step";
import StepIndicator from "../../components/story/step-indicator";

const steps: Step[] = [
  { id: 1, name: "Upload Media", icon: "./cloud.png" },
  { id: 2, name: "Add Caption", icon: "./Text.png" },
  { id: 3, name: "Tag Location", icon: "./Map.png" },
  { id: 4, name: "Preview", icon: "./Check.png" },
];

export default function MultiStepForm() {
  const router = useRouter();
  const [currentStep, setCurrentStep] = useState(1);
  const [hasDetectedLocation, setHasDetectedLocation] = useState(false);
  const [formData, setFormData] = useState<FormData>({
    media: null,
    caption: "",
    location: "",
  });
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [notification, setNotification] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [locationError, setLocationError] = useState<string | null>(null);

  const {
    uploadState,
    uploadProgress,
    selectedFile,
    previewUrl,
    thumbnailUrl,
    uploadKey,
    errorMessage,
    handleFileSelect,
    resetUpload,
  } = useFileUpload();

  const {
    locationLoading,
    suggestionsLoading,
    suggestions,
    setSuggestions,
    selectedSuggestion,
    setSelectedSuggestion,
    isLocationConfirmed,
    setIsLocationConfirmed,
    autoDetectDeclined,
    detectCurrentLocation,
  } = useLocation(formData.location);

  const hasValidLocationSelection = Boolean(
    selectedSuggestion?.dropdownValue &&
      Number.isFinite(selectedSuggestion.latitude) &&
      Number.isFinite(selectedSuggestion.longitude)
  );

  useEffect(() => {
    if (currentStep === 3 && !autoDetectDeclined && !hasDetectedLocation) {
      detectCurrentLocation()
        .then(async ({ address, latitude, longitude }) => {
          setHasDetectedLocation(true);
          setLocationError(null);
          setSelectedSuggestion(null);
          setIsLocationConfirmed(false);
          setFormData((prev) => ({ ...prev, location: address }));

          try {
            const resolvedSuggestions = await locationService.searchLocations(
              address
            );
            setSuggestions(resolvedSuggestions);

            if (resolvedSuggestions.length === 0) {
              setLocationError(
                "We couldn't match your current location. Please pick a neighborhood manually."
              );
              return;
            }

            const bestMatch = resolvedSuggestions.reduce(
              (closest: LocationSuggestion | null, candidate) => {
                if (!closest) {
                  return candidate;
                }

                const candidateDistance = Math.hypot(
                  candidate.latitude - latitude,
                  candidate.longitude - longitude
                );
                const closestDistance = Math.hypot(
                  closest.latitude - latitude,
                  closest.longitude - longitude
                );

                return candidateDistance < closestDistance ? candidate : closest;
              },
              null
            );

            if (bestMatch) {
              setSelectedSuggestion(bestMatch);
              setFormData((prev) => ({
                ...prev,
                location: bestMatch.dropdownValue,
              }));
              setIsLocationConfirmed(true);
              setLocationError(null);
            } else {
              setLocationError(
                "We couldn't match your current location. Please pick a neighborhood manually."
              );
            }
          } catch (error) {
            console.error("Failed to resolve detected location:", error);
            setLocationError(
              "We couldn't match your current location. Please pick a neighborhood manually."
            );
          }
        })
        .catch((error) => {
          console.error("Failed to detect location:", error);
          setHasDetectedLocation(true);
          setLocationError(
            "We couldn't detect your location. Please pick a neighborhood manually."
          );
        });
    }
  }, [
    currentStep,
    autoDetectDeclined,
    hasDetectedLocation,
    detectCurrentLocation,
    setIsLocationConfirmed,
    setSelectedSuggestion,
    setSuggestions,
  ]);

  const handleNext = () => {
    if (currentStep < steps.length) {
      setCurrentStep((prev) => prev + 1);
    }
  };

  const handleBack = () => {
    if (currentStep > 1) {
      setCurrentStep((prev) => prev - 1);
    }
  };

  const handleCaptionChange = (caption: string) => {
    setFormData((prev) => ({ ...prev, caption }));
  };

  const handleLocationChange = (location: string) => {
    setFormData((prev) => ({ ...prev, location }));
    setSelectedSuggestion(null);
    setIsLocationConfirmed(false);
    setLocationError(null);
  };

  const handleSuggestionSelect = (suggestion: LocationSuggestion) => {
    setFormData((prev) => ({
      ...prev,
      location: suggestion.dropdownValue,
    }));
    setSelectedSuggestion(suggestion);
    setIsLocationConfirmed(true);
    setSuggestions([]);
    setLocationError(null);
  };

  const handlePostStory = async () => {
    if (!thumbnailUrl || !selectedFile) {
      setNotification("Please upload a media file first");
      setTimeout(() => setNotification(null), 5000);
      return;
    }

    if (!hasValidLocationSelection || !selectedSuggestion) {
      setNotification(
        "Please select a valid neighborhood before posting your story."
      );
      setTimeout(() => setNotification(null), 5000);
      return;
    }

    setIsSubmitting(true);

    try {
      // Step 1: Submit story with thumbnail_url
      const payload = {
        body: formData.caption,
        location: selectedSuggestion.dropdownValue,
        latitude: selectedSuggestion.latitude,
        longitude: selectedSuggestion.longitude,
        thumbnail_url: thumbnailUrl,
      };

      const storyResponse = await storyService.postStory(payload);
      
      // Fix: API returns structure with data.post.id (not data.data.post.id)
      if (!storyResponse.data?.post?.id) {
        throw new Error("Failed to create story - no content ID received");
      }

      const apiPost = storyResponse.data.post;
      const contentId = apiPost.id;

      // Step 2: Complete upload for content moderation
      await storyService.completeUpload({
        upload_key: uploadKey,
        content_id: contentId,
        metadata: {
          content_type: selectedFile.type,
        },
      });

      // Track story creation
      trackEvent("story_created", {
        content_id: contentId,
        has_caption: !!formData.caption,
        location: selectedSuggestion?.dropdownValue || null,
        media_type: selectedFile.type,
      });

      // Success - Create post object for immediate display using API response data
      // Use location from API response, not from frontend form
      const newPost = {
        id: contentId,
        body: apiPost.body || formData.caption,
        location: apiPost.location, // Use location from API response
        latitude: apiPost.latitude,
        longitude: apiPost.longitude,
        thumbnail: apiPost.thumbnail || thumbnailUrl, // Use thumbnail from API response if available
        media_url: previewUrl,
        created_at: apiPost.created_at || new Date().toISOString(),
        time_since_post: "just now", // Add time_since_post field
        title: apiPost.title || formData.caption || "New Story", // Use title from API response
        user: {
          id: apiPost.user?.id || JSON.parse(sessionStorage.getItem("user") || "{}").user_id,
          username: apiPost.user?.username || JSON.parse(sessionStorage.getItem("user") || "{}").username,
          profile_picture_url: JSON.parse(sessionStorage.getItem("user") || "{}").profile_picture_url,
        },
        comments_count: 0,
        reactions_count: 0,
        score: "0",
        updated_at: apiPost.updated_at || new Date().toISOString(),
        user_has_reacted: false,
        user_reaction_type: null,
        has_user_reposted: false,
        totalReactions: 0,
        totalComments: 0,
        totalReposts: 0,
        userReaction: null,
        userReposted: false,
        isVideo: selectedFile?.type.startsWith("video/") || false,
        isNewlyPosted: true, // Flag to indicate this is a newly posted story
      };

      // Store the new post in sessionStorage for the feed to pick up
      sessionStorage.setItem("newlyPostedStory", JSON.stringify(newPost));
      
      // Store the post location from API response to automatically update feed location
      // This will persist across page refreshes
      sessionStorage.setItem("feedLocation", apiPost.location);

      setNotification(
        "Celebrate your moment and let others discover it\non the map."
      );
      setTimeout(() => setNotification(null), 9000);
      router.push("/?notification=success&newPost=true");

    } catch (error) {
      console.error("Error posting story:", error);
      setNotification(
        error instanceof Error ? error.message : "Error posting story"
      );
      setTimeout(() => setNotification(null), 5000);
    } finally {
      setIsSubmitting(false);
    }
  };

  const renderCurrentStep = () => {
    switch (currentStep) {
      case 1:
        return (
          <UploadMediaStep
            uploadState={uploadState}
            uploadProgress={uploadProgress}
            selectedFile={selectedFile}
            previewUrl={previewUrl}
            errorMessage={errorMessage}
            onFileSelect={handleFileSelect}
            onReset={resetUpload}
          />
        );
      case 2:
        return (
          <CaptionStep
            caption={formData.caption}
            onCaptionChange={handleCaptionChange}
          />
        );
      case 3:
        return (
          <LocationStep
            location={formData.location}
            locationLoading={locationLoading}
            suggestionsLoading={suggestionsLoading}
            suggestions={suggestions}
            errorMessage={locationError}
            onLocationChange={handleLocationChange}
            onSuggestionSelect={handleSuggestionSelect}
          />
        );
      case 4:
        return (
          <PreviewStep
            caption={formData.caption}
            location={selectedSuggestion?.label || formData.location}
            previewUrl={previewUrl}
            fileType={selectedFile?.type}
          />
        );
      default:
        return null;
    }
  };

  return (
    <div className="p-4 sm:p-6">
      <NavBar title="Add your story" showLocationSelector={false} showSearch={false} />

      <div className="flex justify-center">
        <div
          className="
            mx-auto
            w-full
            sm:max-w-lg
            md:max-w-2xl
            lg:max-w-[1200px]

            h-auto
            md:h-[840px]

            overflow-auto
            rounded-3xl
            border-2
            border-gray-200
            bg-white

            px-4 py-2
            sm:px-6 sm:py-6
          "
        >
          <div className="mb-3 sm:mb-0">
            <StepIndicator steps={steps} currentStep={currentStep} />
          </div>

          <div className="mt-2 sm:mt-2">
            {renderCurrentStep()}

            <div className="mt-6 sm:mt-8 flex flex-col sm:flex-row justify-end gap-3 sm:gap-4">
              {currentStep !== 1 && (
                <Button
                  onClick={handleBack}
                  disabled={isSubmitting}
                  className="
                    w-full sm:w-40
                    h-12
                    rounded-full
                    bg-white
                    border-2 border-black
                    hover:bg-gray-50

                    flex items-center gap-2
                    justify-center
                  "
                >
                  <ArrowLeft className="w-5 h-5 text-black" />
                  <span className="text-black">Back</span>
                </Button>
              )}

              {(currentStep === 1 || currentStep === 2) && (
                <Button
                  onClick={handleNext}
                  disabled={currentStep === 1 && uploadState !== "success"}
                  className="
                    w-full sm:w-40
                    h-12
                    rounded-full
                    bg-black
                    hover:bg-gray-900
                    text-white

                    flex items-center gap-2
                    justify-center
                  "
                >
                  <span>{currentStep === 1 ? "Use Media" : "Next"}</span>
                  <ArrowRight className="w-5 h-5" />
                </Button>
              )}

              {currentStep === 3 && (
                <Button
                  onClick={handleNext}
                  disabled={
                    !isLocationConfirmed ||
                    !hasValidLocationSelection ||
                    locationLoading ||
                    suggestionsLoading
                  }
                  className="
                    w-full sm:w-48
                    h-12
                    rounded-full
                    bg-black
                    hover:bg-gray-900
                    text-white

                    flex items-center gap-2
                    justify-center
                  "
                >
                  <span>
                    {locationLoading || suggestionsLoading 
                      ? "Loading..." 
                      : "Confirm Location"
                    }
                  </span>
                  <ArrowRight className="w-5 h-5" />
                </Button>
              )}

              {currentStep === 4 && (
                <Button
                  onClick={handlePostStory}
                  disabled={isSubmitting || !hasValidLocationSelection}
                  className="
                    w-full sm:w-40
                    h-12
                    rounded-full
                    bg-black
                    hover:bg-gray-900
                    text-white

                    flex items-center gap-2
                    justify-center
                  "
                >
                  <span>{isSubmitting ? "Posting..." : "Post Story"}</span>
                </Button>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* {notification && (
        <div className="fixed bottom-4 left-4 right-4 bg-green-500 text-white p-4 rounded-lg shadow-lg z-50">
          {notification}
        </div>
      )} */}
    </div>
  );
}
