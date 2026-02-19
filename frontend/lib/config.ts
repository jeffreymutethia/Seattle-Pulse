const getEnvironment = (): 'local' | 'staging' | 'production' => {
  if (process.env.NEXT_PUBLIC_APP_ENV === 'production') return 'production';
  if (process.env.NEXT_PUBLIC_APP_ENV === 'staging') return 'staging';
  if (process.env.NEXT_PUBLIC_APP_ENV === 'local') return 'local';
  
  if (process.env.NODE_ENV === 'production') {
    return process.env.NEXT_PUBLIC_APP_ENV === 'staging' ? 'staging' : 'production';
  }
  
  return 'local';
};

const appEnv = getEnvironment();
const isServer = typeof window === "undefined";

// Environment-based API URLs
const STAGING_API_URL = 'https://api.staging.seattlepulse.net/api/v1';
const STAGING_API_URL_NOTIFICATION = 'https://api.staging.seattlepulse.net';
const PRODUCTION_API_URL = 'https://api.seattlepulse.net/api/v1';
const PRODUCTION_API_URL_NOTIFICATION = 'https://api.seattlepulse.net';
const LOCAL_API_URL = 'http://localhost:5050/api/v1';
const LOCAL_API_URL_NOTIFICATION = 'http://localhost:5050';
const LOCAL_INTERNAL_API_URL = 'http://backend:5000/api/v1';
const LOCAL_INTERNAL_API_URL_NOTIFICATION = 'http://backend:5000';

const CLIENT_API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  (appEnv === 'production'
    ? PRODUCTION_API_URL
    : appEnv === 'staging'
      ? STAGING_API_URL
      : LOCAL_API_URL);

const SERVER_API_BASE_URL =
  process.env.INTERNAL_API_BASE_URL ||
  process.env.NEXT_PUBLIC_API_BASE_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  (appEnv === 'production'
    ? PRODUCTION_API_URL
    : appEnv === 'staging'
      ? STAGING_API_URL
      : LOCAL_INTERNAL_API_URL);

const CLIENT_NOTIFICATION_URL =
  process.env.NEXT_PUBLIC_API_URL_NOTIFICATION ||
  (appEnv === 'production'
    ? PRODUCTION_API_URL_NOTIFICATION
    : appEnv === 'staging'
      ? STAGING_API_URL_NOTIFICATION
      : LOCAL_API_URL_NOTIFICATION);

const SERVER_NOTIFICATION_URL =
  process.env.INTERNAL_API_URL_NOTIFICATION ||
  process.env.NEXT_PUBLIC_API_URL_NOTIFICATION ||
  (appEnv === 'production'
    ? PRODUCTION_API_URL_NOTIFICATION
    : appEnv === 'staging'
      ? STAGING_API_URL_NOTIFICATION
      : LOCAL_INTERNAL_API_URL_NOTIFICATION);

// Use environment variables if available, otherwise use environment-based defaults
export const API_BASE_URL = 
  isServer ? SERVER_API_BASE_URL : CLIENT_API_BASE_URL;

export const API_BASE_URL_NOTIFICATION = 
  isServer ? SERVER_NOTIFICATION_URL : CLIENT_NOTIFICATION_URL;

export const getSocketUrl = (): string => {
  if (process.env.NEXT_PUBLIC_API_URL_NOTIFICATION) {
    return process.env.NEXT_PUBLIC_API_URL_NOTIFICATION;
  }
  
  // Otherwise use environment-based default
  return isServer ? SERVER_NOTIFICATION_URL : CLIENT_NOTIFICATION_URL;
};
