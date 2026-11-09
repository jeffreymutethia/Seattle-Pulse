import type { Comment, ContentDetails, ExtendedPost } from "@/app/types/content";

/** Original place guides with simulated discussion and engagement. */
const stories = [
  {
    id: 9101, location: "Downtown, Seattle", username: "Seattle Pulse · Market Notes",
    title: "A slower way through Pike Place Market",
    body: "Start on the cobblestones under the Public Market Center clock, then follow the stairs down through the lower levels. From the marketfront, the view opens up toward Elliott Bay. It's a walk that works even when you leave the shopping list at home.",
    image: "pike-place", reactions: 28, source: "https://www.pikeplacemarket.org/",
    comments: ["The lower levels are my first stop when friends visit.", "I like ending the walk with a few minutes looking out at the water."],
  },
  {
    id: 9102, location: "Capitol Hill, Seattle", username: "Seattle Pulse · Hill Notes",
    title: "An hour at Cal Anderson Park",
    body: "Between Broadway and 11th, the park makes room for several versions of a Capitol Hill afternoon. Pause by the fountain, look for the big chess boards, or watch a game at the playfield before heading back toward Pike and Pine.",
    image: "cal-anderson", reactions: 18, source: "https://www.seattle.gov/parks/parks/cal-anderson-park",
    comments: ["The fountain side is my favorite place to read.", "I always forget the chess boards are there. Adding that to my next walk."],
  },
  {
    id: 9201, location: "Ballard, Seattle", username: "Seattle Pulse · Ballard Notes",
    title: "A walk through the Ballard Locks",
    body: "The best part of a visit is waiting long enough to see the water level change. Watch boats move through the lock, then head toward the fish ladder and the botanical garden for a quieter stretch of the walk.",
    image: "ballard-locks", reactions: 24, source: "https://www.myballard.com/ballard-locks-seattle/",
    comments: ["The view from the fish ladder is worth the extra few minutes.", "The garden is a nice detour after watching boats come through."],
  },
  {
    id: 9301, location: "U District, Seattle", username: "Seattle Pulse · Campus Notes",
    title: "Through the Quad, then back to the Ave",
    body: "In spring, the Quad's cherry trees draw crowds to campus. Start there, follow the brick paths past the surrounding halls, and leave time to wander back to University Way for something warm.",
    image: "uw-quad", reactions: 16, source: "https://www.washington.edu/cherryblossoms/",
    comments: ["I go early when I want room to stop and look up.", "It's a great excuse to take the long route back to the Ave."],
  },
  {
    id: 9401, location: "Wallingford, Seattle", username: "Seattle Pulse · Lake Union Notes",
    title: "The hill above Lake Union",
    body: "At Gas Works Park the old plant sits between the lawn and the water. From the hill you can watch the lake traffic cross the skyline, then pick up the Burke-Gilman Trail for a longer walk.",
    image: "gas-works", reactions: 21, source: "https://www.seattle.gov/parks/parks/gas-works-park",
    comments: ["Even on a cloudy day there's always something moving on the lake.", "The trail makes it easy to turn a quick stop into a longer afternoon."],
  },
  {
    id: 9501, location: "West Seattle, Seattle", username: "Seattle Pulse · Sound Notes",
    title: "The long way along Alki",
    body: "Walk the shoreline from the beach toward Duwamish Head and watch the view shift from the open Sound to the downtown skyline. Bring a layer, even when the sun makes the beach look warmer than it is.",
    image: "alki", reactions: 22, source: "https://www.seattle.gov/parks/parks/alki-beach-park",
    comments: ["The change in view around the bend is my favorite part.", "A layer is good advice. The breeze off the water sneaks up on you."],
  },
  {
    id: 9601, location: "Queen Anne, Seattle", username: "Seattle Pulse · Overlook Notes",
    title: "Waiting for the mountain at Kerry Park",
    body: "The Space Needle is easy to spot from the overlook. Mount Rainier takes more patience. On a clear day the mountain appears beyond the buildings, and the view gives you a reason to stay a little longer.",
    image: "seattle-skyline", reactions: 19, source: "https://www.seattle.gov/parks/parks/kerry-park",
    comments: ["I check the clouds before walking up the hill.", "On clear evenings the mountain looks much closer than it is."],
  },
  {
    id: 9701, location: "Seward Park, Seattle", username: "Seattle Pulse · South End Notes",
    title: "The shoreline loop at Seward Park",
    body: "Follow the water around Bailey Peninsula for a long view across Lake Washington. When you want a change of pace, head inland toward the trees before looping back to the shore.",
    image: "seward-park", reactions: 20, source: "https://sewardpark.audubon.org/",
    comments: ["The wooded paths are my favorite part of the park.", "I like starting by the water and finishing under the trees."],
  },
] as const;

export const demoNeighborhoods = [
  { name: "All Seattle", value: "Seattle" },
  ...Array.from(new Set(stories.map((story) => story.location))).sort()
    .map((location) => ({ name: location, value: location })),
];

const createdAt = "2026-01-01T12:00:00Z";
const avatar = "/demo/neighbor.svg";

export const demoPosts: ExtendedPost[] = stories.map((story) => ({
  id: story.id,
  body: story.body,
  title: story.title,
  location: story.location,
  thumbnail: `/demo/${story.image}.webp`,
  comments_count: story.comments.length,
  reactions_count: story.reactions,
  totalReactions: story.reactions,
  score: "0",
  time_since_post: "Neighborhood guide",
  created_at: createdAt,
  updated_at: createdAt,
  user: { id: story.id, username: story.username, profile_picture_url: avatar },
  user_has_reacted: false,
  user_reaction_type: "like",
  userReaction: null,
  has_user_reposted: false,
  top_reactions: ["love", "like"],
}));

export function fetchDemoPosts(page: number, location?: string): ExtendedPost[] {
  if (page !== 1) return [];
  return demoPosts.filter((post) => !location || location === "Seattle" || post.location === location)
    .map((post) => ({ ...post, user: { ...post.user }, top_reactions: [...(post.top_reactions ?? [])] }));
}

export function fetchDemoContent(contentId: string | number): ContentDetails {
  const story = stories.find((item) => item.id === Number(contentId));
  const post = demoPosts.find((item) => item.id === Number(contentId));
  if (!story || !post) throw new Error("This story is outside the demo edition.");
  const comments: Comment[] = story.comments.map((content, index) => ({
    id: post.id * 10 + index,
    content,
    user_id: index + 1,
    created_at: createdAt,
    user_reaction: null,
    reactions: { user_reaction: "" },
    total_reactions: 0,
    user: { id: index + 1, username: index === 0 ? "Sam · demo neighbor" : "Riley · demo neighbor", profile_picture_url: avatar },
    parent_id: null,
    replies_count: 0,
  }));
  return {
    id: post.id,
    unique_id: post.id,
    title: post.title,
    description: post.body,
    image_url: post.thumbnail,
    location: post.location,
    source_url: story.source,
    created_at: createdAt,
    user: { ...post.user, profile_picture_url: avatar },
    user_reaction: null,
    total_reactions: post.reactions_count,
    comments,
  };
}
