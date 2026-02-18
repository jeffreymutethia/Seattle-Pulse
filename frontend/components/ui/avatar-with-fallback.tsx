import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import { Person } from "@/app/types/user";

interface AvatarWithFallbackProps {
  src?: string;
  alt: string;
  fallbackText?: string;
  className?: string;
  size?: "sm" | "md" | "lg" | "xl";
  person?: Person; // Optional person object for automatic fallback generation
}

const getInitials = (person: Person): string => {
  const first = (person.first_name?.[0] || "").toUpperCase();
  const last = (person.last_name?.[0] || "").toUpperCase();
  if (first || last) return `${first}${last}`;
  const user = (person.username?.[0] || "").toUpperCase();
  return user || "?";
};

const getSizeClasses = (size: "sm" | "md" | "lg" | "xl") => {
  switch (size) {
    case "sm":
      return "h-8 w-8 text-xs";
    case "md":
      return "h-10 w-10 text-sm";
    case "lg":
      return "h-16 w-16 text-lg";
    case "xl":
      return "h-20 w-20 text-xl";
    default:
      return "h-10 w-10 text-sm";
  }
};

export function AvatarWithFallback({
  src,
  alt,
  fallbackText,
  className = "",
  size = "md",
  person,
}: AvatarWithFallbackProps) {
  const sizeClasses = getSizeClasses(size);
  const fallback = fallbackText || (person ? getInitials(person) : "?");

  return (
    <Avatar className={`${sizeClasses} ${className}`}>
      <AvatarImage
        src={src || undefined}
        alt={alt}
        className="object-cover"
      />
      <AvatarFallback className="bg-gray-300 text-white font-bold">
        {fallback}
      </AvatarFallback>
    </Avatar>
  );
}
