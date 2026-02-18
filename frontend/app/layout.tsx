import localFont from "next/font/local";

import "./globals.css";
import type React from "react";
import { headers } from "next/headers";
import { AuthProvider } from "./context/auth-context";
import ClientLayout from "./client-layout";
import { NotificationProvider } from "./context/notification-context";
import { MixpanelProvider } from "@/components/mixpanel-provider";

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
  description: "Location-based social media",
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
  const headersList = headers();
  const hasSession = (await headersList).get("x-has-session") === "true";

  return (
    <html lang="en">
      <head>
        {/* Hint font loading for better mobile FCP */}
        <link rel="preload" as="font" href="/fonts/Poppins-Regular.ttf" type="font/ttf" crossOrigin="anonymous" />
        <link rel="preconnect" href="https://seattlepulse.net" />
        <link rel="dns-prefetch" href="https://seattlepulse.net" />
        <link rel="preconnect" href="https://api.staging.seattlepulse.net" />
        <link rel="dns-prefetch" href="https://api.staging.seattlepulse.net" />
      </head>
      <body className={poppins.className}>
        <AuthProvider>
          <MixpanelProvider>
            <NotificationProvider>
              <ClientLayout hasSession={hasSession}>{children}</ClientLayout>
            </NotificationProvider>
          </MixpanelProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
