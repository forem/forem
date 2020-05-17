import { h } from 'preact';
import PropTypes from 'prop-types';

const BodyMarkdown = ({ onChange, defaultValue }) => (
  <textarea
    className="articleform__body"
    id="article_body_markdown"
    placeholder="Body Markdown"
    value={defaultValue}
    onInput={onChange}
    name="body_markdown"
  />
);

BodyMarkdown.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
};

export default BodyMarkdown;
