/* eslint-disable @typescript-eslint/no-explicit-any */
"use client";

import { useState, useEffect, useCallback } from "react";
import { useParams } from "next/navigation";
import { useInView } from "react-intersection-observer";

import ProfileHeader from "../components/profile-Header";
import ProfileTabs from "../components/profile-tabs";
import {
  HeaderSkeleton,
  ProfileHeaderSkeleton,
  ProfileTabsSkeleton,
} from "../components/loading-skeleton";
import { ErrorState } from "../components/error-state";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import NavBar from "@/components/nav-bar";
import { useAuth } from "@/app/context/auth-context";

import {
  fetchUserProfile,
  fetchUserPosts,
  fetchUserReposts,
  toggleFollow,
} from "@/app/services/profile-service";
import { trackEvent } from "@/lib/mixpanel";

export default function ProfilePage() {
  const params = useParams() as { username: string };
  const [userData, setUserData] = useState<any | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [posts, setPosts] = useState<any[]>([]);
  const [reposts, setReposts] = useState<any[]>([]);
  
  // Pagination state
  const [postsPage, setPostsPage] = useState(1);
  const [repostsPage, setRepostsPage] = useState(1);
  const [hasMorePosts, setHasMorePosts] = useState(true);
  const [hasMoreReposts, setHasMoreReposts] = useState(true);
  const [loadingMorePosts, setLoadingMorePosts] = useState(false);
  const [loadingMoreReposts, setLoadingMoreReposts] = useState(false);
  const [activeTab, setActiveTab] = useState<'posts' | 'reposts' | 'location'>('posts');

  const { isAuthenticated } = useAuth();
  const loggedInUserId =
    typeof window !== "undefined" ? sessionStorage.getItem("user_id") : null;

  // Intersection observer for infinite scroll
  const { ref: postsRef, inView: postsInView } = useInView({
    threshold: 0.1,
  });

  const { ref: repostsRef, inView: repostsInView } = useInView({
    threshold: 0.1,
  });

  useEffect(() => {
    if (!params?.username) return;
    loadProfile(params.username);
  }, [params?.username]);

  const loadProfile = async (username: string) => {
    try {
      setLoading(true);
      setError(null);

      const profileResponse = await fetchUserProfile(username);
      setUserData(profileResponse);

      // Load first page of posts and reposts
      const postsResponse = await fetchUserPosts(username, 1, 20);
      setPosts(postsResponse.data.posts || []);
      setHasMorePosts((postsResponse.data.posts || []).length === 20);

      const repostsResponse = await fetchUserReposts(username, 1, 20);
      setReposts(repostsResponse.data.reposts || []);
      setHasMoreReposts((repostsResponse.data.reposts || []).length === 20);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const loadMorePosts = useCallback(async () => {
    if (loadingMorePosts || !hasMorePosts || !params?.username) return;
    
    setLoadingMorePosts(true);
    try {
      const nextPage = postsPage + 1;
      const postsResponse = await fetchUserPosts(params.username, nextPage, 20);
      const newPosts = postsResponse.data.posts || [];
      
      setPosts(prev => [...prev, ...newPosts]);
      setPostsPage(nextPage);
      setHasMorePosts(newPosts.length === 20);
    } catch (err: any) {
      console.error("Error loading more posts:", err);
    } finally {
      setLoadingMorePosts(false);
    }
  }, [postsPage, hasMorePosts, loadingMorePosts, params?.username]);

  const loadMoreReposts = useCallback(async () => {
    if (loadingMoreReposts || !hasMoreReposts || !params?.username) return;
    
    setLoadingMoreReposts(true);
    try {
      const nextPage = repostsPage + 1;
      const repostsResponse = await fetchUserReposts(params.username, nextPage, 20);
      const newReposts = repostsResponse.data.reposts || [];
      
      setReposts(prev => [...prev, ...newReposts]);
      setRepostsPage(nextPage);
      setHasMoreReposts(newReposts.length === 20);
    } catch (err: any) {
      console.error("Error loading more reposts:", err);
    } finally {
      setLoadingMoreReposts(false);
    }
  }, [repostsPage, hasMoreReposts, loadingMoreReposts, params?.username]);

  // Load more posts when scrolling
  useEffect(() => {
    if (postsInView && activeTab === 'posts') {
      loadMorePosts();
    }
  }, [postsInView, activeTab, loadMorePosts]);

  // Load more reposts when scrolling
  useEffect(() => {
    if (repostsInView && activeTab === 'reposts') {
      loadMoreReposts();
    }
  }, [repostsInView, activeTab, loadMoreReposts]);

  // Track profile view when userData is loaded
  useEffect(() => {
    if (userData?.data?.user_data && params?.username) {
      const profileUserId = userData.data.user_data.id;
      const isOwnProfile = !!loggedInUserId && parseInt(loggedInUserId) === profileUserId;
      trackEvent("profile_viewed", {
        profile_username: params.username,
        profile_user_id: profileUserId,
        is_own_profile: isOwnProfile,
      });
    }
  }, [userData, params?.username, loggedInUserId]);

  const handleFollowToggle = async () => {
    if (!userData) return;
    try {
      const isCurrentlyFollowing = userData.data.is_following;
      const targetUserId = userData.data.user_data.id;
      const targetUsername = userData.data.user_data.username;
      await toggleFollow(targetUserId, isCurrentlyFollowing);
      
      // Track follow/unfollow event
      trackEvent(isCurrentlyFollowing ? "user_unfollowed" : "user_followed", {
        target_user_id: targetUserId,
        target_username: targetUsername,
      });
      
      // Update local state
      setUserData((prev: any) => {
        if (!prev) return prev;
        return {
          ...prev,
          data: {
            ...prev.data,
            is_following: !isCurrentlyFollowing,
            relationships: {
              ...prev.data.relationships,
              followers: isCurrentlyFollowing
                ? prev.data.relationships.followers - 1
                : prev.data.relationships.followers + 1,
            },
          },
        };
      });
    } catch (err: any) {
      alert("Error: " + err.message);
    }
  };

  const profileUserId = userData?.data?.user_data?.id;

  const isMyProfile =
    !!loggedInUserId && parseInt(loggedInUserId) === profileUserId;

  if (loading) {
    return (
      <main className="max-w-6xl mx-auto px-4 py-8">
        <HeaderSkeleton />
        <ProfileHeaderSkeleton />
        <ProfileTabsSkeleton />
      </main>
    );
  }

  if (error) {
    return <ErrorState error={error} />;
  }

  if (!userData) {
    return (
      <Alert className="max-w-2xl mx-auto my-8">
        <AlertTitle>Not Found</AlertTitle>
        <AlertDescription>
          No user data found. This profile might not exist or you might not have
          permission to view it.
        </AlertDescription>
      </Alert>
    );
  }

  return (
    <main className="max-w-6xl mx-auto px-4 py-8">
      <NavBar 
        showLocationSelector={false} 
        title="Profile" 
        isAuthenticated={isAuthenticated}
      />

      <ProfileHeader
        userData={userData}
        isMyProfile={isMyProfile}
        onFollowToggle={handleFollowToggle}
      />

      <ProfileTabs
        posts={posts}
        reposts={reposts}
        userid={userData.data.user_data.id}
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        postsRef={postsRef as any}
        repostsRef={repostsRef as any}
        loadingMorePosts={loadingMorePosts}
        loadingMoreReposts={loadingMoreReposts}
        hasMorePosts={hasMorePosts}
        hasMoreReposts={hasMoreReposts}
      />
    </main>
  );
}
