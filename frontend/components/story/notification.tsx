import { XIcon, CheckIcon, AlertTriangleIcon } from "lucide-react";
import { createPortal } from "react-dom";
import { useEffect, useState } from "react";

interface NotificationProps {
  title: string | null;
  message: string | null;
  type?: "success" | "error";
  onClose: () => void;
  onHomeClick: () => void;
}

export default function Notification({ ...props }: NotificationProps) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!props.message || !mounted) return null;

  const bgColor = props.type === "error" ? "bg-red-500" : "bg-[#4C68D5]";
  const Icon = props.type === "error" ? AlertTriangleIcon : CheckIcon;

  return createPortal(
    <div
      className={`fixed top-4 left-1/2 transform -translate-x-1/2 ${bgColor} text-white px-6 py-3 rounded-3xl shadow-md z-[9999]`}
    >
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <Icon
            className="h-5 w-5 inline-block cursor-pointer"
            onClick={props.onHomeClick}
          />
          <p className="font-semibold">{props.title}</p>
        </div>
        <XIcon
          className="h-5 w-5 inline-block cursor-pointer"
          onClick={props.onClose}
        />
      </div>
      {props.message && <div className="mt-2 ml-7">{props.message}</div>}
    </div>,
    document.body
  );
}
