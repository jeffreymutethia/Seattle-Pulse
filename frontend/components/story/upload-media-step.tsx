import React from "react";
import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { UploadState } from "@/app/types/story";
import ReactPlayer from "react-player";
import Image from "next/image";

interface UploadMediaStepProps {
  uploadState: UploadState;
  uploadProgress: number;
  selectedFile: File | null;
  previewUrl: string;
  errorMessage?: string;
  onFileSelect: (file: File) => void;
  onReset: () => void;
}

export default function UploadMediaStep({
  uploadState,
  uploadProgress,
  selectedFile,
  previewUrl,
  errorMessage,
  onFileSelect,
  onReset,
}: UploadMediaStepProps) {
  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) onFileSelect(file);
  };

  // ONLY treat it as video if the selected file's MIME type starts with "video/"
  const isVideo = selectedFile?.type.startsWith("video/");
  
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
    <div className="px-4 md:px-0">
      {/* Header */}
      <div className="mb-8">
        <h2 className="text-center text-xl md:text-2xl font-bold text-[#0C1024] mb-2">
          Upload Media
        </h2>
        <p className="text-center text-sm md:text-base text-[#5D6778]">
          Select a photo or video from your gallery to share your story.
        </p>
      </div>

      {/* Media container */}
      <div className="rounded-3xl overflow-hidden bg-white h-auto md:h-[466px]">
        {uploadState === "uploading" ? (
          <div className="h-full flex flex-col justify-center p-4 md:p-8">
            {/* File info + cancel */}
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="h-12 w-12 rounded-lg bg-gray-100 overflow-hidden">
                  <Image
                    src="/placehold.png"
                    alt="File thumbnail"
                    width={48}
                    height={48}
                    className="object-cover w-full h-full"
                  />
                </div>
                <div>
                  <p className="font-medium text-base md:text-lg truncate">
                    {selectedFile?.name}
                  </p>
                  <p className="text-sm text-[#5D6778]">
                    {uploadProgress}% •{" "}
                    {Math.round((selectedFile?.size || 0) / 1024)} KB
                  </p>
                </div>
              </div>
              <Button
                variant="ghost"
                size="icon"
                className="hover:bg-transparent"
                onClick={onReset}
              >
                <X className="h-4 w-4" />
              </Button>
            </div>

            {/* Progress bar */}
            <div className="w-full md:max-w-2xl mx-auto">
              <Progress
                value={uploadProgress}
                className="h-3 bg-[#E1E2F8] [&>div]:bg-[#428553]"
              />
            </div>
          </div>
        ) : uploadState === "success" ? (
          <div className="h-full flex items-center justify-center p-4 md:p-0">
            <div className="relative w-full md:max-w-5xl h-auto md:h-[466px]">
              {isVideo ? (
                isReactPlayerSupported(selectedFile?.type || '') ? (
                  <ReactPlayer
                    url={previewUrl}
                    controls
                    width="100%"
                    height="100%"
                    className="rounded-3xl overflow-hidden"
                  />
                ) : (
                  <video
                    src={previewUrl}
                    controls
                    className="w-full h-auto md:h-[466px] rounded-3xl"
                    style={{ width: '100%', height: '100%' }}
                  >
                    Your browser does not support the video tag.
                  </video>
                )
              ) : (
                needsImageFallback(selectedFile?.type || '') ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={previewUrl || "/placeholder.svg"}
                    alt="Preview"
                    className="object-cover w-full h-auto md:h-[466px] rounded-3xl"
                    style={{ width: '100%', height: '100%' }}
                  />
                ) : (
                  <Image
                    src={previewUrl || "/placeholder.svg"}
                    alt="Preview"
                    width={800}
                    height={466}
                    className="object-cover w-full h-auto md:h-[466px] rounded-3xl"
                  />
                )
              )}
              <Button
                variant="ghost"
                size="icon"
                className="absolute top-2 right-2 bg-black/50 hover:bg-black/70"
                onClick={onReset}
              >
                <X className="h-4 w-4 text-white" />
              </Button>
            </div>
          </div>
        ) : uploadState === "error" ? (
          <div className="h-full bg-white border-2 border-dashed border-red-500 rounded-3xl flex flex-col items-center justify-center p-6">
            <Image
              src="./Upload.png"
              width={48}
              height={48}
              className="mx-auto h-12 w-12 mb-4"
              alt="Upload icon"
            />
            <h3 className="text-lg font-bold mb-2 text-red-600">
              Upload Failed
            </h3>
            {errorMessage && (
              <p className="text-sm text-red-500 mb-4 text-center max-w-md">
                {errorMessage}
              </p>
            )}
            <p className="text-sm text-gray-500 mb-6">
              Please try again or contact support if the issue persists.
            </p>
            <div className="flex gap-3">
              <Button
                onClick={onReset}
                className="h-12 px-6 rounded-full border-2 border-red-500 bg-white hover:bg-red-50 text-red-500"
              >
                Try Again
              </Button>
              <label htmlFor="file-upload">
                <input
                  id="file-upload"
                  type="file"
                  className="hidden"
                  onChange={handleFileInput}
                  accept="image/jpeg,image/jpg,image/png,image/gif,image/webp,image/bmp,image/tiff,image/svg+xml,image/heic,image/heif,video/mp4,video/mpeg,video/quicktime,video/x-msvideo,video/webm,video/ogg,video/3gpp,video/x-ms-wmv,video/x-flv,video/x-matroska"
                />
                <Button
                  onClick={() =>
                    document.getElementById("file-upload")?.click()
                  }
                  className="h-12 px-6 rounded-full border-2 border-black bg-white hover:bg-gray-50"
                >
                  Browse Files
                </Button>
              </label>
            </div>
          </div>
        ) : (
          <div className="h-full flex flex-col items-center justify-center p-6 md:p-0 border-2 border-dashed border-[#A5A9E9] rounded-3xl bg-[#E1E2F8]">
            <Image
              src="/Upload.png"
              width={48}
              height={48}
              alt="Upload icon"
              className="h-12 w-12 mb-4"
            />
            <h3 className="text-lg font-bold mb-2">
              Choose a file or drag & drop it here
            </h3>
            <p className="text-sm text-gray-500 mb-6">
              Images (JPEG, PNG, GIF, WebP, HEIC, etc.) and Videos (MP4, MOV, AVI, etc.), up to 100MB
            </p>
            <label htmlFor="file-upload">
              <input
                id="file-upload"
                type="file"
                className="hidden"
                onChange={handleFileInput}
                accept="image/jpeg,image/jpg,image/png,image/gif,image/webp,image/bmp,image/tiff,image/svg+xml,image/heic,image/heif,video/mp4,video/mpeg,video/quicktime,video/x-msvideo,video/webm,video/ogg,video/3gpp,video/x-ms-wmv,video/x-flv,video/x-matroska"
              />
              <Button
                onClick={() =>
                  document.getElementById("file-upload")?.click()
                }
                className="h-12 w-full md:w-[156px] rounded-full border-2 text-black border-black bg-white hover:bg-gray-50"
              >
                Browse Files
              </Button>
            </label>
          </div>
        )}
      </div>
    </div>
  );
}
