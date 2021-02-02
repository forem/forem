import PropTypes from 'prop-types';
import { h } from 'preact';

const domId = 1;

export const Title = ({ onChange, defaultValue }) => (
  <div className="crayons-field">
    <label className="crayons-field__label" htmlFor={domId}>
      Title
    </label>
    <input
      type="text"
      className="crayons-textfield"
      id={domId}
      name="listing[title]"
      maxLength="128"
      size="128"
      placeholder="128 characters max, plain text"
      autoComplete="off"
      value={defaultValue}
      onInput={onChange}
    />
  </div>
);

Title.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
};
