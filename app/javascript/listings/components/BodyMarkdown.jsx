import { h } from 'preact';
import PropTypes from 'prop-types';

export const BodyMarkdown = ({ onChange, defaultValue }) => (
  <div className="crayons-field">
    <label className="crayons-field__label" htmlFor="body_markdown">
      Body Markdown
    </label>
    <textarea
      className="crayons-textfield"
      id="body_markdown"
      name="listing[body_markdown]"
      maxLength="400"
      placeholder="..."
      value={defaultValue}
      onInput={onChange}
    />
    <p className="crayons-field__description">
      400 characters max, 12 line break max, no images allowed, *markdown is
      encouraged*
    </p>
  </div>
);

BodyMarkdown.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
};
