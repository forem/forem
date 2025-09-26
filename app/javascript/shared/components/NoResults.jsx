import { h } from 'preact';
import PropTypes from 'prop-types';
import { locale } from '../../utilities/locale';

/**
 * A reusable component for displaying no results/empty states
 * Follows the existing design patterns used throughout the app
 */
export const NoResults = ({ 
  feedType = 'default',
  title = null, 
  description = null,
  actionText = null,
  actionHref = null,
  className = ""
}) => {
  // Get i18n keys based on feed type
  const getI18nKey = (key) => `views.stories.feed.no_results.${feedType}.${key}`;
  
  // Use provided props or fall back to i18n
  const displayTitle = title || locale(getI18nKey('title'));
  const displayDescription = description || locale(getI18nKey('description'));
  const displayActionText = actionText || locale(getI18nKey('action_text'));
  const displayActionHref = actionHref || locale(getI18nKey('action_href'));

  return (
    <div className={`p-6 m:p-9 crayons-card crayons-card--secondary align-center fs-l h-100 flex items-center justify-center flex-1 mt-4 ${className}`}>
      <div className="text-center">
        <h2 className="crayons-subtitle-2 mb-2 color-base-80">
          {displayTitle}
        </h2>
        <p className="color-base-60 mb-6">
          {displayDescription}
        </p>
        {displayActionText && displayActionHref && (
          <p>
            <a href={displayActionHref} className="crayons-btn crayons-btn--l" data-no-instant>
              {displayActionText}
            </a>
          </p>
        )}
      </div>
    </div>
  );
};

NoResults.propTypes = {
  feedType: PropTypes.oneOf(['discover', 'following', 'default']),
  title: PropTypes.string,
  description: PropTypes.string,
  actionText: PropTypes.string,
  actionHref: PropTypes.string,
  className: PropTypes.string,
};

NoResults.displayName = 'NoResults';
