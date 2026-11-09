import type { NextConfig } from "next";

const config: NextConfig = {
  output: "export",
  trailingSlash: true,
  images: { unoptimized: true },
  env: { NEXT_PUBLIC_DEMO_MODE: "true" },
  experimental: { externalDir: true },
};

export default config;
