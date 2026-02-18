import { Skeleton } from "@/components/ui/skeleton"
import { Search } from "lucide-react"

export function ProfileHeaderSkeleton() {
  return (
    <div className="space-y-4 mb-8">
      <div className="flex justify-center gap-8 items-start">
        {/* Avatar Skeleton */}
        <Skeleton className="w-[198px] h-[198px] rounded-full" />

        {/* Main Info Skeleton */}
        <div className="space-y-3 w-full max-w-[400px]">
          <div className="flex gap-2">
            <Skeleton className="h-7 w-32" /> {/* Name */}
            <Skeleton className="h-6 w-24" /> {/* Username */}
          </div>

          {/* Buttons Skeleton */}
          <div className="flex gap-2">
            <Skeleton className="h-14 w-32" /> 
            <Skeleton className="h-14 w-32" /> 
            <Skeleton className="h-14 w-14" /> 
          </div>

          {/* Stats Skeleton */}
          <div className="flex gap-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="flex gap-1">
                <Skeleton className="h-6 w-8" />
                <Skeleton className="h-6 w-16" />
              </div>
            ))}
          </div>

          {/* Bio Skeleton */}
          <div className="space-y-2">
            <Skeleton className="h-4 w-full" />
            <Skeleton className="h-4 w-3/4" />
          </div>
        </div>
      </div>
    </div>
  )
}

export function ProfileTabsSkeleton() {
  return (
    <div className="mt-6">
      <div className="w-full flex justify-center border-t bg-transparent space-x-6">
        {[1, 2, 3].map((i) => (
          <Skeleton key={i} className="h-10 w-24" />
        ))}
      </div>
      <div className="mt-4">
        <PhotoGridSkeleton />
      </div>
    </div>
  )
}

export function PhotoGridSkeleton() {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2 p-4">
      {[1, 2, 3, 4, 5, 6].map((i) => (
        <Skeleton key={i} className="aspect-square w-full" />
      ))}
    </div>
  )
}

export function HeaderSkeleton() {
  return (
    <div className="flex items-center justify-between mb-16">
      <div>
        <Skeleton className="h-8 w-24" />
      </div>
      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Skeleton className="w-[400px] h-10 rounded-full" />
      </div>
      <div className="flex gap-4">
        <Skeleton className="h-10 w-10 rounded-lg" />
        <Skeleton className="h-10 w-10 rounded-lg" />
      </div>
    </div>
  )
}

