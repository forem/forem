import { h } from 'preact';
import PropTypes from 'prop-types';
import { Icon, ButtonNew as Button } from '@crayons';
import { Close } from '@images/x.svg';

/**
 * Responsible for the layout of a selected item in the crayons autocomplete and multi input components
 *
 * @param {string} name The selected item name
 * @param {string} buttonVariant Optional button variant
 * @param {string} className Optional classname for selected item
 * @param {Function} onEdit Callback for edit click on the name of the selected item
 * @param {Function} onDeselect Callback for deselect click on the close icon
 */
export const DefaultSelectionTemplate = ({
  name,
  enableValidation = false,
  valid = true,
  buttonVariant = 'default',
  className = 'c-autocomplete--multi__selected',
  onEdit,
  onDeselect,
}) => {
  const conditionalAttributes = () => {
    if (enableValidation) {
      return { 'aria-describedby': `invalid-item-${name}` };
    }
    return {};
  };

  return (
    <>
      {enableValidation && (
        <div
          id={`invalid-item-${name}`}
          className="screen-reader-only"
          aria-live="assertive"
        >
          {!valid ? 'Invalid entry' : ''}
        </div>
      )}
      <div role="group" aria-label={name} className="flex mr-1 mb-1 w-max">
        <Button
          variant={buttonVariant}
          className={`${className} p-1 cursor-text`}
          aria-label={`Edit ${name}`}
          {...conditionalAttributes()}
          onClick={onEdit}
        >
          {name}
        </Button>
        <Button
          variant={buttonVariant}
          className={`${className} p-1`}
          aria-label={`Remove ${name}`}
          onClick={onDeselect}
        >
          <Icon src={Close} />
        </Button>
      </div>
    </>
  );
};

DefaultSelectionTemplate.propTypes = {
  name: PropTypes.string.isRequired,
  buttonVariant: PropTypes.string,
  className: PropTypes.string,
  onEdit: PropTypes.func.isRequired,
  onDeselect: PropTypes.func.isRequired,
};
