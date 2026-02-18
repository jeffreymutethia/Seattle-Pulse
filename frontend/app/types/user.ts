export interface User {
  id: number;
  profile_picture_url: string | null;
  username: string;
}

export interface Person {
  first_name: string;
  last_name: string;
  id: number;
  username: string;
  profile_picture_url: string;
  total_followers: number;
  location: string;
  is_following: boolean;
}
