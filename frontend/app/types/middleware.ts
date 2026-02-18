// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { API_BASE_URL } from "@/lib/config";


/**
 * 1. We protect ALL routes by default, but we will
 *    manually allow /auth routes below (login, signup, etc.).
 */
export const config = {
  matcher: ['/:path*'], // Match all paths
}

export async function middleware(this: any, req: NextRequest) {
  const { pathname } = req.nextUrl
   


  // 2. ALLOW all routes under /auth (login, signup, forgot-password, etc.)
  //    so the user can actually log in or register.
  //    If you're using Next.js 13 "app/auth/...", you might do:
  //       if (pathname.startsWith('/auth')) { return NextResponse.next() }
  //    Adjust as needed if your auth path is different.
  if (pathname.startsWith('/auth')) {
    return NextResponse.next()
  }

  /**
   * 3. For all other routes, we check if the user is authenticated.
   *    We'll call our external backend's "is_authenticated" endpoint.
   *    - We pass along the "Cookie" from the request so the backend
   *      can see the user's session.
   */
  try {
    const verifyRes = await fetch(`${API_BASE_URL}/auth/is_authenticated`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        // Forward the incoming cookies to the backend
        Cookie: req.headers.get('cookie') || '',
      },
      // credentials: 'include' is typically for browser fetches;
      // here we manually forward the cookie header.
    })

    // 4. The backend always returns 200 OK, but the JSON will tell us success/failure.
    if (verifyRes.ok) {
      const data = await verifyRes.json()

      // The backend returns something like:
      //  {
      //     "status": "success",
      //     "message": "...",
      //     "data": {
      //        "authenticated": true,
      //        "user_id": 123,
      //        "username": "john_doe"
      //     }
      //  }
      if (data?.status === 'success' && data?.data?.authenticated) {
        // => The user is authenticated; let them proceed.
        return NextResponse.next()
      }
    }

    // If we reach here => Not authenticated
    // Redirect to login
    return NextResponse.redirect(new URL('/auth/login', req.url))
  } catch (err) {
    console.error('Error verifying session:', err)
    // If an error occurred, treat as not authenticated
    return NextResponse.redirect(new URL('/auth/login', req.url))
  }
}
