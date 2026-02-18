
import { Metadata } from "next";
import { notFound } from "next/navigation";
import SharePageClient from "./share-page-client";

interface SharePageProps {
  params: Promise<{
    shareId: string;
  }>;
}

// Generate dynamic metadata for OG tags
export async function generateMetadata({ params }: SharePageProps): Promise<Metadata> {
  const { shareId } = await params;
  
  try {
    // Fetch actual share content using direct fetch (server-side compatible)
    const baseUrl = 'https://api.staging.seattlepulse.net/api/v1';
    const apiUrl = `${baseUrl}/content/share/content-detail/${shareId}`;
    
    const response = await fetch(apiUrl, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
      cache: 'no-store', // Don't cache for dynamic content
    });

    if (response.ok) {
      const data = await response.json();
      
      if (data.success === "success" && data.data) {
        const content = data.data;
        const title = content.title || "Shared Post";
        const description = content.description || "Check out this post on Seattle Pulse";
        const image = content.image_url || "/default-profile.png";
        const location = content.location || "Seattle";
        const author = content.user.username;
        
        return {
          title: `${title} | Seattle Pulse`,
          description: description,
          openGraph: {
            title: title,
            description: description,
            images: [
              {
                url: image,
                width: 1200,
                height: 630,
                alt: title,
              },
            ],
            type: "article",
            siteName: "Seattle Pulse",
            locale: "en_US",
            url: `https://staging.seattlepulse.net/share/${shareId}`,
          },
          twitter: {
            card: "summary_large_image",
            title: title,
            description: description,
            images: [image],
          },
          other: {
            "og:url": `https://staging.seattlepulse.net/share/${shareId}`,
            "og:type": "article",
            "article:author": author,
            "article:section": location,
          },
        };
      }
    }
  } catch (error) {
    console.error("Error fetching shared content:", error);
    return {
      title: "Shared Post | Seattle Pulse",
      description: "Check out this shared post on Seattle Pulse",
    };
  }
  
  // Fallback metadata if content not found or error
  return {
    title: "Shared Post | Seattle Pulse",
    description: "Check out this shared post on Seattle Pulse",
    openGraph: {
      title: "Shared Post | Seattle Pulse",
      description: "Check out this shared post on Seattle Pulse",
      images: ["/default-profile.png"],
      type: "article",
      siteName: "Seattle Pulse",
      locale: "en_US",
      url: `https://staging.seattlepulse.net/share/${shareId}`,
    },
    twitter: {
      card: "summary_large_image",
      title: "Shared Post | Seattle Pulse",
      description: "Check out this shared post on Seattle Pulse",
      images: ["/default-profile.png"],
    },
    other: {
      "og:url": `https://staging.seattlepulse.net/share/${shareId}`,
      "og:type": "article",
    },
  };
}

export default async function SharePage({ params }: SharePageProps) {
  const { shareId } = await params;
  
  // Validate shareId exists
  if (!shareId) {
    notFound();
  }
  
  return <SharePageClient shareId={shareId} />;
}