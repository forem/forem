import { h } from 'preact';
import PropTypes from 'prop-types';

// Limit the number of suggestions shown so that the UI isn't overwhelmed
const MAX_SUGGESTIONS = 3;

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

  // Truncate the errors, favouring image errors (as these accessibility suggestions are more impactful)
  if (imageErrors.length > MAX_SUGGESTIONS) {
    imageErrors.length = MAX_SUGGESTIONS;
  }

  const remainingErrors = MAX_SUGGESTIONS - imageErrors.length;
  if (otherErrors.length > remainingErrors) {
    otherErrors.length = remainingErrors;
  }

  return [...imageErrors, ...otherErrors];
};

/**
 * An information notice displayed to users in the Preview window when accessibility improvements could be made to their post.
 * This component displays a maximum of 3 suggestions, favouring image-related suggestions (as these changes are more impactful).
 *
 * @param {Object} props
 * @param {Object[]} props.markdownLintErrors The array of error objects returned from the markdownlint library
 *
 * @example
 * <AccessibilitySuggestions
 *   markdownLintErrors={[
 *     {
 *       errorContext: "Consider adding an image description in the square brackets of the image ![](http://example.png)",
 *       errorDetail: "/p/editor_guide#alt-text-for-images"
 *       ruleNames: ["no-empty-alt-text"]
 *     }
 *   ]}
 * />
 */
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
                  aria-label={`Learn more about accessible ${
                    lintError.errorType === 'image' ? 'images' : 'headings'
                  }`}
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

AccessibilitySuggestions.propTypes = {
  markdownLintErrors: PropTypes.arrayOf(
    PropTypes.shape({
      errorContext: PropTypes.string,
      errorDetail: PropTypes.string,
      ruleNames: PropTypes.arrayOf(PropTypes.string),
    }),
  ),
};
