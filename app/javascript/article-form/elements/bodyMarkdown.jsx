import { h } from 'preact';
import PropTypes from 'prop-types';
import Textarea from 'preact-textarea-autosize';

const BodyMarkdown = ({ onChange, onKeyUp, defaultValue }) => (
  <Textarea
    className="articleform__body"
    id="article_body_markdown"
    placeholder="Body"
    value={defaultValue}
    onChange={onChange}
    name="body_markdown"
  />
);

BodyMarkdown.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
};

export default BodyMarkdown;
