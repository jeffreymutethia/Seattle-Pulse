import { useState, useEffect } from "react";
import { ExtendedComment, RawComment } from "../types/comment";
import { transformComment } from "../services/comment-service";

export const useComments = (rawComments: RawComment[] = []) => {
  const [comments, setComments] = useState<ExtendedComment[]>([]);

  useEffect(() => {
    const transformed = rawComments.map(transformComment);
    setComments(transformed);
  }, [rawComments]);

  return { comments, setComments };
};
