import { h } from 'preact';

const MAX_SUGGESTIONS = 3;
const MAX_IMAGE_SUGGESTIONS = 2;

const extractRelevantErrors = (lintErrors) => {
  // todo - don't make it an object
  const errorsForDisplay = { imageErrors: [], otherErrors: [] };

  lintErrors.forEach((lintError) => {
    if (
      lintError.ruleNames.includes('no-default-alt-text') ||
      lintError.ruleNames.includes('no-empty-alt-text')
    ) {
      errorsForDisplay.imageErrors.push(lintError);
    } else {
      errorsForDisplay.otherErrors.push(lintError);
    }
  });

  //   Truncate the errors
  if (errorsForDisplay.imageErrors.length > MAX_IMAGE_SUGGESTIONS) {
    errorsForDisplay.imageErrors = errorsForDisplay.imageErrors.slice(
      0,
      MAX_IMAGE_SUGGESTIONS,
    );
  }

  const totalImageErrors = errorsForDisplay.imageErrors.length;
  const remainingErrors = MAX_SUGGESTIONS - totalImageErrors;

  if (errorsForDisplay.otherErrors.length > remainingErrors) {
    errorsForDisplay.otherErrors = errorsForDisplay.otherErrors.slice(
      0,
      remainingErrors,
    );
  }

  return [...errorsForDisplay.imageErrors, ...errorsForDisplay.otherErrors];
};

export const AccessibilitySuggestions = ({ markdownLintErrors }) => {
  return (
    <div
      className="crayons-notice crayons-notice--info mb-6"
      aria-live="polite"
    >
      <h3 className="fs-l mb-2 fw-bold">
        Improve the accessibility of your post:
      </h3>
      <ul>
        {extractRelevantErrors(markdownLintErrors).map((lintError, index) => {
          return <li key={`linterror-${index}`}>{lintError.errorContext}</li>;
        })}
      </ul>
    </div>
  );
};
