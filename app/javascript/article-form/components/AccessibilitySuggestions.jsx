import { h } from 'preact';

const MAX_SUGGESTIONS = 3;
const MAX_IMAGE_SUGGESTIONS = 2;

const extractRelevantErrors = (lintErrors) => {
  const imageErrors = [];
  const otherErrors = [];

  lintErrors.forEach((lintError) => {
    if (
      lintError.ruleNames.includes('no-default-alt-text') ||
      lintError.ruleNames.includes('no-empty-alt-text')
    ) {
      imageErrors.push({ ...lintError, errorType: 'image' });
    } else {
      otherErrors.push({ ...lintError, errorType: 'other' });
    }
  });

  //   Truncate the errors, favouring image errors (as these accessibility suggestions are more impactful)
  if (imageErrors.length > MAX_IMAGE_SUGGESTIONS) {
    imageErrors.length = MAX_IMAGE_SUGGESTIONS;
  }

  const totalImageErrors = imageErrors.length;
  const remainingErrors = MAX_SUGGESTIONS - totalImageErrors;

  if (otherErrors.length > remainingErrors) {
    otherErrors.length = remainingErrors;
  }

  return [...imageErrors, ...otherErrors];
};

export const AccessibilitySuggestions = ({ markdownLintErrors }) => {
  return (
    <div
      className="crayons-notice crayons-notice--info mb-6"
      aria-live="polite"
    >
      <h2 className="fs-l mb-2 fw-bold">
        Improve the accessibility of your post:
      </h2>
      <ul>
        {extractRelevantErrors(markdownLintErrors).map((lintError, index) => {
          return (
            <li key={`linterror-${index}`}>
              {lintError.errorContext}
              <span className="fs-s">
                {' '}
                <a
                  href={lintError.errorDetail}
                  aria-label={
                    lintError.errorType === 'image'
                      ? 'Learn more about accessible images'
                      : 'Learn more about accessible headings'
                  }
                >
                  Learn more
                </a>
              </span>
            </li>
          );
        })}
      </ul>
    </div>
  );
};
