import { h } from 'preact';
import PropTypes from 'prop-types';

const Tags = ({ onInput, onKeyDown, defaultValue, options, onFocusChange }) => (
  <div className="articleform__tagswrapper">
    <textarea
      id="tag-input"
      type="text"
      className="articleform__tags"
      placeholder="tags"
      value={defaultValue}
      onInput={onInput}
      onKeyDown={onKeyDown}
      onBlur={onFocusChange}
      onFocus={onFocusChange}
    />
    {options}
  </div>
);

Tags.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
  options: PropTypes.array.isRequired,
};

export default Tags;
