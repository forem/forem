import { h } from 'preact';
import PropTypes from 'prop-types';

const Description = ({ onChange, defaultValue }) => (
  <textarea
    className="articleform__description"
    type="text"
    placeholder="description"
    name="description"
    value={defaultValue}
    onChange={onChange}
  />
);

Description.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
};

export default Description;
