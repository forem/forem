import { h } from 'preact';
import PropTypes from 'prop-types';

/**
 * Responsible for the layout of a tag "suggestion" in the article form
 *
 * @param {string} name The tag name
 * @param {string} bg_color_hex Optional hex code for tag
 * @param {string} short_summary Optional short summary of the tag
 * @param {string} badge Optional object containing badge details
 */
export const TagAutocompleteOption = ({
  name,
  bg_color_hex: backgroundColor,
  short_summary: shortSummary,
  badge,
}) => {
  const badgeUrl = badge?.['badge_image']?.url;

  return (
    <div
      className="crayons-article-form__tag-option"
      style={{ '--tag-prefix': backgroundColor }}
    >
      <div className="crayons-article-form__tag-option-title flex items-center">
        <span className="crayons-tag__prefix"># </span>
        <span className="crayons-article-form__tag-option-name overflow-hidden">
          {name}
        </span>
        {badgeUrl ? (
          <img
            className="crayons-article-form__tag-option-image"
            src={badgeUrl}
            alt=""
          />
        ) : null}
      </div>
      <span className="truncate-at-2 fs-s">{shortSummary}</span>
    </div>
  );
};

TagAutocompleteOption.propTypes = {
  name: PropTypes.string.isRequired,
  background_color_hex: PropTypes.string,
  short_summary: PropTypes.string,
  badge: PropTypes.shape({
    badge_image: PropTypes.shape({ url: PropTypes.string }),
  }),
};
