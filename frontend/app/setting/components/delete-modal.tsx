"use client";

import { useState } from "react";
import "../style/delete-account-modal.css";
import { deleteUserAccount } from "@/app/services/account-service";

interface DeleteAccountModalProps {
  onClose: () => void;
}

export default function DeleteAccountModal({
  onClose,
}: DeleteAccountModalProps) {
  const [reason, setReason] = useState("");
  const [feedback, setFeedback] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!reason) {
      alert("Please select a reason for account deletion.");
      return;
    }

    let usernameOrEmail = "";
    const storedUser = sessionStorage.getItem("user");
    if (storedUser) {
      try {
        const user = JSON.parse(storedUser);
        usernameOrEmail = user.username || "";
      } catch (err) {
        console.error("Failed to parse user from sessionStorage:", err);
      }
    }

    if (!usernameOrEmail) {
      alert("No username found in session. Cannot delete account.");
      return;
    }

    try {
      const isEmail = usernameOrEmail.includes("@");
      const payload = {
        reason,
        comments: feedback,
        ...(isEmail
          ? { email: usernameOrEmail }
          : { username: usernameOrEmail }),
      };

      const response = await deleteUserAccount(payload);

      if (response.status === "success") {
        sessionStorage.clear();
        window.location.href = "/login";
      } else {
        alert(`Deletion error: ${response.message}`);
      }
    } catch (error: any) {
      console.error("Error deleting account:", error);
      alert(error.message || "An unexpected error occurred.");
    }
  };

  return (
    <div className="fixed inset-0 top-0 bg-black/60 flex items-center justify-center">
      <div className="bg-white rounded-3xl w-full max-w-md p-6 relative">
        <button
          onClick={onClose}
          className="absolute right-4 top-4 text-gray-400 hover:text-gray-600"
        >
          ×
        </button>

        <h2 className="text-lg font-semibold text-center mb-4">
          Delete Account
        </h2>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-3">
            <p className="text-md font-medium mb-2">Select Reason</p>

            <label className="flex items-start gap-3">
              <input
                type="radio"
                name="reason"
                value="dont-use"
                checked={reason === "dont-use"}
                onChange={(e) => setReason(e.target.value)}
                className="mt-0.5 custom-radio"
              />
              <span className="text-sm">I don't want to use Seattle Pulse</span>
            </label>

            <label className="flex items-start gap-3">
              <input
                type="radio"
                name="reason"
                value="another-account"
                checked={reason === "another-account"}
                onChange={(e) => setReason(e.target.value)}
                className="mt-0.5 custom-radio"
              />
              <span className="text-sm">I have another account</span>
            </label>

            <label className="flex items-start gap-3">
              <input
                type="radio"
                name="reason"
                value="problems"
                checked={reason === "problems"}
                onChange={(e) => setReason(e.target.value)}
                className="mt-0.5 custom-radio"
              />
              <span className="text-sm">This website has some problems</span>
            </label>

            <label className="flex items-start gap-3">
              <input
                type="radio"
                name="reason"
                value="other"
                checked={reason === "other"}
                onChange={(e) => setReason(e.target.value)}
                className="mt-0.5 custom-radio"
              />
              <span className="text-sm">Other</span>
            </label>
          </div>

          {/* Feedback textarea */}
          <div className="space-y-2">
            <p className="text-sm">Anything else you want to add</p>
            <textarea
              value={feedback}
              onChange={(e) => setFeedback(e.target.value)}
              placeholder="Write/suggest something to improve our app"
              className="w-full rounded-3xl  border-[#ABB0B9] border-[2px] p-3 text-sm min-h-[100px] resize-none focus:outline-none focus:border-gray-300"
            />
          </div>

          {/* Warning message */}
          <p className="text-[#b81616] text-xs">
            *All your data will be deleted permanently from our server. This
            action is irreversible.
          </p>

          {/* Action buttons */}
          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2.5 border-[2px] border-black rounded-xl text-sm hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 px-4 py-2.5 bg-[#b81616] text-white rounded-xl text-sm hover:bg-red-600"
            >
              Delete my Account
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
