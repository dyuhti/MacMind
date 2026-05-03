import React, { useState } from 'react';
import { Copy, Check } from 'lucide-react';

/**
 * FormulaDisplay Component
 * 
 * A clean, accessible formula display container with a copy-to-clipboard feature.
 * Meets all requirements: styling, accessibility, responsiveness, and edge case handling.
 */
export default function FormulaDisplay({ formula, title }) {
  const [copied, setCopied] = useState(false);

  const handleCopyFormula = async (e) => {
    e.preventDefault();
    e.stopPropagation();

    try {
      await navigator.clipboard.writeText(formula);
      setCopied(true);

      // Reset feedback after 2 seconds
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Failed to copy formula:', err);
    }
  };

  return (
    <div className="w-full flex flex-col items-center gap-4 p-6">
      {title && (
        <h3 className="text-lg font-semibold text-gray-800">{title}</h3>
      )}

      {/* Formula Container */}
      <div className="relative w-full max-w-2xl">
        {/* Main Formula Box */}
        <div
          className="
            relative
            px-6 py-6
            bg-gradient-to-b from-blue-50 to-indigo-50
            border border-blue-200
            rounded-lg
            shadow-sm
            overflow-hidden
          "
        >
          {/* Formula Text - centered and wrappable */}
          <div className="pr-14 text-center">
            <p
              className="
                font-mono
                text-lg
                text-gray-900
                leading-relaxed
                break-words
                whitespace-pre-wrap
              "
              role="region"
              aria-label="Mathematical formula"
            >
              {formula}
            </p>
          </div>

          {/* Copy Button - Absolute Positioning */}
          <button
            onClick={handleCopyFormula}
            aria-label="Copy formula"
            className="
              absolute
              top-2 right-2
              p-2
              bg-transparent
              hover:bg-gray-100
              text-gray-600
              hover:text-gray-800
              rounded-md
              transition-all
              duration-200
              ease-in-out
              focus:outline-none
              focus:ring-2
              focus:ring-blue-500
              focus:ring-offset-2
              cursor-pointer
              group
            "
            title="Copy to clipboard"
          >
            {copied ? (
              <Check className="w-5 h-5 text-green-600 transition-colors" />
            ) : (
              <Copy className="w-5 h-5 transition-colors group-hover:text-blue-600" />
            )}
          </button>

          {/* Feedback Tooltip */}
          {copied && (
            <div
              className="
                absolute
                top-12 right-2
                bg-green-600
                text-white
                px-3 py-1.5
                rounded-md
                text-sm
                font-medium
                whitespace-nowrap
                pointer-events-none
                animate-fade-in-out
                shadow-lg
              "
            >
              Copied!
            </div>
          )}
        </div>

        {/* Help Text */}
        <p className="text-xs text-gray-500 mt-2 text-center">
          Click the button or press <kbd className="px-1.5 py-0.5 bg-gray-100 border border-gray-300 rounded text-xs">Tab</kbd> + <kbd className="px-1.5 py-0.5 bg-gray-100 border border-gray-300 rounded text-xs">Enter</kbd> to copy
        </p>
      </div>
    </div>
  );
}
