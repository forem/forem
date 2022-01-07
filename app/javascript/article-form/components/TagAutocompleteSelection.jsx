import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button, Icon } from '@crayons';
import { Close } from '@images/x.svg';

/**
 * Responsible for the layout of a tag autocomplete selected item in the article form
 *
 * @param {string} name The tag name
 * @param {string} bg_color_hex Optional background color hex code
 * @param {Function} onEdit Callback for tag edit click
 * @param {Function} onDeselect Callback for tag deselect click
 */
export const TagAutocompleteSelection = ({
  name,
  bg_color_hex: bgColorHex,
  onEdit,
  onDeselect,
}) => {
  const baseColorStyles = bgColorHex
    ? {
        '--bg': `${bgColorHex}1a`,
        '--bg-hover': `${bgColorHex}1a`,
        '--tag-prefix': bgColorHex,
      }
    : {};
  return (
    <div role="group" aria-label={name} className="flex mr-1 mb-1 w-max">
      <Button
        style={baseColorStyles}
        variant="secondary"
        className="c-autocomplete--multi__selected p-1 cursor-text"
        aria-label={`Edit ${name}`}
        onClick={onEdit}
      >
        <span className="crayons-article-form__tag-prefix"># </span>
        {name}
      </Button>
      <Button
        style={baseColorStyles}
        variant="secondary"
        className="c-autocomplete--multi__selected p-1"
        aria-label={`Remove ${name}`}
        onClick={onDeselect}
      >
        <Icon src={Close} />
      </Button>
    </div>
  );
};

TagAutocompleteSelection.propTypes = {
  name: PropTypes.string.isRequired,
  bg_color_hex: PropTypes.string,
  onEdit: PropTypes.func.isRequired,
  onDeselect: PropTypes.func.isRequired,
};
