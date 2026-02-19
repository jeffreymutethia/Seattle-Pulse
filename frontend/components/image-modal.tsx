"use client"

import { Dialog, DialogContent, DialogTitle } from "@/components/ui/dialog"
import Image from "next/image"

interface ImageModalProps {
  isOpen: boolean
  onClose: () => void
  src: string
  alt: string
}

export function ImageModal({ isOpen, onClose, src, alt }: ImageModalProps) {
  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-[90vw] max-h-[90vh] p-0">
        <DialogTitle className="sr-only">Image preview</DialogTitle>
        <div className="relative w-full aspect-video">
          <Image src={src || "/placeholder.svg"} alt={alt} fill className="object-contain" priority />
        </div>
      </DialogContent>
    </Dialog>
  )
}
