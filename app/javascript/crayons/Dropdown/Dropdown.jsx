import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types/default-children-prop-types';

export const Dropdown = ({ children, className }) => {
  return (
    <div
      className={`crayons-dropdown${
        className && className.length > 0 ? ` ${className}` : ''
      }`}
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
