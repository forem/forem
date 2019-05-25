import PropTypes from 'prop-types';
import { h } from 'preact';

const domId = 1;

const Title = ( { onChange, defaultValue }) => (
  <div className="field">
    <label className="listingform__label" htmlFor={domId}>Title</label>
    <input
      type="text"
      className="listingform__input"
      id={domId}
      name="classified_listing[title]"
      maxLength="128"
      size="128"
      placeholder="128 characters max, plain text"
      autoComplete="off"
      value={defaultValue}
      onInput={onChange}
    />
  </div>
)

Title.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
}


export default Title;