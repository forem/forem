import { h } from 'preact';
import PropTypes from 'prop-types';
import Textarea from 'preact-textarea-autosize';

const Title = ({ onChange, defaultValue, onKeyDown }) => (
  <Textarea
    className="articleform__title"
    type="text"
    id="article-form-title"
    placeholder="Title"
    autoComplete="off"
    value={defaultValue}
    onInput={onChange}
    onKeyDown={onKeyDown}
  />
);

Title.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
  onKeyDown: PropTypes.func.isRequired,
};

export default Title;
