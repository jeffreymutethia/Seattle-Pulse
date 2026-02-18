"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useShare } from "../../hooks/use-share";
import Loading from "@/components/loading";

interface SharePageClientProps {
  shareId: string;
}

export default function SharePageClient({ shareId }: SharePageClientProps) {
  const router = useRouter();
  const { fetchSharedContent } = useShare();

  useEffect(() => {
    // Fetch share content and then redirect
    const handleShare = async () => {
      if (shareId) {
        try {
          await fetchSharedContent(shareId);
          // Redirect to main page with shareId parameter
          router.replace(`/?shareId=${shareId}`);
        } catch (error) {
          console.error("Error fetching share content:", error);
          // Still redirect even if there's an error
          router.replace(`/?shareId=${shareId}`);
        }
      }
    };

    handleShare();
  }, [shareId, router, fetchSharedContent]);

  // Show loading while fetching and redirecting
  return (
    <div className="min-h-screen flex items-center justify-center">
      <Loading />
    </div>
  );
}