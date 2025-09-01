import { h } from 'preact';
import { useRef, useLayoutEffect } from 'preact/hooks';
import PropTypes from 'prop-types';
import { locale } from '@utilities/locale';
// We use this hook for the title field to automatically grow the height of the textarea.
// It helps keep the entire layout the way it is without having unnecessary scrolling and white spaces.
// Keep in mind this is what happens only here - in the Preact component.
// I'm mentioning this because the entire "Create Post" view is a preact component
// BUT it is also a classic .html.erb view which is being loaded BEFORE this component
// to give a feeling of blazing fast page load. And we do NOT use this magic autoresizing
// functionality on .html.erb view because there's no point of it.
import { useTextAreaAutoResize } from '@utilities/textAreaUtils';

export const Title = ({ onChange, defaultValue, switchHelpContext }) => {
  const textAreaRef = useRef(null);
  const { setTextArea, setConstrainToContentHeight } = useTextAreaAutoResize();

  useLayoutEffect(() => {
    if (textAreaRef.current) {
      setConstrainToContentHeight(true);
      setTextArea(textAreaRef.current);
    }
  }, [setTextArea, setConstrainToContentHeight]);

  return (
    <div
      data-testid="article-form__title"
      className="crayons-article-form__title"
    >
      <textarea
        ref={textAreaRef}
        className="crayons-textfield crayons-textfield--ghost fs-3xl m:fs-4xl l:fs-5xl fw-bold s:fw-heavy lh-tight"
        type="text"
        id="article-form-title"
        aria-label="Post Title"
        placeholder={locale('core.editor_new_title')}
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
