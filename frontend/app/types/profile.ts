export interface UserData {
  id: number;
}

export interface Relationships {
  followers: number;
}

export interface ProfileData {
  userData: {
    data: {
      is_following: boolean;
      relationships: {
        followers: number;
        following: number;
        total_posts: number;
      };
      user_data: {
        bio: string | null;
        email: string;
        id: number;
        first_name: string;
        last_name: string;
        location: string | null;
        profile_picture_url: string | null;
        show_home_location: boolean;
        username: string;
      };
    };
    message: string;
    success: string;
  };
  onFollowToggle: () => void;
  isMyProfile: boolean;
}

export interface ProfileResponse {
  data: ProfileData;
}

export interface PostsResponse {
  data: {
    posts: any[];
  };
}

export interface RepostsResponse {
  data: {
    reposts: any[];
  };
}
