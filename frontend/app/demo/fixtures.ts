import type { Comment, ContentDetails, ExtendedPost } from "@/app/types/content";

/** Original fictional examples, never a representation of current Seattle news. */
const stories = [
  {
    id: 9101, location: "Capitol Hill, Seattle", username: "Maya · demo neighbor",
    title: "A little more room to linger on Pike Street",
    body: "What if a pocket of Pike Street became a place to pause? Neighbors imagine planters, a few shared benches, and space for a conversation on the walk home.",
    image: "pike-street", reactions: 18,
    comments: ["A bench near the corner would be a lovely place to pause on the walk home.", "I would love to help look after the planters. Who else is in?"],
  },
  {
    id: 9102, location: "Capitol Hill, Seattle", username: "Theo · demo neighbor",
    title: "Trading books, one front porch at a time",
    body: "A fictional neighborhood book swap brings spare paperbacks out of the house and into new hands. Which book would you leave for the next person?",
    image: "book-swap", reactions: 12,
    comments: ["I would bring a favorite collection of short stories.", "A children's shelf would make this welcoming for families, too."],
  },
  {
    id: 9201, location: "Ballard, Seattle", username: "Jun · demo neighbor",
    title: "A neighborhood table at the Ballard market",
    body: "Imagine a long communal table beside the market stalls: somewhere to share a pastry, ask a grower a question, and meet a neighbor you usually walk past.",
    image: "ballard-market", reactions: 24,
    comments: ["A shared table would make it easier to meet the people behind the stalls.", "Could we leave space for wheelchairs and strollers at both ends?"],
  },
  {
    id: 9202, location: "Ballard, Seattle", username: "Alex · demo neighbor",
    title: "An evening walk along the working waterfront",
    body: "This fictional photo walk follows the shapes and colors of Ballard's waterfront. Bring a camera, a sketchbook, or just your curiosity about the neighborhood.",
    image: "waterfront", reactions: 16,
    comments: ["The reflections would make a wonderful sketching prompt.", "I would enjoy hearing stories about the boats along the way."],
  },
];

const createdAt = "2026-01-01T12:00:00Z";
const avatar = "/demo/neighbor.svg";

export const demoPosts: ExtendedPost[] = stories.map((story) => ({
  id: story.id,
  body: story.body,
  title: story.title,
  location: story.location,
  thumbnail: `/demo/${story.image}.svg`,
  comments_count: story.comments.length,
  reactions_count: story.reactions,
  totalReactions: story.reactions,
  score: "0",
  time_since_post: "Fictional story",
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
  if (!story || !post) throw new Error("This story is not part of the fictional walkthrough.");
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
    source_url: "",
    created_at: createdAt,
    user: { ...post.user, profile_picture_url: avatar },
    user_reaction: null,
    total_reactions: post.reactions_count,
    comments,
  };
}
