import { h } from 'preact';
import PropTypes from 'prop-types';

const BodyMarkdown = ({ onChange, onKeyUp, defaultValue }) => (
  <textarea
    className="articleform__body"
    id="article_body_markdown"
    placeholder="Body"
    defaultValue={defaultValue}
    onInput={onChange}
    name="body_markdown"
  />
);

BodyMarkdown.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
};

export default BodyMarkdown;
