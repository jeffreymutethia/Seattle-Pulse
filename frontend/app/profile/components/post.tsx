import Image from "next/image";
import { Heart, MessageCircle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useState } from "react";
import { useContentDetails } from "@/app/hooks/use-content-details";
import CommentModal from "@/components/comments/comment-modal";
import { useAuth } from "@/app/context/auth-context";

interface PhotoGridProps {
  posts?: {
    post: {
      id: number;
      title: string;
      body: string;
      created_at: string;
      location?: string;
      thumbnail?: string;
    };
    total_comments: number;
    total_likes: number;
  }[];
}

export default function PhotoGrid({ posts = [] }: PhotoGridProps) {
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

  if (posts.length === 0) {
    return (
      <div className="flex items-center justify-center h-full">
        <p className="text-gray-500">No posts available</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-3 gap-2 p-2">
      {posts.map((postData) => (
        <div
          key={postData.post.id}
          className="relative bg-gray-200 cursor-pointer overflow-hidden shadow-md group aspect-square"
        >
          {isVideoUrl(postData.post.thumbnail || "") ? (
            <div className="relative w-full h-full group">
              <video
                src={postData.post.thumbnail}
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
              src={postData.post.thumbnail || ""}
              alt={postData.post.title}
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

          <div
            onClick={() => handleOpenComments("user_content", postData.post.id)}
            className="absolute inset-0 flex flex-col justify-between 
                       opacity-0 group-hover:opacity-100 transition-opacity 
                       duration-300 bg-black bg-opacity-50 text-white p-2"
          >
            {postData.post.location && (
              <p className="text-xs font-medium text-center">
                @{postData.post.location}
              </p>
            )}

            <div className="flex justify-around">
              <Button
                variant="ghost"
                
                className="flex items-center gap-1 p-0"
              >
                <Heart className="h-3 w-3" />
                <span className="text-xs">{postData.total_likes ?? 0}</span>
              </Button>
              <Button
                variant="ghost"
               
                className="flex items-center gap-1 p-0"
              >
                <MessageCircle className="h-3 w-3" />
                <span className="text-xs">{postData.total_comments ?? 0}</span>
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
