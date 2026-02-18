"use client";

import { useState } from "react";
import { UploadState } from "../types/story";
import { apiClient } from "../api/api-client";

interface UploadPrepareResponse {
  presigned_url: string;
  file_url: string;
  upload_key?: string;
  final_upload_key?: string;  // API actually returns this field name
}

export function useFileUpload() {
  const [uploadState, setUploadState] = useState<UploadState>("idle");
  const [uploadProgress, setUploadProgress] = useState(0);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string>("");
  const [thumbnailUrl, setThumbnailUrl] = useState<string>("");
  const [uploadKey, setUploadKey] = useState<string>("");
  const [errorMessage, setErrorMessage] = useState<string>("");

  const validateFile = (file: File) => {
    const allowedTypes = [
      // Common image formats
      "image/jpeg",
      "image/jpg", 
      "image/png",
      "image/gif",
      "image/webp",
      "image/bmp",
      "image/tiff",
      "image/svg+xml",
      
      // HEIC/HEIF formats (iPhone photos)
      "image/heic",
      "image/heif",
      
      // Video formats
      "video/mp4",
      "video/mpeg",
      "video/quicktime", // .mov files
      "video/x-msvideo", // .avi files
      "video/webm",
      "video/ogg",
      "video/3gpp", // .3gp files
      "video/x-ms-wmv", // .wmv files
      "video/x-flv", // .flv files
      "video/x-matroska", // .mkv files
    ];
    
    const maxSize = 100 * 1024 * 1024; // Increased to 100MB for videos

    if (!allowedTypes.includes(file.type)) {
      setUploadState("error");
      return false;
    }
    if (file.size > maxSize) {
      setUploadState("error");
      return false;
    }
    return true;
  };

  const handleFileSelect = async (file: File) => {
    if (!validateFile(file)) return;
    
    setSelectedFile(file);
    setUploadState("uploading");
    setUploadProgress(0);

    try {
      // Step 1: Get presigned URL from /upload/prepare
      const prepareResponse = await apiClient.post<UploadPrepareResponse>("/upload/prepare", {
        filename: file.name,
        content_type: file.type,
        file_size: file.size
      });

      setUploadProgress(25);

      // Step 2: Upload file to S3 using presigned URL
      console.log("Uploading to S3:", prepareResponse.presigned_url);
      console.log("File details:", { name: file.name, type: file.type, size: file.size });
      
      const uploadResponse = await fetch(prepareResponse.presigned_url, {
        method: "PUT",
        body: file,
        headers: {
          "Content-Type": file.type,
        },
        mode: "cors", // Explicitly set CORS mode
      });

      console.log("S3 upload response:", {
        status: uploadResponse.status,
        statusText: uploadResponse.statusText,
        headers: Object.fromEntries(uploadResponse.headers.entries())
      });

      if (!uploadResponse.ok) {
        const errorText = await uploadResponse.text();
        console.error("S3 upload error response:", errorText);
        throw new Error(`S3 upload failed: ${uploadResponse.status} ${uploadResponse.statusText}. ${errorText}`);
      }

      setUploadProgress(75);

      // Store the file_url and upload_key for later use
      // Note: API returns 'final_upload_key' not 'upload_key'
      setThumbnailUrl(prepareResponse.file_url);
      
      // Ensure we have a valid upload key
      const uploadKey = prepareResponse.final_upload_key || prepareResponse.upload_key;
      if (!uploadKey) {
        throw new Error("No upload key received from prepare response");
      }
      setUploadKey(uploadKey);
      
      // Create preview URL for UI
      setPreviewUrl(URL.createObjectURL(file));
      
      setUploadProgress(100);
      setUploadState("success");

    } catch (error) {
      console.error("Upload failed:", error);
      
      // Provide more specific error messages
      let errorMessage = "Upload failed";
      if (error instanceof Error) {
        if (error.message.includes("CORS")) {
          errorMessage = "CORS error: The S3 bucket doesn't allow uploads from this domain. Please check S3 CORS configuration.";
        } else if (error.message.includes("403")) {
          errorMessage = "Access denied: The presigned URL may be invalid or expired.";
        } else if (error.message.includes("NetworkError")) {
          errorMessage = "Network error: Unable to connect to S3. Please check your internet connection.";
        } else {
          errorMessage = error.message;
        }
      }
      
      console.error("Detailed error:", errorMessage);
      setErrorMessage(errorMessage);
      setUploadState("error");
      setUploadProgress(0);
    }
  };

  const resetUpload = () => {
    setUploadState("idle");
    setSelectedFile(null);
    setUploadProgress(0);
    setThumbnailUrl("");
    setUploadKey("");
    setErrorMessage("");
    if (previewUrl) {
      URL.revokeObjectURL(previewUrl);
      setPreviewUrl("");
    }
  };

  return {
    uploadState,
    uploadProgress,
    selectedFile,
    previewUrl,
    thumbnailUrl,
    uploadKey,
    errorMessage,
    handleFileSelect,
    resetUpload,
  };
}
