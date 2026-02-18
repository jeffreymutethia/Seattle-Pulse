"use client";

import React from "react";
import { usePathname } from "next/navigation";
import { useAuth } from "./context/auth-context";
import dynamic from "next/dynamic";
// import { MobileHeader } from "@/components/mobile-header";
import { MobileBottomNav } from "@/components/mobile-bottom-nav";

const Sidebar = dynamic(() => import("@/components/sidebar").then(m => m.Sidebar), { ssr: false });
const GuestSidebar = dynamic(() => import("@/components/guest-sidebar").then(m => m.GuestSidebar), { ssr: false });

function ClientLayout({
  children,
  hasSession,
}: {
  children: React.ReactNode;
  hasSession: boolean;
}) {
  const { isAuthenticated, isLoading } = useAuth();
  const pathname = usePathname();

  const showAuthenticatedUI = isLoading ? hasSession : isAuthenticated;

  const isAuthPage = pathname.startsWith("/auth");
  const isPrivacyPage = pathname.startsWith("/privacy");
  const isTermsPage = pathname.startsWith("/terms");
  const isOnboardingPage = pathname.startsWith("/onboarding");

  const [sidebarKey, setSidebarKey] = React.useState(0);

  React.useEffect(() => {
    const checkUser = () => {
      const user = sessionStorage.getItem("user");
      if (user) {
        setSidebarKey((prev) => prev + 1);
      }
    };

    checkUser();

    window.addEventListener("user-updated", checkUser);

    return () => {
      window.removeEventListener("user-updated", checkUser);
    };
  }, []);

  return (
    <div className="flex h-screen bg-[#FAFBFF]">
      {/* Mobile Header - persistent across all pages except auth */}
      {/* {!isAuthPage && !isOnboardingPage && !isPrivacyPage && !isTermsPage && (
        <MobileHeader />
      )} */}
      
      {/* Reserve sidebar space and mount dynamic sidebar inside a fixed-width wrapper to avoid layout shift */}
      {!isAuthPage && !isOnboardingPage && !isPrivacyPage && !isTermsPage && (
        <div className="hidden md:block w-[250px] shrink-0 relative">
          {showAuthenticatedUI ? (
            <div className="absolute inset-0">
              <Sidebar key={sidebarKey} />
            </div>
          ) : (
            <div className="absolute inset-0">
              <GuestSidebar />
            </div>
          )}
        </div>
      )}
      <main id="app-main" className="flex-1 overflow-auto  pb-20 md:pt-0 md:pb-0">{children}</main>
      {/* Mobile Bottom Navigation */}
      {!isAuthPage && !isOnboardingPage && !isPrivacyPage && !isTermsPage && (
        <MobileBottomNav />
      )}
    </div>
  );
}

export default ClientLayout;
