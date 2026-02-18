import { JSX, ReactNode } from "react";

export function AvatarGroup({ children }: { children: ReactNode }): JSX.Element {
    const avatars = Array.isArray(children) ? children : [children];
  
    return (
      <div className="flex -space-x-2">
        {avatars.map((avatar, i) => (
          <div key={i} className="relative">
            {avatar}
          </div>
        ))}
      </div>
    );
  }