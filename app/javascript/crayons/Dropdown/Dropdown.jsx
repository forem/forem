import { h } from 'preact';
import { useLayoutEffect, useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../common-prop-types/default-children-prop-types';
import { initializeDropdown } from '@utilities/dropdownUtils';

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
};
