import { h } from 'preact';
import PropTypes from 'prop-types';

const Title = ({ onChange, defaultValue }) => (
  <input
    className="articleform__title"
    type="text"
    id="article-form-title"
    placeholder="title"
    autocomplete="off"
    value={defaultValue}
    onChange={onChange}
  />
);

Title.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
};

export default Title;
