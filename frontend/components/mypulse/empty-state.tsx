/* eslint-disable @typescript-eslint/no-explicit-any */
import { Search, MapPin } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useState, useEffect, useRef } from "react";
import {
  fetchUserSuggestions,
  toggleFollow,
} from "@/app/services/userSuggestionService";
import { AvatarWithFallback } from "@/components/ui/avatar-with-fallback";
import { Person } from "@/app/types/user";


interface UserCardProps {
  person: Person;
  onFollowToggle: (userId: number) => void;
}

function UserCard({ person, onFollowToggle }: UserCardProps) {
  return (
    <div className="flex-shrink-0 w-48 bg-white rounded-3xl border border-gray-200 p-4">
      <div className="flex flex-col items-center text-center space-y-3">
        {/* Profile Picture */}
        <AvatarWithFallback
          src={person.profile_picture_url}
          alt={`${person.username}'s avatar`}
          person={person}
          size="lg"
        />

        {/* Name */}
        <h3 className="font-semibold text-gray-900 text-md">
          {person.first_name} {person.last_name}
        </h3>

        {/* Location */}
        <div className="flex items-center gap-1 text-gray-500 text-sm">
          <MapPin className="h-5 w-5" />
          <span>{person.location}</span>
        </div>

        {/* Followers */}
        <p className="text-gray-500 text-sm">
          {person.total_followers} followers
        </p>

        {/* Follow Button */}
        <button
          onClick={() => onFollowToggle(person.id)}
          className={`w-full py-2 px-4 rounded-full text-sm font-medium border-2 transition-colors ${
            person.is_following
              ? "bg-gray-100 text-gray-700 border-gray-300"
              : "bg-white text-black border-black hover:bg-gray-50"
          }`}
        >
          {person.is_following ? "Unfollow" : "Follow"}
        </button>
      </div>
    </div>
  );
}

interface EmptyStateProps {
  onFollowSuccess?: () => void;
}

export default function EmptyState({ onFollowSuccess }: EmptyStateProps = {}) {
  const [users, setUsers] = useState<Person[]>([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const scrollContainerRef = useRef<HTMLDivElement>(null);

  const scrollToNext = () => {
    if (scrollContainerRef.current) {
      const container = scrollContainerRef.current;
      
      // Check if container is actually scrollable
      const isScrollable = container.scrollWidth > container.clientWidth;
      
      if (!isScrollable) {
        // Container is not scrollable, try to load more users
        if (hasMore && !isLoadingMore) {
          loadMoreUsers();
        }
        return;
      }
      
      // Get the actual card width from the first card element
      const firstCard = container.querySelector('.flex-shrink-0') as HTMLElement;
      if (!firstCard) return;
      
      const cardWidth = firstCard.offsetWidth;
      const gap = 16; // gap-4 = 16px
      const cardWithGap = cardWidth + gap;
      const containerWidth = container.clientWidth;
      
      // Scroll by 2 cards or 80% of viewport, whichever is smaller
      const scrollAmount = Math.min(cardWithGap * 2, containerWidth * 0.8);
      
      // Use scrollBy which is more reliable across browsers
      container.scrollBy({
        left: scrollAmount,
        behavior: 'smooth'
      });
    }
  };

  const handleFollowToggle = async (userId: number) => {
    try {
      const user = users.find((u) => u.id === userId);
      if (!user) return;

      const isCurrentlyFollowing = user.is_following;
      await toggleFollow(userId, isCurrentlyFollowing);

      setUsers((prevUsers) =>
        prevUsers.map((u) =>
          u.id === userId ? { ...u, is_following: !isCurrentlyFollowing } : u
        )
      );

      // Refresh My Pulse feed if user followed someone (not unfollowed)
      if (!isCurrentlyFollowing && onFollowSuccess) {
        // Small delay to ensure the follow API call completes
        setTimeout(() => {
          onFollowSuccess();
        }, 500);
      }
    } catch (err) {
      console.error("Error toggling follow:", err);
    }
  };

  const loadMoreUsers = async () => {
    if (isLoadingMore || !hasMore) return;
    
    setIsLoadingMore(true);
    try {
      const nextPage = currentPage + 1;
      const newSuggestions = await fetchUserSuggestions(nextPage, 5); // Load 5 more users
      
      if (newSuggestions.length === 0) {
        setHasMore(false);
      } else {
        // Deduplicate users by ID to prevent duplicate keys
        setUsers(prev => {
          const existingIds = new Set(prev.map(user => user.id));
          const uniqueNewUsers = newSuggestions.filter(user => !existingIds.has(user.id));
          return [...prev, ...uniqueNewUsers];
        });
        setCurrentPage(nextPage);
      }
    } catch (err) {
      console.error("Error loading more suggestions:", err);
    } finally {
      setIsLoadingMore(false);
    }
  };

  useEffect(() => {
    const fetchSuggestions = async () => {
      try {
        const suggestions = await fetchUserSuggestions(1, 5); // Load first 5 users
        setUsers(suggestions);
        setHasMore(suggestions.length === 5); // If we got 5, there might be more
      } catch (err) {
        console.error("Error fetching suggestions:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchSuggestions();
  }, []);

  if (loading) {
    return (
      <div className="p-8 space-y-16">
        <div className="flex justify-center">
          <h2 className="text-xl font-semibold">Loading...</h2>
        </div>
      </div>
    );
  }

  return (
    <div className="p-8 space-y-16">
      {/* Empty State */}
      <div className="flex flex-col items-center justify-center space-y-6 max-w-[400px] mx-auto text-center">
        <div className="w-16 h-16 flex items-center justify-center rounded-2xl border">
          <svg
            width="32"
            height="32"
            viewBox="0 0 24 24"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              d="M21 12C21 16.9706 16.9706 21 12 21C7.02944 21 3 16.9706 3 12C3 7.02944 7.02944 3 12 3C16.9706 3 21 7.02944 21 12Z"
              stroke="currentColor"
              strokeWidth="2"
            />
            <path
              d="M3.5 11C3.5 11 7 14.5 12 14.5C17 14.5 20.5 11 20.5 11"
              stroke="currentColor"
              strokeWidth="2"
            />
          </svg>
        </div>
        <div className="space-y-2 ">
          <div className="flex justify-center">
            <h2 className="text-xl font-semibold ">No Posts Yet</h2>
          </div>
          <div className="text-muted-foreground space-y-1">
            <p>There are no posts on &quot;My Pulse&quot; yet.</p>
            <p>Follow users to see their posts.</p>
          </div>
        </div>
        <Button className="rounded-xl w-52 h-12 bg-black text-base text-white hover:bg-black/90">
          <Search className="w-6 h-6 mr-2" />
          Search for Users
        </Button>
      </div>

      {/* People You May Know */}
      <div>
        <div className="flex justify-start">
          <h3 className="text-lg font-medium text-black mb-6">
            People You May Know
          </h3>
        </div>
        <div className="relative">
          <div 
            ref={scrollContainerRef}
            className="flex gap-4 overflow-x-auto pb-4 -mx-8 px-8 scrollbar-hide"
            style={{ 
              scrollBehavior: 'smooth',
              WebkitOverflowScrolling: 'touch' // Enable smooth scrolling on iOS/WebKit
            }}
            onScroll={(e) => {
              const { scrollLeft, scrollWidth, clientWidth } = e.currentTarget;
              // Load more when user scrolls to 80% of the content
              if (scrollLeft + clientWidth >= scrollWidth * 0.8 && hasMore && !isLoadingMore) {
                loadMoreUsers();
              }
            }}
          >
            {users.map((user, index) => (
              <UserCard
                key={`${user.id}-${index}`}
                person={user}
                onFollowToggle={handleFollowToggle}
              />
            ))}
            
            {/* Loading indicator */}
            {isLoadingMore && (
              <div className="flex-shrink-0 w-48 flex items-center justify-center">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
              </div>
            )}
          </div>
          
          {/* Scroll indicator */}
          {hasMore && !isLoadingMore && (
            <div className="absolute right-4 top-1/2 transform -translate-y-1/2">
              <button
                onClick={scrollToNext}
                className="bg-black/20 hover:bg-black/30 rounded-full p-2 transition-colors"
                aria-label="Scroll to next users"
              >
                <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
