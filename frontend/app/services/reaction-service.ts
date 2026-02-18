// import { API_ENDPOINTS } from "./api-config"

// export const reactionService = {
//   async addReaction(contentId: number, commentId: number, reactionType: string) {
//     const response = await fetch(API_ENDPOINTS.reactions.comment(contentId, commentId), {
//       method: "POST",
//       credentials: "include",
//       headers: { "Content-Type": "application/json" },
//       body: JSON.stringify({ reaction_type: reactionType }),
//     })

//     if (!response.ok) {
//       throw new Error("Failed to add reaction")
//     }

//     return response.json()
//   },
// }

