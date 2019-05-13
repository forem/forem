import { h } from 'preact';
import PropTypes from 'prop-types';

const BodyMarkdown = ({ onChange, defaultValue }) => (
  <div className="field">
    <label className="listingform__label" htmlFor="body_markdown">
      Body Markdown
      <textarea
        className="listingform__input listingform__bodymarkdown"
        id="body_markdown"
        name="classified_listing[body_markdown]"
        maxLength="400"
        placeholder="400 characters max, 12 line break max, no images allowed"
        value={defaultValue}
        onInput={onChange}
      />
    </label>
  </div>
)

BodyMarkdown.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
}

export default BodyMarkdown;
