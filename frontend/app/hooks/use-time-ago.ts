export function useTimeAgo() {
  const timeAgo = (dateString: string): string => {
    const now = new Date();
    const createdAt = new Date(dateString);
    
    // Check if the date is valid
    if (isNaN(createdAt.getTime())) {
      return "Invalid date";
    }
    
    const difference = now.getTime() - createdAt.getTime();
    
    // Handle future dates or invalid differences
    if (difference < 0) {
      return "Just now";
    }
    
    const seconds = Math.floor(difference / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) {
      return `${days} day${days > 1 ? "s" : ""} ago`;
    } else if (hours > 0) {
      return `${hours} hour${hours > 1 ? "s" : ""} ago`;
    } else if (minutes > 0) {
      return `${minutes} minute${minutes > 1 ? "s" : ""} ago`;
    } else if (seconds > 0) {
      return `${seconds} second${seconds > 1 ? "s" : ""} ago`;
    } else {
      return "Just now";
    }
  };

  return { timeAgo };
}
