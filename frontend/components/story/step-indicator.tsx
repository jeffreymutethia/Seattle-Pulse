import { Step } from "@/app/types/story"

interface StepIndicatorProps {
  steps: Step[]
  currentStep: number
}

export default function StepIndicator({
  steps,
  currentStep,
}: StepIndicatorProps) {
  const current = steps.find((s) => s.id === currentStep)!

  const isDone = (id: number) => id < currentStep
  const isActive = (id: number) => id === currentStep

  // decide circle styles
  const circleClass = isDone(current.id)
    ? "bg-[#E1E2F8] border-2 border-[#4C68D5] text-[#4C68D5]"
    : isActive(current.id)
    ? "bg-[#4C68D5] text-white"
    : "bg-gray-100 text-gray-500"

  return (
    <>
      {/* ── MOBILE: single-step view ── */}
      <div className="flex flex-col items-center md:hidden py-0 px-4 bg-white rounded-xl shadow-sm">
        {/* <div
          className={`
            flex items-center justify-center 
            w-12 h-12 rounded-full 
            ${circleClass}
          `}
        >
          {isDone(current.id) ? (
            <img src="./seen.png" className="w-5 h-5" />
          ) : (
            <img
              src={current.icon || "/placeholder.svg"}
              className={`w-6 h-6 ${isActive(current.id) ? "invert brightness-0" : ""}`}
            />
          )}
        </div> */}
        <p className="mt-3 text-lg font-medium text-[#4C68D5]">
          {current.name}
        </p>
        <p className="mt-1 text-sm text-gray-500">
          Step {currentStep} of {steps.length}
        </p>
      </div>

      {/* ── DESKTOP: your original stepper, untouched ── */}
      <div className="hidden md:flex justify-center items-center gap-6 border-b">
        {steps.map((step, index) => (
          <div key={step.id} className="flex items-center gap-2 mb-4">
            <div
              className={`flex items-center justify-center w-10 h-10 rounded-full ${
                step.id < currentStep
                  ? "bg-[#E1E2F8] border-2 border-[#4C68D5] text-white"
                  : step.id === currentStep
                  ? "bg-[#4C68D5] text-white"
                  : "bg-gray-100 text-gray-500"
              }`}
            >
              {step.id < currentStep ? (
                <img src="./seen.png" className="w-5 h-5" />
              ) : (
                <img
                  src={step.icon || "/placeholder.svg"}
                  className={`w-6 h-6 ${
                    step.id === currentStep ? "invert brightness-0" : ""
                  }`}
                />
              )}
            </div>
            <div className="ml-3">
              <p
                className={`text-sm font-medium ${
                  step.id < currentStep
                    ? "text-[#4C68D5]"
                    : step.id === currentStep
                    ? "text-[#4C68D5]"
                    : "text-gray-500"
                }`}
              >
                {step.name}
              </p>
            </div>
            {index < steps.length - 1 && (
              <img
                src={step.id < currentStep ? "./Arroww.png" : "./Arrow.png"}
                className="w-12"
                alt="Step Arrow"
              />
            )}
          </div>
        ))}
      </div>
    </>
  )
}
