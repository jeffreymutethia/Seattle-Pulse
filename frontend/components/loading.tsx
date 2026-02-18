import { Skeleton } from "@/components/ui/skeleton"

export default function Loading() {
  return (
    <div className="w-full mx-auto p-4">
      <div className="flex items-center justify-between mb-6">
        <Skeleton className="h-8 w-32" />
        <Skeleton className="w-[400px] h-10 rounded-full" />
        <div className="flex gap-4">
          <Skeleton className="h-10 w-10 rounded-full" />
          <Skeleton className="h-10 w-10 rounded-full" />
        </div>
      </div>

      <Skeleton className="h-12 w-48 mx-auto mb-6" />

      <div className="space-y-6 max-w-xl mx-auto">
        {[...Array(3)].map((_, i) => (
          <div key={i} className="rounded-lg border bg-card shadow-sm p-4 space-y-4">
            <div className="flex items-center gap-4">
              <Skeleton className="h-10 w-10 rounded-full" />
              <div className="space-y-2">
                <Skeleton className="h-4 w-24" />
                <Skeleton className="h-4 w-16" />
              </div>
            </div>
            <Skeleton className="w-full aspect-video rounded-md" />
            <Skeleton className="h-4 w-3/4" />
            <div className="flex gap-4">
              <Skeleton className="h-8 w-16" />
              <Skeleton className="h-8 w-16" />
              <Skeleton className="h-8 w-16 ml-auto" />
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

