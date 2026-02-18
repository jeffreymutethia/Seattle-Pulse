"use client";

import { MapPin, MoreHorizontal } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useEffect, useState } from "react";
import ReactPlayer from "react-player";
import Image from "next/image";

interface PreviewStepProps {
  caption: string;
  location: string;
  previewUrl: string;
  /** NEW: the MIME type of the selected file (e.g. "image/jpeg", "video/mp4") */
  fileType?: string;
}

interface User {
  user_id: number;
  username: string;
  email: string;
  first_name: string;
  last_name: string;
  profile_picture_url: string;
}

export default function PreviewStep({
  caption,
  location,
  previewUrl,
  fileType,
}: PreviewStepProps) {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    const storedUser = sessionStorage.getItem("user");
    if (storedUser) {
      setUser(JSON.parse(storedUser));
    }
  }, []);

  // Determine by MIME type instead of ReactPlayer.canPlay
  const isVideo = fileType?.startsWith("video/");
  
  // Check if the video format is well-supported by ReactPlayer
  const isReactPlayerSupported = (mimeType: string) => {
    const supportedFormats = [
      'video/mp4',
      'video/webm',
      'video/ogg',
      'video/quicktime',
      'video/x-msvideo' // AVI
    ];
    return supportedFormats.includes(mimeType);
  };
  
  // Check if the image format needs special handling (HEIC, etc.)
  const needsImageFallback = (mimeType: string) => {
    const problematicFormats = [
      'image/heic',
      'image/heif'
    ];
    return problematicFormats.includes(mimeType);
  };

  return (
    <>
      {/* MOBILE */}
      <div className="md:hidden px-4">
        <div className="bg-white rounded-3xl shadow-lg p-4 space-y-4">
          <header>
            <h2 className="text-center text-lg text-[#0C1024] font-bold mb-1">
              Preview
            </h2>
            <p className="text-center text-sm text-[#5D6778]">
              Take one last look at your story. If everything looks good, click
              &quot;Post Story&quot; to share it with the world. Need changes? Go back
              and edit!
            </p>
          </header>

          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Image
                src={user?.profile_picture_url || "/placeholder.svg"}
                alt="User"
                width={32}
                height={32}
                className="w-8 h-8 rounded-full"
              />
              <span className="text-sm font-semibold text-[#0C1024]">
                {user?.first_name} {user?.last_name}
              </span>
            </div>
            <div className="flex items-center gap-2">
              <div className="flex items-center gap-1 w-32 min-w-0">
                <MapPin className="w-3 h-3 text-gray-500 flex-shrink-0" />
                <span className="text-xs text-gray-600 truncate">{location}</span>
              </div>
              <Button variant="ghost" size="icon">
                <MoreHorizontal className="w-4 h-4" />
              </Button>
            </div>
          </div>

          <div>
            {isVideo ? (
              isReactPlayerSupported(fileType || '') ? (
                <div className="rounded-xl overflow-hidden">
                  <ReactPlayer
                    url={previewUrl}
                    controls
                    width="100%"
                    height="200px"
                  />
                </div>
              ) : (
                <video
                  src={previewUrl}
                  controls
                  className="w-full h-40 rounded-xl"
                  style={{ width: '100%', height: '160px' }}
                >
                  Your browser does not support the video tag.
                </video>
              )
            ) : (
              needsImageFallback(fileType || '') ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={previewUrl || "/placeholder.svg"}
                  alt="Post preview"
                  className="w-full h-40 object-cover rounded-xl"
                />
              ) : (
                <Image
                  src={previewUrl || "/placeholder.svg"}
                  alt="Post preview"
                  width={400}
                  height={160}
                  className="w-full h-40 object-cover rounded-xl"
                />
              )
            )}
          </div>

          <p className="text-[#4B5669]">{caption || "No caption"}</p>
        </div>
      </div>

      {/* DESKTOP */}
      <div className="hidden md:block">
        <div className="mb-2 py-1 text-center">
          <h2 className="text-xl text-[#0C1024] font-bold">Preview</h2>
          <p className="text-sm text-[#5D6778]">
            Take one last look at your story. <br />
            Click &quot;Post Story&quot; to share it with the world. Need changes? Go
            back and edit!
          </p>
        </div>

        <div className="max-w-[681px] mx-auto">
          <div className="rounded-3xl border p-4 bg-white text-card-foreground">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 p-2 font-semibold text-lg">
                <Image
                  src={user?.profile_picture_url || "/placeholder.svg"}
                  alt="User"
                  width={40}
                  height={40}
                  className="rounded-full w-10 h-10"
                />
                <span>{user?.first_name} {user?.last_name}</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="flex items-center gap-1 w-48 min-w-0">
                  <MapPin className="h-3 w-3 text-gray-500 flex-shrink-0" />
                  <p className="text-base text-gray-600 truncate">{location}</p>
                </div>
                <Button variant="ghost" size="icon" className="flex-shrink-0">
                  <MoreHorizontal className="h-4 w-4" />
                </Button>
              </div>
            </div>

            <div className="mt-4 px-4 w-full">
              {isVideo ? (
                isReactPlayerSupported(fileType || '') ? (
                  <div className="rounded-xl overflow-hidden">
                    <ReactPlayer
                      url={previewUrl}
                      controls
                      width="100%"
                      height="360px"
                    />
                  </div>
                ) : (
                  <video
                    src={previewUrl}
                    controls
                    className="w-full h-60 rounded-xl"
                    style={{ width: '100%', height: '240px' }}
                  >
                    Your browser does not support the video tag.
                  </video>
                )
              ) : (
                needsImageFallback(fileType || '') ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={previewUrl || "/placeholder.svg"}
                    alt="Post preview"
                    className="w-full h-60 object-cover rounded-xl"
                  />
                ) : (
                  <Image
                    src={previewUrl || "/placeholder.svg"}
                    alt="Post preview"
                    width={600}
                    height={240}
                    className="w-full h-60 object-cover rounded-xl"
                  />
                )
              )}
            </div>

            <div className="px-4 py-2">
              <p className="text-[#4B5669]">{caption }</p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
