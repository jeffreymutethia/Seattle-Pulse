interface CaptionStepProps {
  caption: string;
  onCaptionChange: (caption: string) => void;
}

export default function CaptionStep({
  caption,
  onCaptionChange,
}: CaptionStepProps) {
  return (
    <>
      {/* ── MOBILE (<md): fluid height, smaller textarea ── */}
      <div className="md:hidden px-4 space-y-6">
        <div className="mb-4">
          <h2 className="text-center text-lg text-[#0C1024] font-bold mb-1">
            Add Caption
          </h2>
          <p className="text-center text-sm text-[#5D6778]">
            Write a caption that describes your story. Keep it short and
            engaging, or skip this stage by clicking <strong>"Next"</strong>
          </p>
        </div>

        <div className="space-y-2">
          <p className="text-base text-[#0C1024] font-normal">Caption</p>
          <textarea
            className="border-[#ABB0B9] rounded-3xl border-2 p-4 w-full h-40"
            placeholder="Write your caption here..."
            value={caption}
            onChange={(e) => onCaptionChange(e.target.value)}
            maxLength={100}
          />
          <div className="text-right text-sm text-gray-500">
            {caption.length} / 100
          </div>
        </div>
      </div>

      {/* ── DESKTOP (≥md): exactly your original code, untouched ── */}
      <div className="hidden md:block">
        <div className="mb-8">
          <h2 className="mb-2 text-center text-xl text-[#0C1024] font-bold">
            Add Caption
          </h2>
          <p className="text-center text-sm">
            Write a caption that describes your story. Keep it short and
            engaging, or skip this stage by clicking <strong>"Next"</strong>
          </p>
        </div>
        <div className="space-y-2">
          <p className="text-base text-[#0C1024] font-normal">Caption</p>
          <div className="max-w-[1150px] h-[466px]">
            <textarea
              className="border-[#ABB0B9] rounded-3xl border-2 p-4 w-full h-full"
              placeholder="Write your caption here..."
              value={caption}
              onChange={(e) => onCaptionChange(e.target.value)}
            />
          </div>
          <div className="text-right text-sm text-gray-500">
            {caption.length} / 100
          </div>
        </div>
      </div>
    </>
  );
}
