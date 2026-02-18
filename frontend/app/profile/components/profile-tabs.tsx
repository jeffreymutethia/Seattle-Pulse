/* eslint-disable @typescript-eslint/no-explicit-any */
"use client"
import { useState } from "react"
import Image from "next/image"
import PhotoGrid from "./post"
import MyMapComponent from "./location-map"
import RepostPhotoGrid from "./repost"

interface ProfileTabsProps {
  posts: any[]
  reposts: any[]
  userid: any
  activeTab?: 'posts' | 'reposts' | 'location'
  setActiveTab?: (tab: 'posts' | 'reposts' | 'location') => void
  postsRef?: any
  repostsRef?: any
  loadingMorePosts?: boolean
  loadingMoreReposts?: boolean
  hasMorePosts?: boolean
  hasMoreReposts?: boolean
}

export default function ProfileTabs({ 
  posts, 
  reposts, 
  userid, 
  activeTab: externalActiveTab,
  setActiveTab: externalSetActiveTab,
  postsRef,
  repostsRef,
  loadingMorePosts = false,
  loadingMoreReposts = false,
  
}: ProfileTabsProps) {

  const [internalActiveTab, setInternalActiveTab] = useState<'posts' | 'reposts' | 'location'>('posts')
  
  // Use external state if provided, otherwise use internal state
  const activeTab = externalActiveTab || internalActiveTab
  const setActiveTab = externalSetActiveTab || setInternalActiveTab

  return (
    <div className="mt-6">
      <div className="w-full flex justify-center border-t bg-transparent space-x-6 ">
        <button
          onClick={() => setActiveTab("posts")}
          className={`flex items-center pt-2 space-x-2 ${activeTab === "posts" ? "border-t-2 border-primary text-black" : "text-gray-500"}`}
        >
          <Image
            src="/Feed.svg"
            alt="Feed"
            width={24}
            height={24}
            style={{
              filter: activeTab === "posts" ? "invert(0%)" : "invert(40%)", // Active = black, Inactive = gray
            }}
          />
          <span data-cy="posts-btn" className={`${activeTab === "posts" ? "text-black font-medium" : "text-gray-500"}`}>Posts</span>
        </button>

        <button
          onClick={() => setActiveTab("reposts")}
          className={`flex pt-2 items-center space-x-2 ${activeTab === "reposts" ? "border-t-2 border-primary text-black" : "text-gray-500"}`}
        >
          <Image
            src="/Refresh.svg"
            alt="Repost"
            width={24}
            height={24}
            style={{
              filter: activeTab === "reposts" ? "invert(100%)" : "invert(40%)", // Active = black, Inactive = gray
            }}
          />
          <span className={`${activeTab === "reposts" ? "text-black font-medium" : "text-gray-500"}`}>Reposts</span>
        </button>

        <button
          onClick={() => setActiveTab("location")}
          className={`flex pt-2 items-center space-x-2 ${activeTab === "location" ? "border-t-2 border-primary text-black" : "text-gray-500"}`}
        >
          <Image
            src="/MapPoint.svg"
            alt="Location"
            width={24}
            height={24}
            style={{
              filter: activeTab === "location" ? "invert(100%)" : "invert(40%)", // Active = black, Inactive = gray
            }}
          />
          <span className={`${activeTab === "location" ? "text-black font-medium" : "text-gray-500"}`}>Location Map</span>
        </button>
      </div>

      <div className="mt-4">
        {activeTab === "posts" && (
          <div>
            <PhotoGrid posts={posts} />
            {postsRef && <div ref={postsRef} />}
            {loadingMorePosts && (
              <div className="py-4 flex justify-center">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
              </div>
            )}
           
          </div>
        )}
        {activeTab === "reposts" && (
          <div>
            <RepostPhotoGrid reposts={reposts} />
            {repostsRef && <div ref={repostsRef} />}
            {loadingMoreReposts && (
              <div className="py-4 flex justify-center">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
              </div>
            )}
            
          </div>
        )}
        {activeTab === "location" && <MyMapComponent userId={userid} />}
      </div>
    </div>
  );
}
