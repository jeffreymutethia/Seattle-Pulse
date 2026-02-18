"use client";

import { useState, useEffect } from "react";
import NavBar from "@/components/nav-bar";
import Loading from "@/components/loading";
import PeopleSuggestions from "@/components/mypulse/people-suggestion";
import EmptyState from "@/components/mypulse/empty-state";
import CommentModal from "@/components/comments/comment-modal";
import MyPulseList from "@/components/mypulse/my-pulse-list";
import { useContentDetails } from "@/app/hooks/use-content-details";
import { usePosts } from "../hooks/use-pulse";
import { useAuth } from "../context/auth-context";
import Notification from "@/components/story/notification";

export default function MyPulsePage() {
  const [, setSelectedImage] = useState<string | null>(null);
  const [showModal, setShowModal] = useState(false);
  const { isAuthenticated } = useAuth();
  const [notificationMessage, setNotificationMessage] = useState<string | null>(null);
  const [notificationTitle, setNotificationTitle] = useState<string | undefined>(undefined);


  const {
    posts,
    loading,
    hasMore,
    hoveredPostId,
    setHoveredPostId,
    handlePostReactionSelect,
    handleRepostSelect,
    loadingRef,
    refreshPosts,
  } = usePosts();

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

  useEffect(() => {
    if (notificationMessage) {
      const timer = setTimeout(() => {
        setNotificationMessage(null);
        setNotificationTitle(undefined);
      }, 3000); // 3 seconds

      return () => clearTimeout(timer); // Cleanup
    }
  }, [notificationMessage]);

  if (loading && posts.length === 0) {
    return <Loading />;
  }

  // Show empty state when no posts and not loading
  if (!loading && posts.length === 0) {
    return (
      <div className="w-full mx-auto p-6">
        <NavBar 
          title="My Pulse" 
          showLocationSelector={false}
          showNotification={isAuthenticated}
          showMessage={isAuthenticated}
          isAuthenticated={isAuthenticated}
        />
        <EmptyState onFollowSuccess={refreshPosts} />
      </div>
    );
  }

  return (
    <div className="w-full mx-auto p-6">
      {notificationMessage && (
        <div className="fixed top-20 right-4 z-50">
          <Notification
            title={notificationTitle || ""}
            message={notificationMessage}
            type="success"
            onClose={() => {
              setNotificationMessage(null);
              setNotificationTitle(undefined);
            }}
            onHomeClick={() => null}
          />
        </div>
      )}

      <NavBar 
      title="My Pulse" 
      showLocationSelector={false}
      showNotification={isAuthenticated}
      showMessage={isAuthenticated}
      isAuthenticated={isAuthenticated}
       />

      <div className="ml-5">
        <p className="font-normal text-xl">Posts from people you follow</p>
      </div>

      <div className="flex justify-center gap-6 mt-6">
        {/* Feed Posts */}
        <MyPulseList
          posts={posts}
          loading={loading}
          hasMore={hasMore}
          hoveredPostId={hoveredPostId}
          setHoveredPostId={setHoveredPostId}
          handlePostReactionSelect={handlePostReactionSelect}
          handleRepostSelect={handleRepostSelect}
          onOpenComments={handleOpenComments}
          onImageSelect={setSelectedImage}
          loadingRef={loadingRef}
          onLinkCopied={() => {
            setNotificationMessage("Link copied to clipboard!");
            setNotificationTitle("Link Copied");
          }}
        />

        {/* People Suggestions are decoupled from MyPulse posts; always fetch/render */}
        <div className="hidden md:block md:w-1/3">
          <PeopleSuggestions onFollowSuccess={refreshPosts} />
        </div>
      </div>

      {/* Mobile People Suggestions - Full width below feed */}
      <div className="md:hidden">
        <PeopleSuggestions onFollowSuccess={refreshPosts} />
      </div>


      <CommentModal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        contentDetails={contentDetails}
        isLoading={detailLoading}
        error={error}
        isAuthenticated={false}
      />
    </div>
  );
}
