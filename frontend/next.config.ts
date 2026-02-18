import {withSentryConfig} from "@sentry/nextjs";
import type { NextConfig } from "next";

// Get git SHA for release tracking (set by build scripts or CI/CD)
// This will be available as process.env.NEXT_PUBLIC_GIT_SHA at runtime
const gitSha = process.env.NEXT_PUBLIC_GIT_SHA || process.env.NEXT_PUBLIC_RELEASE || "unknown";

const nextConfig: NextConfig = {
  env: {
    NEXT_PUBLIC_GIT_SHA: gitSha,
    NEXT_PUBLIC_RELEASE: gitSha,
  },
  reactStrictMode: true,
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "seattlepulse-staging-user-post-images.s3.us-west-2.amazonaws.com",
      },
      {
        protocol: "https",
        hostname: "seattlepulse-user-post-images.s3.us-west-2.amazonaws.com",
      },
      {
        protocol: "https",
        hostname: "**",
      },
      {
        protocol: "http",
        hostname: "**",
      },
    ],
    // Optimized settings for S3 images
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
    formats: ['image/webp', 'image/avif'],
    minimumCacheTTL: 300, // 5 minutes cache
    dangerouslyAllowSVG: true,
    contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;",
    // Add timeout settings
    loader: 'default',
    domains: [
      'seattlepulse-staging-user-post-images.s3.us-west-2.amazonaws.com',
      'seattlepulse-user-post-images.s3.us-west-2.amazonaws.com'
    ],
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
  // ✅ Add this headers function here
  // async headers() {
  //   return [
  //     {
  //       source: '/:path*',
  //       headers: [
  //         {
  //           key: 'Content-Security-Policy',
  //           value: 'upgrade-insecure-requests',
  //         },
  //       ],
  //     },
  //   ];
  // },
};

export default withSentryConfig(nextConfig, {
  // For all available options, see:
  // https://www.npmjs.com/package/@sentry/webpack-plugin#options

  org: "seattle-pulse",

  project: "javascript-nextjs",

  // Only print logs for uploading source maps in CI
  silent: !process.env.CI,

  // For all available options, see:
  // https://docs.sentry.io/platforms/javascript/guides/nextjs/manual-setup/

  // Upload a larger set of source maps for prettier stack traces (increases build time)
  widenClientFileUpload: true,

  // Uncomment to route browser requests to Sentry through a Next.js rewrite to circumvent ad-blockers.
  // This can increase your server load as well as your hosting bill.
  // Note: Check that the configured route will not match with your Next.js middleware, otherwise reporting of client-
  // side errors will fail.
  // tunnelRoute: "/monitoring",

  // Automatically tree-shake Sentry logger statements to reduce bundle size
  disableLogger: true,

  // Enables automatic instrumentation of Vercel Cron Monitors. (Does not yet work with App Router route handlers.)
  // See the following for more information:
  // https://docs.sentry.io/product/crons/
  // https://vercel.com/docs/cron-jobs
  automaticVercelMonitors: true,
});