/** Build-time boundary: Docker and normal Next builds keep using the Flask API. */
export const IS_DEMO = process.env.NEXT_PUBLIC_DEMO_MODE === "true";
