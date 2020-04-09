import { h } from 'preact';
import PropTypes from 'prop-types';

export const RadioButton = ({
  id,
  value,
  name,
  className,
  checked,
  onClick,
}) => {
  return (
    <input
      id={id}
      value={value}
      name={name}
      className={`crayons-radio${
        className && className.length > 0 ? ` ${className}` : ''
      }`}
      checked={checked}
      onClick={onClick}
      type="radio"
    />
  );
};

RadioButton.displayName = 'RadioButton';

RadioButton.defaultProps = {
  id: undefined,
  className: undefined,
  checked: false,
  name: undefined,
};

RadioButton.propTypes = {
  id: PropTypes.string,
  value: PropTypes.string.isRequired,
  className: PropTypes.string,
  checked: PropTypes.bool,
  name: PropTypes.string,
  onClick: PropTypes.func.isRequired,
};
