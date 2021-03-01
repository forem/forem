import { h } from 'preact';
import PropTypes from 'prop-types';
// We use this magic Textarea component for title field because it's automatically
// resizable. Even though it looks like a classic input, if you enter long title
// it would wrap the text to the next line automatically resizing itself. It helps keep
// the entire layout the way it is without having unnecessary scrolling and white spaces.
// Keep in mind this is what happens only here - in preact component.
// I'm mentioning this because the entire "Write a post" view is a preact component
// BUT it is also a classic .html.erb view which is being loaded BEFORE this component
// to give a feeling of blazing fast page load. And we do NOT use this magic autoresizing
// functionality on .html.erb view because there's no point of it.
import Textarea from 'preact-textarea-autosize';

export const Title = ({ onChange, defaultValue, switchHelpContext }) => {
  return (
    <div
      data-testid="article-form__title"
      className="crayons-article-form__title"
    >
      <Textarea
        className="crayons-textfield crayons-textfield--ghost fs-3xl m:fs-4xl l:fs-5xl fw-bold s:fw-heavy lh-tight"
        type="text"
        id="article-form-title"
        aria-label="Post Title"
        placeholder="New post title here..."
        autoComplete="off"
        value={defaultValue}
        onFocus={switchHelpContext}
        onInput={onChange}
        autofocus="true"
        onKeyDown={(e) => {
          if (e.keyCode === 13) {
            e.preventDefault();
          }
        }}
      />
    </div>
  );
};

Title.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
  switchHelpContext: PropTypes.func.isRequired,
};

Title.displayName = 'Title';
