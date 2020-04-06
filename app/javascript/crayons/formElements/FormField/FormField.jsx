import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../../src/components/common-prop-types';

export const FormField = ({ children, variant }) => {
  return (
    <div className={`crayons-field crayons-field--${variant}`}>{children}</div>
  );
};

FormField.displayName = 'FormField';

FormField.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  variant: PropTypes.oneOf(['radio', 'checkbox']).isRequired,
};
