"use client";

import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";

type ReportModalProps = {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (reason: string, customReason?: string) => void;
};

// ['Spam', 'Harassment', 'Violence', 'Inappropriate Language', 'Hate Speech', 'Sexual Content', 'False Information', 'Other']

const REASONS = [
  { label: "Spam", value: "Spam" },
  { label: "Harassment", value: "Harassment" },
  { label: "Violence", value: "Violence" },
  { label: "Inappropriate Language", value: "Inappropriate Language" },
  { label: "Hate Speech", value: "Hate Speech" },
  { label: "Sexual Content", value: "Sexual Content" },
  { label: "False Information", value: "False Information" },
  { label: "Other", value: "Other" },
];

export function ReportModal({ isOpen, onClose, onSubmit }: ReportModalProps) {
  const [reason, setReason] = useState<string>("");
  const [customReason, setCustomReason] = useState<string>("");

  const handleSubmit = () => {
    if (!reason) return;
    if (reason === "OTHER" && !customReason.trim()) return;

    onSubmit(reason, reason === "OTHER" ? customReason : undefined);
    setReason("");
    setCustomReason("");
    onClose();
  };

  const handleClose = () => {
    setReason("");
    setCustomReason("");
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && handleClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Report Post</DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          <p>Please select a reason for reporting this post:</p>
          <Select value={reason} onValueChange={(val) => setReason(val)}>
            <SelectTrigger>
              <SelectValue placeholder="-- Select Reason --" />
            </SelectTrigger>
            <SelectContent>
              {REASONS.map((r) => (
                <SelectItem key={r.value} value={r.value}>
                  {r.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>

          {reason === "OTHER" && (
            <Textarea
              value={customReason}
              onChange={(e) => setCustomReason(e.target.value)}
              placeholder="Describe your reason..."
              rows={3}
            />
          )}
        </div>

        <DialogFooter className="mt-4">
          <Button variant="outline" onClick={handleClose}>
            Cancel
          </Button>
          <Button onClick={handleSubmit}>Submit</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
