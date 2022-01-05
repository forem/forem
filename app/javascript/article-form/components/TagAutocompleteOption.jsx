import { h } from 'preact';
import PropTypes from 'prop-types';

/**
 * Responsible for the layout of a tag "suggestion" in the article form
 *
 * @param {string} name The tag name
 * @param {string} backgroundColor Optional hex code for tag
 * @param {string} shortSummary Optional short summary of the tag
 * @param {string} badgeUrl Optional src for the tag's badge
 */
export const TagAutocompleteOption = ({
  name,
  backgroundColor,
  shortSummary,
  badgeUrl,
}) => {
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
  backgroundColor: PropTypes.string,
  shortSummary: PropTypes.string,
  badgeUrl: PropTypes.string,
};
