"use client";
import Image from "next/image";
import { Heart, MessageCircle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useState } from "react";
import { useContentDetails } from "@/app/hooks/use-content-details";
import CommentModal from "@/components/comments/comment-modal";
import { useAuth } from "@/app/context/auth-context";

interface RepostGridProps {
  reposts?: {
    id: number;
    title: string;
    body: string;
    created_at: string;
    location?: string;
    thumbnail: string;
  }[];
}

export default function RepostPhotoGrid({ reposts = [] }: RepostGridProps) {
  const [showModal, setShowModal] = useState(false);
  const { isAuthenticated } = useAuth();

  const {
    contentDetails,
    loadings: detailLoading,
    error,
    getContentDetails,
  } = useContentDetails();

  const handleOpenComments = async (contentType: string, contentId: number) => {
    await getContentDetails(contentType, contentId);
    setShowModal(true);
  };

  // Function to detect video URLs
  const isVideoUrl = (url: string) => /\.(mp4|webm|ogg|mov)(\?.*)?$/.test(url);

  if (reposts.length === 0) {
    return (
      <div className="flex items-center justify-center h-full">
        <p className="text-gray-500">No reposts available</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-3 gap-2 p-2">
      {reposts.map((repost) => (
        <div
          key={repost.id}
          className="relative bg-gray-200 overflow-hidden shadow-md group aspect-square"
        >
          {/* Media - Video or Image */}
          {isVideoUrl(repost.thumbnail) ? (
            <div className="relative w-full h-full group">
              <video
                src={repost.thumbnail}
                className="w-full h-full object-cover"
                muted={false}
                preload="metadata"
                controls={true}
                onLoadedData={(e) => {
                  // Set the current frame as poster
                  const video = e.target as HTMLVideoElement;
                  video.currentTime = 1; // Go to 1 second to get a good frame
                }}
              />
            </div>
          ) : (
            <Image
              src={repost.thumbnail}
              alt={repost.title}
              width={150}
              height={150}
              className="object-cover w-full h-full"
              priority={false}
              loading="lazy"
              unoptimized={true}
              quality={90}
              sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
            />
          )}

          {/* Overlay with location and interaction buttons */}
          <div
            onClick={() => handleOpenComments("user_content", repost.id)}
            className="absolute inset-0 flex flex-col justify-between cursor-pointer opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-black bg-opacity-50 text-white p-2"
          >
            {repost.location && (
              <p className="text-xs font-medium text-center">
                @{repost.location}
              </p>
            )}
            <div className="flex justify-around">
              <Button variant="ghost"  className="flex items-center gap-1 p-0">
                <Heart className="h-3 w-3" />
                <span className="text-xs">0</span>
              </Button>
              <Button variant="ghost"  className="flex items-center gap-1 p-0">
                <MessageCircle className="h-3 w-3" />
                <span className="text-xs">0</span>
              </Button>
            </div>
          </div>
        </div>
      ))}
      <CommentModal
        isAuthenticated={isAuthenticated}
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        contentDetails={contentDetails}
        isLoading={detailLoading}
        error={error}
      />
    </div>
  );
}
