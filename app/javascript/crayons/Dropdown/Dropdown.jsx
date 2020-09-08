import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../common-prop-types/default-children-prop-types';

export const Dropdown = (props) => {
  const { children, className, ...restOfProps } = props;
  return (
    <div
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
