import React from 'react';
import FormulaDisplay from './FormulaDisplay';
import './FormulaDisplay.css';

/**
 * Demo component showing FormulaDisplay usage with various examples
 */
export default function FormulaDisplayDemo() {
  const formulas = [
    {
      title: 'Basic Formula',
      text: 'E = mc²'
    },
    {
      title: 'Complex Medical Formula',
      text: 'BMI = weight (kg) / height (m)²'
    },
    {
      title: 'Long Formula with Wrapping',
      text: 'Dosage = (Patient Weight × Concentration × Rate) / (Duration × 60)'
    },
    {
      title: 'Multi-line Formula',
      text: `Area = π × r²
Circumference = 2π × r
Radius = √(Area / π)`
    },
    {
      title: 'Chemical Formula',
      text: 'H₂O + CO₂ → H₂CO₃'
    }
  ];

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto">
        <div className="mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            Formula Display Component
          </h1>
          <p className="text-lg text-gray-600">
            A clean, accessible, and responsive formula display component
            with copy-to-clipboard functionality.
          </p>
        </div>

        {/* Feature List */}
        <div className="grid md:grid-cols-2 gap-6 mb-12">
          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <h3 className="font-semibold text-gray-900 mb-3">✓ Features</h3>
            <ul className="text-sm text-gray-700 space-y-2">
              <li>✓ Copy to clipboard with instant feedback</li>
              <li>✓ Fully keyboard accessible (Tab + Enter)</li>
              <li>✓ Responsive design on all screen sizes</li>
              <li>✓ Long formula wrapping support</li>
              <li>✓ ARIA labels for screen readers</li>
              <li>✓ No external dependencies (uses lucide-react)</li>
            </ul>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <h3 className="font-semibold text-gray-900 mb-3">🎨 Styling</h3>
            <ul className="text-sm text-gray-700 space-y-2">
              <li>• Subtle gradient background (blue-50 to indigo-50)</li>
              <li>• Soft border and shadow</li>
              <li>• Rounded corners (8px)</li>
              <li>• Monospace font for formulas</li>
              <li>• Hover and focus states</li>
              <li>• Smooth transitions</li>
            </ul>
          </div>
        </div>

        {/* Examples */}
        <div className="space-y-8">
          <h2 className="text-2xl font-bold text-gray-900">Examples</h2>
          {formulas.map((formula, index) => (
            <FormulaDisplay
              key={index}
              title={formula.title}
              formula={formula.text}
            />
          ))}
        </div>

        {/* Usage Instructions */}
        <div className="mt-12 bg-blue-50 border border-blue-200 rounded-lg p-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4">
            How to Use
          </h2>
          <pre className="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto text-sm">
{`import FormulaDisplay from './FormulaDisplay';
import './FormulaDisplay.css';

export default function MyApp() {
  return (
    <FormulaDisplay
      title="Pythagorean Theorem"
      formula="a² + b² = c²"
    />
  );
}`}
          </pre>
        </div>

        {/* Props Documentation */}
        <div className="mt-8 bg-gray-100 rounded-lg p-6">
          <h3 className="text-lg font-bold text-gray-900 mb-4">Props</h3>
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-300">
                <th className="text-left py-2 px-4 font-semibold">Prop</th>
                <th className="text-left py-2 px-4 font-semibold">Type</th>
                <th className="text-left py-2 px-4 font-semibold">Description</th>
              </tr>
            </thead>
            <tbody>
              <tr className="border-b border-gray-200">
                <td className="py-2 px-4 font-mono text-gray-700">formula</td>
                <td className="py-2 px-4 text-gray-600">string</td>
                <td className="py-2 px-4 text-gray-600">Required. The formula text to display</td>
              </tr>
              <tr>
                <td className="py-2 px-4 font-mono text-gray-700">title</td>
                <td className="py-2 px-4 text-gray-600">string</td>
                <td className="py-2 px-4 text-gray-600">Optional. Title above the formula</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
