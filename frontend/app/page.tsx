/* eslint-disable @typescript-eslint/no-unused-vars */
/* eslint-disable @typescript-eslint/no-explicit-any */
"use client";

import { Suspense, useEffect, useState } from "react";
import Loading from "@/components/loading";
import { PostList } from "@/components/feed/post-list";
import NavBar from "@/components/nav-bar";
import { useContentDetails } from "./hooks/use-content-details";
import { usePosts } from "./hooks/use-posts";
import CommentModal from "@/components/comments/comment-modal";
import { PostInteractionWrapper } from "@/components/feed/post-interaction-wrapper";
import { AuthPopup } from "@/components/auth/auth-popup";
import { useAuth } from "./context/auth-context";
import { useAuthRequired } from "./hooks/use-auth-required";
import { useScrollAuthPrompt } from "./hooks/use-scroll-auth-prompt";
import { useMobileAuthPrompt } from "./hooks/use-mobile-auth-prompt";
import { useSearchParams } from "next/navigation";
import Notification from "@/components/story/notification";
import { useRouter } from "next/navigation";
import { ShareModal } from "@/components/feed/share-modal";

import { ReportModal } from "@/components/feed/report-modal";
import { useDeleteStory } from "@/app/hooks/use-delete";
import { useReportContent } from "@/app/hooks/use-report";
import { useHideContent } from "@/app/hooks/use-hide";
import { useShare } from "@/app/hooks/use-share";
import { trackEvent } from "@/lib/mixpanel";

export default function Page() {
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [isShareModalOpen, setIsShareModalOpen] = useState(false);
  const [selectedShareContentId, setSelectedShareContentId] = useState<
    number | null
  >(null);

  const [notificationMessage, setNotificationMessage] = useState<string | null>(
    null
  );
  const [notificationTitle, setNotificationTitle] = useState<
    string | undefined
  >(undefined);

  const { isAuthenticated } = useAuth();
  const { requireAuth } = useAuthRequired();
  const { showPrompt, setShowPrompt } = useScrollAuthPrompt();
  const { showPrompt: showMobilePrompt, setShowPrompt: setShowMobilePrompt } = useMobileAuthPrompt();
  
  // Debug logging
  console.log("Page render - Mobile prompt state:", { showMobilePrompt, isAuthenticated });
  const [sidebarKey, setSidebarKey] = useState(0);

  const searchParams = useSearchParams();
  const router = useRouter();

  // Clear newly posted story on page reload
  useEffect(() => {
    const handleBeforeUnload = () => {
      sessionStorage.removeItem("newlyPostedStory");
    };
    
    window.addEventListener("beforeunload", handleBeforeUnload);
    return () => window.removeEventListener("beforeunload", handleBeforeUnload);
  }, []);

  const [showReportModal, setShowReportModal] = useState(false);
  const [reportPostId, setReportPostId] = useState<number | null>(null);

  const {
    deleteStory,
    loading: deleteLoading,
    error: deleteError,
  } = useDeleteStory();
  const {
    reportContent,
    loading: reportLoading,
    error: reportError,
  } = useReportContent();
  const {
    hideContent,
    loading: hideLoading,
    error: hideError,
  } = useHideContent();

  const {
    shareContent,
    loading: shareLoading,
    error: shareError,
    fetchSharedContent,
    convertToExtendedPost,
    clearShareContent,
  } = useShare();

  // State to track if we're showing shared content
  const [isShowingSharedContent, setIsShowingSharedContent] = useState(false);

  // Convert share content to ContentDetails format for comment modal
  const getContentDetailsForModal = () => {
    if (isShowingSharedContent && shareContent) {
      return {
        id: shareContent.id,
        unique_id: shareContent.id,
        title: shareContent.title,
        description: shareContent.description,
        image_url: shareContent.image_url,
        location: shareContent.location,
        source_url: "",
        created_at: new Date().toISOString(),
        user: {
          id: shareContent.user.id,
          username: shareContent.user.username,
          profile_picture_url: shareContent.user.profile_picture_url,
        },
        user_reaction: shareContent.user_reaction?.replace("ReactionType.", "") || null,
        total_reactions: shareContent.total_reactions,
        top_reactions: Object.entries(shareContent.reaction_breakdown)
          .filter(([_, count]) => count > 0)
          .sort(([, a], [, b]) => b - a)
          .slice(0, 3)
          .map(([reaction]) => reaction),
        comments: shareContent.comments.map(comment => ({
          id: comment.id,
          content: comment.content,
          user_id: comment.user_id,
          created_at: comment.created_at,
          user_reaction: null,
          reactions: { user_reaction: null },
          total_reactions: 0,
          user: comment.user,
          parent_id: null,
          replies_count: comment.replies_count,
          replies: [],
        })),
      };
    }
    return contentDetails;
  };

  const {
    posts,
    setPosts,
    loading,
    locationLoading,
    hasMore,
    hoveredPostId,
    setHoveredPostId,
    handlePostReaction,
    handleRepost,
    loadMorePosts,
    location,
    handleLocationChange,
  } = usePosts();

  // Check for newly posted story and keep it as first post
  useEffect(() => {
    const newPostParam = searchParams.get("newPost");
    if (newPostParam === "true") {
      const newlyPostedStory = sessionStorage.getItem("newlyPostedStory");
      if (newlyPostedStory) {
        try {
          const newPost = JSON.parse(newlyPostedStory);
          // Get the location from the new post and update feed location
          const postLocation = newPost.location;
          if (postLocation) {
            // Update the feed location to match the post's location
            handleLocationChange(postLocation);
          }
          
          // Add the new post to the top of the feed and keep it there
          setPosts((prevPosts: any) => {
            // Remove any existing post with the same ID to avoid duplicates
            const filteredPosts = prevPosts.filter((post: any) => post.id !== newPost.id);
            // Add the new post at the top
            return [newPost, ...filteredPosts];
          });
          // DON'T clear the sessionStorage - keep it until page reload
          // Remove the URL parameter
          router.replace("/?notification=success", { scroll: false });
        } catch (error) {
          console.error("Error parsing newly posted story:", error);
        }
      }
    }
  }, [searchParams, setPosts, router, handleLocationChange]);

  // Keep newly posted story at the top on every render (until page reload)
  useEffect(() => {
    const newlyPostedStory = sessionStorage.getItem("newlyPostedStory");
    if (newlyPostedStory) {
      try {
        const newPost = JSON.parse(newlyPostedStory);
        setPosts((prevPosts: any) => {
          // Check if the new post is already at the top
          if (prevPosts.length > 0 && prevPosts[0].id === newPost.id) {
            return prevPosts; // Already at top, no need to change
          }
          // Remove any existing post with the same ID and add to top
          const filteredPosts = prevPosts.filter((post: any) => post.id !== newPost.id);
          return [newPost, ...filteredPosts];
        });
      } catch (error) {
        console.error("Error parsing newly posted story:", error);
      }
    }
  }, [setPosts]);

  // Content detail logic
  const {
    contentDetails,
    loadings: detailLoading,
    error,
    getContentDetails,
  } = useContentDetails();

  // -------------- Integrating Delete --------------
  async function handleDeletePost(postId: number) {
    requireAuth(async () => {
      const res = await deleteStory(postId);
      if (res) {
        setNotificationMessage("Post deleted successfully!");
        setPosts((prev: any) => prev.filter((p: any) => p.id !== postId));
      }
    });
  }

  async function handleHidePost(postId: number) {
    requireAuth(async () => {
      const res = await hideContent(postId);
      if (res) {
        setNotificationMessage("Post hidden from your feed!");
        // Remove from your feed
        setPosts((prev: any) => prev.filter((p: any) => p.id !== postId));
      }
    });
  }

  function openReportModal(postId: number) {
    setReportPostId(postId);
    setShowReportModal(true);
  }

  async function onSubmitReport(reason: string, customReason?: string) {
    if (!reportPostId) return;
    const payload = {
      content_id: reportPostId,
      reason,
      custom_reason: customReason,
    };
    const res = await reportContent(payload);
    if (res) {
      setNotificationMessage("Thanks! Your report has been submitted.");
      setReportPostId(null);
    }
  }

  useEffect(() => {
    const user_id = searchParams.get("user_id");
    const username = searchParams.get("username");
    const email = searchParams.get("email");
    const first_name = searchParams.get("name");
    const last_name = searchParams.get("last_name") ?? "";
    const profile_picture_url = searchParams.get("profile_picture_url") ?? "";
    const location = searchParams.get("location");
    const displayHomeLocationParam = searchParams.get("display_home_location");

    if (user_id && username && email) {
      let baseUser: Record<string, any> = {};
      const storedUser = sessionStorage.getItem("user");
      if (storedUser) {
        try {
          baseUser = JSON.parse(storedUser) || {};
        } catch (error) {
          console.error("Failed to parse existing session user:", error);
        }
      }

      const userData: Record<string, any> = {
        ...baseUser,
        user_id,
        username,
        email,
        first_name,
        last_name,
        profile_picture_url,
      };

      if (location !== null) {
        userData.location = location;
        userData.home_location = location;
      } else {
        const canonicalLocation =
          (typeof userData.location === "string" && userData.location) ||
          (typeof userData.home_location === "string" && userData.home_location) ||
          "";
        userData.location = canonicalLocation;
        userData.home_location = canonicalLocation;
      }

      if (displayHomeLocationParam !== null) {
        userData.display_home_location = displayHomeLocationParam !== "false";
      }
      userData.display_home_location = userData.display_home_location !== false;

      sessionStorage.setItem("user_id", user_id.toString());
      sessionStorage.setItem("user", JSON.stringify(userData));

      const newParams = new URLSearchParams(searchParams.toString());
      newParams.delete("user_id");
      newParams.delete("username");
      newParams.delete("email");
      newParams.delete("name");
      newParams.delete("last_name");
      newParams.delete("profile_picture_url");
      newParams.delete("login_type");
      router.replace("?" + newParams.toString(), { scroll: false });

      setSidebarKey((prev) => prev + 1);
    }
  }, [searchParams, router]);

  useEffect(() => {
    const notification = searchParams.get("notification");
    if (!loading && posts.length > 0 && notification === "success") {
      setNotificationMessage(
        "Celebrate your moment and let others discover it\non the map"
      );
      setNotificationTitle("Your story is live!");
      
      // Remove the notification parameter from URL to prevent showing again on reload
      const newParams = new URLSearchParams(searchParams.toString());
      newParams.delete("notification");
      router.replace("?" + newParams.toString(), { scroll: false });
    }
  }, [loading, posts.length, searchParams, router]);

  useEffect(() => {
    if (notificationMessage) {
      const timer = setTimeout(() => {
        setNotificationMessage(null);
        setNotificationTitle(undefined);
      }, 3000); // 3 seconds

      return () => clearTimeout(timer); // Cleanup
    }
  }, [notificationMessage]);

  useEffect(() => {
    const notif = searchParams.get("notification");
    const postId = searchParams.get("post_id");
    const type = searchParams.get("type");
    if (notif === "true" && postId && type) {
      getContentDetails(type, postId);
      setShowModal(true);

      const newParams = new URLSearchParams(searchParams.toString());
      newParams.delete("notification");
      newParams.delete("post_id");
      newParams.delete("type");
      router.replace("?" + newParams.toString(), { scroll: false });
    }
  }, [searchParams, getContentDetails, router]);

  useEffect(() => {
    // Only load more posts if we have some posts but less than 5, and we're not in the middle of a location change
    if (!loading && posts.length > 0 && posts.length < 5 && hasMore) {
      loadMorePosts();
    }
  }, [loading, posts.length, loadMorePosts, hasMore]);

  // Handle share functionality
  useEffect(() => {
    const shareId = searchParams.get("shareId");
    if (shareId && !shareLoading && !shareContent) {
      fetchSharedContent(shareId).then((content) => {
        if (content) {
          // Set flag to indicate we're showing shared content
          setIsShowingSharedContent(true);
          setShowModal(true);
          
          // Clean up URL parameters
          const newParams = new URLSearchParams(searchParams.toString());
          newParams.delete("shareId");
          router.replace("?" + newParams.toString(), { scroll: false });
        }
      });
    }
  }, [searchParams, shareLoading, shareContent, fetchSharedContent, router]);

  // Track landing_viewed (for unauthenticated users) and feed_viewed (for authenticated users)
  useEffect(() => {
    if (!loading) {
      if (!isAuthenticated) {
        // Track landing page view for unauthenticated users
        trackEvent("landing_viewed");
      } else {
        // Determine source for feed view
        const referrer = typeof document !== "undefined" ? document.referrer : "";
        const source = referrer 
          ? (referrer.includes(window.location.hostname) ? "internal" : "external")
          : "direct";
        
        // Track feed view for authenticated users
        trackEvent("feed_viewed", { source });
        
        // Track session_started (first feed load of the day)
        const today = new Date().toDateString();
        const lastSessionDate = localStorage.getItem("mixpanel_last_session_date");
        
        if (lastSessionDate !== today) {
          trackEvent("session_started", { source });
          localStorage.setItem("mixpanel_last_session_date", today);
        }
      }
    }
  }, [loading, isAuthenticated]);


  if (loading && posts.length === 0) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loading />
      </div>
    );
  }

  return (
    <>
      {/* existing code */}
      {notificationMessage && (
        <div className="fixed top-20 right-4 z-50">
          <Notification
            title={notificationTitle || ""}
            message={notificationMessage}
            type={error ? "error" : "success"}
            onClose={() => {
              setNotificationMessage(null);
              setNotificationTitle(undefined);
            }}
            onHomeClick={() => null}
          />
        </div>
      )}

      <Suspense fallback={<Loading />}>
        <div className="w-full mx-auto p-4 min-h-screen">
          <NavBar
            title="Feed"
            showNotification={true}
            showMessage={true}
            isAuthenticated={isAuthenticated}
            location={location}
            onLocationChange={handleLocationChange}
          />

          <PostInteractionWrapper>
            {(requireAuth) => (
              <PostList
                posts={posts}
                loading={loading}
                locationLoading={locationLoading}
                hasMore={hasMore}
                hoveredPostId={hoveredPostId}
                setHoveredPostId={setHoveredPostId}
                onReactionSelect={(postId, reactionType) => {
                  requireAuth(() => handlePostReaction(postId, reactionType));
                }}
                onRepostSelect={(postId) => {
                  requireAuth(() => handleRepost(postId));
                }}
                onOpenComments={(contentType, contentId) => {
                  requireAuth(() => {
                    getContentDetails(contentType, contentId);
                    setShowModal(true);
                    // Track comment modal opened
                    trackEvent("comments_opened", {
                      content_id: contentId,
                      content_type: contentType,
                    });
                  });
                }}
                onShare={(postId) => {
                  requireAuth(() => {
                    setSelectedShareContentId(postId);
                    setIsShareModalOpen(true);
                  });
                }}
                onLinkCopied={() => {
                  setNotificationMessage("Link copied to clipboard!");
                  setNotificationTitle("Link Copied");
                }}
                onImageClick={(imageUrl) => setSelectedImage(imageUrl)}
                onLoadMore={loadMorePosts}
                isAuthenticated={isAuthenticated}
                // NEW callbacks:
                onDeletePost={handleDeletePost}
                onHidePost={handleHidePost}
                onReportPost={openReportModal}
              />
            )}
          </PostInteractionWrapper>

       

          <CommentModal
            isOpen={showModal}
            onClose={() => {
              setShowModal(false);
              setIsShowingSharedContent(false);
              clearShareContent();
            }}
            contentDetails={getContentDetailsForModal()}
            isLoading={isShowingSharedContent ? shareLoading : detailLoading}
            error={isShowingSharedContent ? shareError : error}
            isAuthenticated={isAuthenticated}
            requireAuth={requireAuth}
            onPostReactionSelect={(postId, reactionType) => {
              requireAuth(() => handlePostReaction(postId, reactionType));
            }}
          />

          <AuthPopup
            isOpen={showPrompt}
            onClose={() => setShowPrompt(false)}
            action="scroll"
          />

          {/* Mobile onboarding popup for unauthenticated users */}
          <AuthPopup
            isOpen={showMobilePrompt}
            onClose={() => setShowMobilePrompt(false)}
          />
        </div>
      </Suspense>

      {/* Share Modal */}
      <ShareModal
        isOpen={isShareModalOpen}
        onClose={() => {
          setIsShareModalOpen(false);
          setSelectedShareContentId(null);
        }}
        contentId={selectedShareContentId ?? 0}
      />

      {/* Report Modal */}
      <ReportModal
        isOpen={showReportModal}
        onClose={() => setShowReportModal(false)}
        onSubmit={onSubmitReport}
      />
    </>
  );
}