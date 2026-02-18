"use client";

import * as React from "react";
import { Search, History, X, Dot } from "lucide-react";
import debounce from "lodash/debounce";
import { useRouter } from "next/navigation";
import { apiClient } from "@/app/api/api-client";
import { trackEvent } from "@/lib/mixpanel";
import Image from "next/image";

interface User {
  id: number;
  username: string;
  email: string;
  total_followers: number;
  first_name: string;
  last_name: string;
  location: string;
  profile_picture_url: string;
}

interface SearchResponse {
  success: string;
  message: string;
  data: User[];
  query: string;
  pagination: {
    page: number;
    per_page: number;
    total_pages: number;
    total_items: number;
    has_next: boolean;
    has_prev: boolean;
  };
}

interface SearchHistory {
  query: string;
  username: string;
  timestamp: number;
}

export default function SearchWithResults() {
  const router = useRouter();
  const [query, setQuery] = React.useState("");
  const [isOpen, setIsOpen] = React.useState(false);
  const [results, setResults] = React.useState<User[]>([]);
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [page, setPage] = React.useState(1);
  const [hasMore, setHasMore] = React.useState(true);
  const [searchHistory, setSearchHistory] = React.useState<SearchHistory[]>([]);
  const searchRef = React.useRef<HTMLDivElement>(null);
  const inputRef = React.useRef<HTMLInputElement>(null);
  const resultsRef = React.useRef<HTMLDivElement>(null);

  React.useEffect(() => {
    const history = localStorage.getItem("searchHistory");
    if (history) {
      setSearchHistory(JSON.parse(history));
    }
  }, []);

  const getDropdownPosition = () => {
    if (inputRef.current) {
      const rect = inputRef.current.getBoundingClientRect();
      return {
        top: `${rect.bottom + 8}px`,
        left: `${rect.left}px`,
        width: `${rect.width}px`,
      };
    }
    return {};
  };

  const addToHistory = (username: string) => {
    const newHistory = [
      {
        query,
        username,
        timestamp: Date.now(),
      },
      ...searchHistory,
    ].slice(0, 10);

    setSearchHistory(newHistory);
    localStorage.setItem("searchHistory", JSON.stringify(newHistory));
  };

  // Clear search history
  const clearHistory = () => {
    setSearchHistory([]);
    localStorage.removeItem("searchHistory");
  };

  const removeHistoryItem = (timestamp: number) => {
    const newHistory = searchHistory.filter(
      (item) => item.timestamp !== timestamp
    );
    setSearchHistory(newHistory);
    localStorage.setItem("searchHistory", JSON.stringify(newHistory));
  };

  const fetchUsers = React.useCallback(
    async (searchQuery: string, pageNum: number) => {
      try {
        setLoading(true);
        setError(null);

        const endpoint = `/users/search?query=${searchQuery}&page=${pageNum}&per_page=10`;
        
        try {
          const data = await apiClient.get<SearchResponse>(endpoint);

          if (data.success === "success") {
            setResults(pageNum === 1 ? data.data : [...results, ...data.data]);
            setHasMore(data.pagination?.has_next ?? false);
            setError(null);
            
            // Track search event (only on first page to avoid duplicate events)
            if (pageNum === 1 && searchQuery.trim()) {
              trackEvent("search_performed", {
                query: searchQuery,
                results_count: data.data?.length || 0,
              });
            }
          } else {
            if (pageNum === 1) {
              setResults([]);
            }
            setHasMore(false);
            setError(data.message);
          }
        } catch (error: unknown) {
          const errorMessage = error instanceof Error ? error.message : String(error);
          if (errorMessage?.includes("404")) {
            setHasMore(false);
            if (pageNum === 1) {
              setResults([]);
              setError("No results found");
            }
            return;
          }
          throw error;
        }
      } catch (error: unknown) {
        if (pageNum === 1) {
          setResults([]);
        }
        setHasMore(false);
        setError("Failed to fetch results");
        console.error("Search error:", error);
      } finally {
        setLoading(false);
      }
    },
    [results]
  );

  // Debounced search function
  const debouncedSearch = React.useMemo(
    () =>
      debounce((value: string) => {
        setPage(1);
        setHasMore(true);
        if (value.trim()) {
          fetchUsers(value, 1);
        } else {
          setResults([]);
        }
      }, 300),
    [fetchUsers]
  );

  // Handle search input
  const handleSearch = (value: string) => {
    setQuery(value);
    setIsOpen(true);
    debouncedSearch(value);
  };

  // Handle user selection
  const handleUserSelect = (user: User) => {
    addToHistory(user.username);
    router.push(`/profile/${user.username}`);
    setIsOpen(false);
  };

  // Handle scroll for infinite loading
  const handleScroll = (e: React.UIEvent<HTMLDivElement>) => {
    const bottom =
      Math.abs(
        e.currentTarget.scrollHeight -
          e.currentTarget.scrollTop -
          e.currentTarget.clientHeight
      ) < 1;

    if (bottom && !loading && hasMore && query) {
      setPage((prev) => prev + 1);
      fetchUsers(query, page + 1);
    }
  };

  // Close dropdown when clicking outside
  React.useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        searchRef.current &&
        !searchRef.current.contains(event.target as Node)
      ) {
        setIsOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  return (
    <div ref={searchRef} className="relative z-50">
    <div className="relative">
  <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground pointer-events-none" />
  <input
    ref={inputRef}
    type="search"
    placeholder="Search"
    value={query}
    onChange={(e) => handleSearch(e.target.value)}
    onFocus={() => setIsOpen(true)}
    className="w-full md:w-[530px] pl-9 rounded-full border border-[#ABB0B9] bg-background px-3 py-2 transition-all duration-200 outline-none focus:border-gray-400 focus:ring-1 focus:ring-gray-400"
  />
</div>


      {/* Results Dropdown - Fixed Position */}
      {isOpen && (
        <div
          className="fixed bg-white rounded-2xl border border-gray-200 shadow-lg animate-in fade-in slide-in-from-top-2 duration-200 z-50"
          style={getDropdownPosition()}
        >
          <div className="p-2">
            <div className="flex items-center justify-between px-2 py-1.5 text-sm text-gray-500">
              <span>{query ? "Results" : "Recent Searches"}</span>
              {(query ? results.length > 0 : searchHistory.length > 0) && (
                <button
                  onClick={() =>
                    query ? (setResults([]), setQuery("")) : clearHistory()
                  }
                  className="text-blue-500 hover:underline"
                >
                  Clear All
                </button>
              )}
            </div>

            <div
              ref={resultsRef}
              onScroll={handleScroll}
              className="mt-2 max-h-[400px] overflow-y-auto overflow-x-hidden"
            >
              {error && !results.length ? (
                <div className="px-4 py-3 text-sm text-red-500">{error}</div>
              ) : results.length > 0 ? (
                <ul className="space-y-1">
                  {results.map((user) => (
                    <li key={user.id}>
                      <button
                        onClick={() => handleUserSelect(user)}
                        className="flex w-full items-center gap-3 rounded-md px-2 py-1.5 text-sm hover:bg-gray-100"
                      >
                        <Image
                          src={
                            user.profile_picture_url ||
                            "/placeholder.svg?height=32&width=32"
                          }
                          alt=""
                          className="h-14 w-14 rounded-full border-2 border-[#E2E8F0] object-cover"
                          width={56}
                          height={56}
                        />
                        <div className="flex flex-col items-start">
                          <span className="font-medium text-base">
                            {user.first_name} {user.last_name}
                          </span>
                          <div className="flex">
                            <p className="font-normal text-sm text-[#5D6778]">
                              {" "}
                              {user.location ?? "Seattle"}
                            </p>

                            <Dot className="h-5 w-5 text-[#5D6778]" />

                            <span className="font-normal text-sm text-[#5D6778]">
                              {user.total_followers.toString() + " followers"}
                            </span>
                          </div>
                        </div>
                      </button>
                    </li>
                  ))}
                  {loading && (
                    <li className="flex justify-center py-2">
                      <div className="h-4 w-4 animate-spin rounded-full border-2 border-gray-300 border-t-gray-600"></div>
                    </li>
                  )}
                  {!hasMore && results.length > 0 && (
                    <li className="px-4 py-2 text-sm text-gray-500 text-center">
                      No more results
                    </li>
                  )}
                </ul>
              ) : !query && searchHistory.length > 0 ? (
                <ul className="space-y-1">
                  {searchHistory.map((item) => (
                    <li key={item.timestamp}>
                      <div className="flex items-center justify-between px-2 py-1.5 text-sm hover:bg-gray-100 rounded-md">
                        <button
                          onClick={() => {
                            setQuery(item.query);
                            handleSearch(item.query);
                          }}
                          className="flex items-center gap-2"
                        >
                          <History className="h-4 w-4 text-gray-500" />
                          <span>{item.username}</span>
                        </button>
                        <button
                          onClick={() => removeHistoryItem(item.timestamp)}
                          className="text-gray-400 hover:text-gray-600"
                        >
                          <X className="h-4 w-4" />
                        </button>
                      </div>
                    </li>
                  ))}
                </ul>
              ) : (
                <div className="px-4 py-3 text-sm text-gray-500">
                  {loading ? (
                    <div className="flex justify-center">
                      <div className="h-4 w-4 animate-spin rounded-full border-2 border-gray-300 border-t-gray-600"></div>
                    </div>
                  ) : query ? (
                    "No results found"
                  ) : (
                    "No recent searches"
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
