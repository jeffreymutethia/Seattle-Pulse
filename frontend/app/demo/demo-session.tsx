"use client";

import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { IS_DEMO } from "@/lib/demo";
import { demoPublishers } from "./fixtures";

export interface DemoReader {
  id: number;
  username: string;
  first_name: string;
  last_name: string;
  bio: string;
  email: string;
  location: string;
  profile_picture_url: string;
  show_home_location: boolean;
}

export const demoReader: DemoReader = {
  id: 9000,
  username: "alex.morgan",
  first_name: "Alex",
  last_name: "Morgan",
  bio: "A Seattle neighbor collecting good walks, independent coffee stops, and places to linger. Fictional demo account.",
  email: "reader@seattlepulse.demo",
  location: "Capitol Hill, Seattle",
  profile_picture_url: "/demo/publishers/demo-reader.svg",
  show_home_location: true,
};

const keys = {
  session: "seattle-pulse-demo-reader",
  follows: "seattle-pulse-demo-follows",
  comments: "seattle-pulse-demo-comments",
  profile: "seattle-pulse-demo-profile",
};
const initialFollows = [9101, 9102, 9201];
type ProfilePatch = Partial<Pick<DemoReader, "first_name" | "last_name" | "bio" | "location">>;

interface DemoSession {
  ready: boolean;
  isSignedIn: boolean;
  reader: DemoReader;
  followedSourceIds: number[];
  comments: Record<number, string[]>;
  signIn: () => void;
  signOut: () => void;
  toggleFollow: (id: number) => void;
  addComment: (id: number, content: string) => void;
  updateReader: (patch: ProfilePatch) => void;
}

const Context = createContext<DemoSession | null>(null);
const save = (key: string, value: string) => {
  try { sessionStorage.setItem(key, value); } catch { /* In-memory demo still works if storage is unavailable. */ }
};

function Provider({ children }: { children: ReactNode }) {
  const [ready, setReady] = useState(false);
  const [isSignedIn, setSignedIn] = useState(false);
  const [reader, setReader] = useState(demoReader);
  const [followedSourceIds, setFollows] = useState(initialFollows);
  const [comments, setComments] = useState<Record<number, string[]>>({});

  useEffect(() => {
    try {
      setSignedIn(sessionStorage.getItem(keys.session) === "yes");
      const savedFollows: unknown = JSON.parse(sessionStorage.getItem(keys.follows) ?? "null");
      if (Array.isArray(savedFollows)) setFollows(demoPublishers.filter(source => savedFollows.includes(source.id)).map(source => source.id));
      const savedComments: unknown = JSON.parse(sessionStorage.getItem(keys.comments) ?? "{}");
      if (savedComments && typeof savedComments === "object" && !Array.isArray(savedComments)) {
        setComments(Object.fromEntries(Object.entries(savedComments).filter(([id, values]) =>
          /^\d+$/.test(id) && Array.isArray(values) && values.every(value => typeof value === "string"))));
      }
      const savedProfile: unknown = JSON.parse(sessionStorage.getItem(keys.profile) ?? "{}");
      if (savedProfile && typeof savedProfile === "object") {
        const profile = savedProfile as Record<string, unknown>;
        const patch = Object.fromEntries(["first_name", "last_name", "bio", "location"].filter(key => typeof profile[key] === "string").map(key => [key, profile[key]]));
        setReader({ ...demoReader, ...patch });
      }
    } catch { /* An invalid or unavailable stored session starts from sample defaults. */ }
    setReady(true);
  }, []);

  const signIn = () => { save(keys.session, "yes"); setSignedIn(true); };
  const signOut = () => { save(keys.session, "no"); setSignedIn(false); };
  const toggleFollow = (id: number) => {
    if (!isSignedIn || !demoPublishers.some(source => source.id === id)) return;
    setFollows(previous => {
      const next = previous.includes(id) ? previous.filter(item => item !== id) : [...previous, id];
      save(keys.follows, JSON.stringify(next));
      return next;
    });
  };
  const addComment = (id: number, content: string) => {
    const text = content.trim().slice(0, 300);
    if (!isSignedIn || !text) return;
    setComments(previous => {
      const next = { ...previous, [id]: [...(previous[id] ?? []), text] };
      save(keys.comments, JSON.stringify(next));
      return next;
    });
  };
  const updateReader = (patch: ProfilePatch) => {
    if (!isSignedIn) return;
    setReader(previous => {
      const next = { ...previous, ...patch };
      save(keys.profile, JSON.stringify(next));
      return next;
    });
  };

  return <Context.Provider value={{ ready, isSignedIn, reader, followedSourceIds, comments, signIn, signOut, toggleFollow, addComment, updateReader }}>{children}</Context.Provider>;
}

export function DemoSessionBoundary({ children }: { children: ReactNode }) {
  return IS_DEMO ? <Provider>{children}</Provider> : children;
}

export function useDemoSession() {
  const session = useContext(Context);
  if (!session) throw new Error("Demo session is only available in the portfolio build.");
  return session;
}
