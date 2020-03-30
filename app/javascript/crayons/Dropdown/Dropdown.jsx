import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types/default-children-prop-types';

function getAdditionalCssClasses(className) {
  let classes = '';

  if (className !== null) {
    classes += ` ${className}`;
  }

  return classes;
}

export const Dropdown = ({ children, className }) => {
  const additionalCssClasses = getAdditionalCssClasses(className);

  return (
    <div className={`crayons-dropdown${additionalCssClasses}`}>{children}</div>
  );
};

Dropdown.defaultProps = {
  className: null,
};

Dropdown.displayName = 'Dropdown';

Dropdown.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  className: PropTypes.string,
};
