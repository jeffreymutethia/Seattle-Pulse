import { JSX } from "react";

export function MessagePlaceholder(): JSX.Element {
  return (
    <div className="min-h-screen flex items-center justify-center px-4 sm:px-6 lg:px-8">
      <div className="text-center space-y-4 max-w-md w-full">
        <div className="w-16 h-16 mx-auto">
          <img src="./Inbox.svg" alt="Inbox" className="w-full h-full object-contain" />
        </div>

        <p className="text-base font-medium text-black">Your messages</p>

        <p className="text-gray-500 text-sm sm:text-base max-w-md mx-auto">
          Select a person to display their chat or start a new
          <br className="hidden sm:block" /> conversation
        </p>

        <button
          className="mt-6 sm:mt-8 px-5 sm:px-6 py-2 sm:py-2.5 bg-black text-white rounded-lg 
                     hover:bg-gray-800 transition-colors duration-200 
                     flex items-center justify-center gap-2 mx-auto"
        >
          <svg
            className="w-4 h-4 sm:w-5 sm:h-5"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M12 20h9" />
            <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z" />
          </svg>
          <span className="text-sm sm:text-base">Write a Message</span>
        </button>
      </div>
    </div>
  );
}
