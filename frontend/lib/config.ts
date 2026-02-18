const getEnvironment = (): 'staging' | 'production' => {
  if (process.env.NEXT_PUBLIC_APP_ENV === 'production') return 'production';
  if (process.env.NEXT_PUBLIC_APP_ENV === 'staging') return 'staging';
  
  if (process.env.NODE_ENV === 'production') {
    return process.env.NEXT_PUBLIC_APP_ENV === 'staging' ? 'staging' : 'production';
  }
  
  return 'staging';
};

const appEnv = getEnvironment();

// Environment-based API URLs
const STAGING_API_URL = 'https://api.staging.seattlepulse.net/api/v1';
const STAGING_API_URL_NOTIFICATION = 'https://api.staging.seattlepulse.net';
const PRODUCTION_API_URL = 'https://api.seattlepulse.net/api/v1';
const PRODUCTION_API_URL_NOTIFICATION = 'https://api.seattlepulse.net';

// Use environment variables if available, otherwise use environment-based defaults
export const API_BASE_URL = 
  process.env.NEXT_PUBLIC_API_URL || 
  (appEnv === 'production' ? PRODUCTION_API_URL : STAGING_API_URL);

export const API_BASE_URL_NOTIFICATION = 
  process.env.NEXT_PUBLIC_API_URL_NOTIFICATION || 
  (appEnv === 'production' ? PRODUCTION_API_URL_NOTIFICATION : STAGING_API_URL_NOTIFICATION);

export const getSocketUrl = (): string => {
  if (process.env.NEXT_PUBLIC_API_URL_NOTIFICATION) {
    return process.env.NEXT_PUBLIC_API_URL_NOTIFICATION;
  }
  
  // Otherwise use environment-based default
  return appEnv === 'production' ? PRODUCTION_API_URL_NOTIFICATION : STAGING_API_URL_NOTIFICATION;
};
