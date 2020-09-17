import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../../common-prop-types';

// Only radio and checkboxes require an additional CSS class (variant class). Other form elements do not.

export const FormField = ({ children, variant }) => {
  return (
    <div
      className={`crayons-field${
        variant && variant.length > 0 ? ` crayons-field--${variant}` : ''
      }`}
    >
      {children}
    </div>
  );
};

FormField.displayName = 'FormField';

FormField.defaultProps = {
  variant: undefined,
};

FormField.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  variant: PropTypes.oneOf(['radio', 'checkbox']),
};
