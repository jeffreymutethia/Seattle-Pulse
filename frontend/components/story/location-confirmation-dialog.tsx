import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogDescription,
    DialogFooter,
  } from "@/components/ui/dialog"
  import { Button } from "@/components/ui/button"
  
  interface LocationConfirmationDialogProps {
    open: boolean
    onOpenChange: (open: boolean) => void
    location: string
    isValidLocation: boolean
    suggestionsLoading: boolean
    onConfirm: () => void
    onDecline: () => void
  }
  
  export default function LocationConfirmationDialog({
    open,
    onOpenChange,
    location,
    isValidLocation,
    suggestionsLoading,
    onConfirm,
    onDecline,
  }: LocationConfirmationDialogProps) {
    return (
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Confirm Your Location</DialogTitle>
            <DialogDescription>Please select a valid Seattle neighborhood from the search results.</DialogDescription>
          </DialogHeader>
          <div className="py-4">
            <p>{location || "No location detected"}</p>
            {!isValidLocation && <p className="text-sm text-red-500 mt-2">Please select a valid Seattle neighborhood.</p>}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={onDecline}>
              Decline
            </Button>
            <Button onClick={onConfirm} disabled={!isValidLocation || suggestionsLoading}>
              Confirm Location
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    )
  }
  
  