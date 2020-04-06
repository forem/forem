import { h } from 'preact';
import PropTypes from 'prop-types';

export const RadioButton = ({ id, value, className, checked }) => {
  return (
    <input
      id={id}
      value={value}
      className={`crayons-radio${
        className && className.length > 0 ? ` ${className}` : ''
      }`}
      checked={checked}
      type="radio"
    />
  );
};

RadioButton.displayName = 'RadioButton';

RadioButton.defaultProps = {
  id: undefined,
  className: undefined,
  checked: false,
};

RadioButton.propTypes = {
  id: PropTypes.string,
  value: PropTypes.string.isRequired,
  className: PropTypes.string,
  checked: PropTypes.bool,
};
