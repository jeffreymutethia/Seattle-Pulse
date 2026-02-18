// src/components/PeopleSuggestions.tsx
import { useEffect, useState } from "react";
import { AvatarWithFallback } from "@/components/ui/avatar-with-fallback";
import {
  fetchUserSuggestions,
  toggleFollow,
} from "@/app/services/userSuggestionService";
import { Person } from "@/app/types/user";
import Image from "next/image";
import { MapPin } from "lucide-react";

interface PeopleSuggestionsProps {
  onFollowSuccess?: () => void;
}

export default function PeopleSuggestions({ onFollowSuccess }: PeopleSuggestionsProps = {}) {
  const [users, setUsers] = useState<Person[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  const handleFollowToggle = async (userId: number) => {
    try {
      const user = users.find((u) => u.id === userId);
      if (!user) return;
      const isFollowing = user.is_following;

      await toggleFollow(userId, isFollowing);

      setUsers((prevUsers) =>
        prevUsers.map((u) =>
          u.id === userId ? { ...u, is_following: !isFollowing } : u
        )
      );

      // Refresh My Pulse feed if user followed someone (not unfollowed)
      if (!isFollowing && onFollowSuccess) {
        setTimeout(() => {
          onFollowSuccess();
        }, 500);
      }
    } catch (err) {
      console.error("Error toggling follow:", err);
    }
  };

  useEffect(() => {
    const loadUsers = async () => {
      try {
        const suggestions = await fetchUserSuggestions();
        setUsers(suggestions);
      } catch (err) {
        console.error("Error fetching suggestions:", err);
      } finally {
        setLoading(false);
      }
    };
    loadUsers();
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
    <>
      {/* Desktop Layout */}
      <div className="hidden md:block w-[282px] bg-white border border-[#ECF0F5] rounded-3xl">
        <h2 className="text-lg font-semibold p-6 text-[#0C1024]">
          People You May Know
        </h2>
        <div className="border-b mb-2" />
        <div className="space-y-6 px-6 py-8">
          {users.map((person) => (
            <div key={person.id} className="flex items-center justify-between">
              <div className="flex items-center gap-3 w-[180px]">
                <AvatarWithFallback
                  src={person.profile_picture_url}
                  alt={`${person.username}'s avatar`}
                  person={person}
                  size="md"
                />
                <span className="text-sm font-medium text-gray-900 truncate whitespace-nowrap overflow-hidden w-[120px]">
                  {person.first_name} {person.last_name}
                </span>
              </div>
              <button
                onClick={() => handleFollowToggle(person.id)}
                className="h-8 w-8 flex items-center justify-center text-gray-500 hover:bg-gray-100"
                aria-label={`Connect with ${person.username}`}
              >
                <div className="w-8 h-8 bg-[#F1F4F9] rounded-md flex items-center justify-center">
                  {person.is_following ? (
                    <Image
                      src="https://img.icons8.com/sf-regular/48/delete-sign.png"
                      width={24}
                      height={24}
                      className="w-6 h-6"
                      alt="Unfollow"
                    />
                  ) : (
                    <Image
                      src="/Plus.png"
                      className="w-6 h-6"
                      alt="Follow"
                      width={24}
                      height={24}
                    />
                  )}
                </div>
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Mobile Layout - Horizontal Scrollable Cards */}
      <div className="md:hidden p-4">
        <h2 className="text-white text-lg font-semibold mb-4 px-2">
          People You May Know
        </h2>
        <div className="flex gap-4 overflow-x-auto pb-2 scrollbar-hide">
          {users.map((person) => (
            <div
              key={person.id}
              className="flex-shrink-0 w-48 bg-white rounded-3xl border border-gray-200 p-4"
            >
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
                  onClick={() => handleFollowToggle(person.id)}
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
          ))}
        </div>
      </div>
    </>
  );
}
