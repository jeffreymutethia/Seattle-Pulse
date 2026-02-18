import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  console.log("Request path:", request.nextUrl.pathname);

  const { pathname, origin } = request.nextUrl;

  const publicPaths = [
    "/",
    "/onboarding",
    "/auth/login",
    "/auth/signup",
    "/privacy",
    "/terms",
    "/auth/reset-password",
    "/auth/forgot-password",
    "/auth/verify-otp",
    "/share"
  ];

  if (request.method === "OPTIONS") {
    const response = NextResponse.next();
    response.headers.set(
      "Access-Control-Allow-Origin",
      "http://localhost:3000"
    );
    response.headers.set("Access-Control-Allow-Credentials", "true");
    response.headers.set(
      "Access-Control-Allow-Methods",
      "GET, POST, PUT, DELETE, OPTIONS"
    );
    response.headers.set(
      "Access-Control-Allow-Headers",
      "Content-Type, Authorization"
    );
    return response;
  }

  const sessionCookie = request.cookies.get("session");
  console.log("Session cookie present:", !!sessionCookie);
  console.log("Current pathname:", pathname);

  const isPublicPath = publicPaths.some(
    (path) => pathname === path || pathname.startsWith("/auth/")
  );
  console.log("Is public path:", isPublicPath);

  if (!sessionCookie && !isPublicPath) {
    console.log("No session found, redirecting to login");
    const loginUrl = new URL("/", origin);
    loginUrl.searchParams.set("redirect", pathname);
    return NextResponse.redirect(loginUrl);
  }

  const response = NextResponse.next();
  if (sessionCookie) {
    console.log("Setting x-has-session header to true");
    response.headers.set("x-has-session", "true");
  } else {
    console.log("Setting x-has-session header to false");
    response.headers.set("x-has-session", "false");
  }

  return response;
}

export const config = {
  matcher: [
    "/((?!auth/login|auth/signup|auth/reset-password|components/ui|auth/forgot-password|share|auth/verify-otp|_next/image|_next|favicon.ico|robots.txt|sitemap.xml|manifest.json|public|.*\\.png|.*\\.jpg|.*\\.jpeg|.*\\.gif|.*\\.svg|.*\\.ico).*)",
  ],
};