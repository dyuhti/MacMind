import React, { useState } from 'react';
import { Copy, Check } from 'lucide-react';
import './FormulaDisplay.plain.css';

/**
 * FormulaDisplay Component - Plain CSS Version
 * 
 * Same functionality as Tailwind version, but using plain CSS for styling.
 * Use this if you prefer vanilla CSS over Tailwind utilities.
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
    <div className="formula-display-wrapper">
      {title && <h3 className="formula-display-title">{title}</h3>}

      {/* Formula Container */}
      <div className="formula-display-container">
        {/* Main Formula Box */}
        <div className="formula-display-box">
          {/* Formula Text - centered and wrappable */}
          <div className="formula-display-text-wrapper">
            <p
              className="formula-display-text"
              role="region"
              aria-label="Mathematical formula"
            >
              {formula}
            </p>
          </div>

          {/* Copy Button */}
          <button
            onClick={handleCopyFormula}
            aria-label="Copy formula"
            className="formula-display-button"
            title="Copy to clipboard"
          >
            {copied ? (
              <Check className="formula-icon formula-icon-check" />
            ) : (
              <Copy className="formula-icon formula-icon-copy" />
            )}
          </button>

          {/* Feedback Tooltip */}
          {copied && (
            <div className="formula-display-tooltip">
              Copied!
            </div>
          )}
        </div>

        {/* Help Text */}
        <p className="formula-display-help-text">
          Click the button or press <kbd>Tab</kbd> + <kbd>Enter</kbd> to copy
        </p>
      </div>
    </div>
  );
}
