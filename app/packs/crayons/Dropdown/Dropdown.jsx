import { h } from 'preact';
import { useLayoutEffect, useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../common-prop-types/default-children-prop-types';
import { initializeDropdown } from '@utilities/dropdownUtils';

/**
 * A component to render a dropdown with the provided children.
 * This component handles the attachment of all open/close click events and listeners.
 *
 * @param {Object} props
 * @param {Array} props.children Children to be rendered inside the dropdown, passed via composition
 * @param {String} props.className Optional string of classnames to be applied to the dropdown (e.g for positioning)
 * @param {String} props.triggerButtonId The ID of the button element which should open and close the dropdown
 * @param {String} props.dropdownContentId The ID to be applied to the dropdown itself
 * @param {String} props.dropdownContentCloseButtonId An optional ID for any button inside the dropdown content itself which should close it
 * @param {Function} props.onOpen Optional callback for any side-effects needed when the dropdown opens
 * @param {Function} props.onClose Optional callback for any side-effects needed when the dropdown closes
 *
 * @example
 * <div>
 *   <button id="toggle-dropdown-button">Toggle dropdown</button>
 *   <Dropdown
 *     className="right-4 left-4"
 *     triggerButtonId="toggle-dropdown-button"
 *     dropdownContentId="dropdown-content"
 *   >
 *     {dropdownInnerContent}
 *   </Dropdown>
 * </div>
 */
export const Dropdown = ({
  children,
  className,
  triggerButtonId,
  dropdownContentId,
  dropdownContentCloseButtonId,
  onOpen = () => {},
  onClose = () => {},
  ...restOfProps
}) => {
  const [isInitialized, setIsInitialized] = useState(false);
  useLayoutEffect(() => {
    if (!isInitialized) {
      initializeDropdown({
        triggerElementId: triggerButtonId,
        dropdownContentId,
        dropdownContentCloseButtonId,
        onOpen,
        onClose,
      });

      setIsInitialized(true);
    }
  }, [
    dropdownContentId,
    triggerButtonId,
    dropdownContentCloseButtonId,
    isInitialized,
    onOpen,
    onClose,
  ]);

  return (
    <div
      id={dropdownContentId}
      className={`crayons-dropdown${
        className && className.length > 0 ? ` ${className}` : ''
      }`}
      {...restOfProps}
    >
      {children}
    </div>
  );
};

Dropdown.defaultProps = {
  className: undefined,
};

Dropdown.displayName = 'Dropdown';

Dropdown.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  className: PropTypes.string,
  triggerButtonId: PropTypes.string.isRequired,
  dropdownContentId: PropTypes.string.isRequired,
  dropdownContentCloseButtonId: PropTypes.string,
  onOpen: PropTypes.func,
  onClose: PropTypes.func,
};
