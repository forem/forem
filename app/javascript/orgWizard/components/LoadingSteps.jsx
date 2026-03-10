import { h } from 'preact';
import { useState, useEffect } from 'preact/hooks';

const FLAVOR_TEXTS = [
  'Pretending to type really fast...',
  'Consulting the DEV community hivemind...',
  'Asking the AI to use its inside voice...',
  'Teaching pixels about your brand...',
  'Convincing the markdown to behave...',
  'Summoning the liquid tag wizards...',
  'Politely asking servers for data...',
  'Reading between the <div>s...',
  'Turning caffeine into content...',
  'Optimizing for developer happiness...',
  'Debating serif vs sans-serif internally...',
  'Sprinkling some DEV magic on top...',
  'Carefully arranging ones and zeros...',
  'Warming up the content engine...',
  'Cross-referencing with the internet...',
  "Crafting something you'll actually want to ship...",
  'Building at mass scale, as they say...',
  'This is the fun part, promise...',
  'Almost there... (for real this time)',
  'Generating vibes... and also content...',
];

export function LoadingSteps({ steps }) {
  const [currentStep, setCurrentStep] = useState(0);
  const [elapsed, setElapsed] = useState(0);
  const [flavorIdx, setFlavorIdx] = useState(
    () => Math.floor(Math.random() * FLAVOR_TEXTS.length),
  );
  const [flavorVisible, setFlavorVisible] = useState(true);

  useEffect(() => {
    const timer = setInterval(() => {
      setElapsed((prev) => prev + 1000);
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  // Rotate flavor text every 3 seconds with fade
  useEffect(() => {
    const rotateTimer = setInterval(() => {
      setFlavorVisible(false);
      setTimeout(() => {
        setFlavorIdx((prev) => (prev + 1) % FLAVOR_TEXTS.length);
        setFlavorVisible(true);
      }, 300);
    }, 3000);
    return () => clearInterval(rotateTimer);
  }, []);

  useEffect(() => {
    // Space steps evenly across ~16s, starting at 0
    const interval = 16000 / steps.length;
    const delays = steps.map((_, i) => i * interval);
    const idx = delays.filter((d) => elapsed >= d).length - 1;
    if (idx >= 0 && idx < steps.length) {
      setCurrentStep(idx);
    }
  }, [elapsed, steps.length]);

  return (
    <div className="py-8">
      <style>{`
        @keyframes wizard-pulse {
          0%, 100% { transform: scale(1); }
          50% { transform: scale(1.3); }
        }
      `}</style>
      <div className="m-auto" style={{ maxWidth: '400px' }}>
        {steps.map((step, idx) => {
          const isDone = idx < currentStep;
          const isCurrent = idx === currentStep;
          const isPending = idx > currentStep;

          return (
            <div
              key={idx}
              className="flex items-center gap-3 py-2"
              style={{
                opacity: isPending ? 0.3 : 1,
                transition: 'opacity 0.4s ease',
              }}
            >
              <span
                className="fs-l"
                style={{
                  width: '28px',
                  textAlign: 'center',
                  ...(isCurrent ? {
                    animation: 'wizard-pulse 1.5s ease-in-out infinite',
                  } : {}),
                }}
              >
                {isDone ? '✓' : isCurrent ? step.icon : '○'}
              </span>
              <span
                className={`fs-s ${isDone ? 'color-base-50' : isCurrent ? 'fw-medium color-base-90' : 'color-base-40'}`}
                style={{ transition: 'color 0.3s ease' }}
              >
                {step.label}
              </span>
              {isCurrent && (
                <span
                  className="crayons-indicator crayons-indicator--loading"
                  style={{ width: '16px', height: '16px' }}
                />
              )}
            </div>
          );
        })}

        <div
          className="mt-6 pt-4 fs-xs color-base-50 text-center"
          style={{
            borderTop: '1px solid var(--base-10)',
            opacity: flavorVisible ? 0.7 : 0,
            transition: 'opacity 0.3s ease',
            minHeight: '24px',
          }}
        >
          {FLAVOR_TEXTS[flavorIdx]}
        </div>
      </div>
    </div>
  );
}
