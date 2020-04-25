import { h } from 'preact';
import PropTypes from 'prop-types';
import Textarea from 'preact-textarea-autosize';

export const Title = ({ onChange, defaultValue, onKeyDown }) => (
  <div className="crayons-article-form__title">
    <Textarea
      className="crayons-textfield crayons-textfield--ghost fs-4xl l:fs-5xl fw-bold s:fw-heavy lh-tight"
      type="text"
      id="article-form-title"
      placeholder="New post title here..."
      autoComplete="off"
      value={defaultValue}
      onInput={onChange}
      onKeyDown={onKeyDown}
    />
  </div>
);

Title.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
  onKeyDown: PropTypes.func.isRequired,
};

Title.displayName = 'Title';
