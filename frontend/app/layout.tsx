import localFont from "next/font/local";

import "./globals.css";
import type React from "react";
import { headers } from "next/headers";
import { AuthProvider } from "./context/auth-context";
import ClientLayout from "./client-layout";
import { NotificationProvider } from "./context/notification-context";
import { MixpanelProvider } from "@/components/mixpanel-provider";
import { IS_DEMO } from "@/lib/demo";
import { DemoSessionBoundary } from "./demo/demo-session";

const poppins = localFont({
  src: [
    {
      path: "../public/fonts/Poppins-Thin.ttf",
      weight: "100",
      style: "normal",
    },
    {
      path: "../public/fonts/Poppins-ExtraLight.ttf",
      weight: "200",
      style: "normal",
    },
    {
      path: "../public/fonts/Poppins-Light.ttf",
      weight: "300",
      style: "normal",
    },
    {
      path: "../public/fonts/Poppins-Regular.ttf",
      weight: "400",
      style: "normal",
    },
    {
      path: "../public/fonts/Poppins-Medium.ttf",
      weight: "500",
      style: "normal",
    },
    {
      path: "../public/fonts/Poppins-SemiBold.ttf",
      weight: "600",
      style: "normal",
    },
    {
      path: "../public/fonts/Poppins-Bold.ttf",
      weight: "700",
      style: "normal",
    },
    {
      path: "../public/fonts/Poppins-ExtraBold.ttf",
      weight: "800",
      style: "normal",
    },
    {
      path: "../public/fonts/Poppins-Black.ttf",
      weight: "900",
      style: "normal",
    },
  ],
  display: "swap",
});

export const metadata = {
  title: "Seattle Pulse",
  description: "Jeffrey Mutethia’s neighborhood discovery and conversation platform. Explore the Seattle Pulse portfolio demo.",
  openGraph: {
    title: "Seattle Pulse",
    description: "Location-based social media",
    type: "website",
    siteName: "Seattle Pulse",
  },
};

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const hasSession = IS_DEMO ? false : (await headers()).get("x-has-session") === "true";
  const isProduction = process.env.NODE_ENV === "production" && !IS_DEMO;

  return (
    <html lang="en">
      <head>
        {/* Hint font loading for better mobile FCP */}
        <link rel="preload" as="font" href="/fonts/Poppins-Regular.ttf" type="font/ttf" crossOrigin="anonymous" />
        {isProduction ? (
          <>
            <link rel="preconnect" href="https://seattlepulse.net" />
            <link rel="dns-prefetch" href="https://seattlepulse.net" />
            <link rel="preconnect" href="https://api.seattlepulse.net" />
            <link rel="dns-prefetch" href="https://api.seattlepulse.net" />
          </>
        ) : null}
      </head>
      <body className={poppins.className}>
        <DemoSessionBoundary><AuthProvider>
          <MixpanelProvider>
            <NotificationProvider>
              <ClientLayout hasSession={hasSession}>{children}</ClientLayout>
            </NotificationProvider>
          </MixpanelProvider>
        </AuthProvider></DemoSessionBoundary>
      </body>
    </html>
  );
}
