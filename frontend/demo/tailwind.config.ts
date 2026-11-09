import config from "../tailwind.config";

export default {
  ...config,
  content: ["../components/**/*.{ts,tsx}", "../app/**/*.{ts,tsx}", "./app/**/*.{ts,tsx}"],
};
