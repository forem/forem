import { h } from 'preact';
import PropTypes from 'prop-types';
import { useEffect, useLayoutEffect, useRef } from 'preact/hooks';
import { locale } from '@utilities/locale';
import { Toolbar } from './Toolbar';
import { handleImagePasted } from './pasteImageHelpers';
import { handleURLPasted } from './pasteURLHelpers';
import {
  handleImageUploadSuccess,
  handleImageUploading,
  handleImageUploadFailure,
} from './imageUploadHelpers';
import { handleImageDrop, onDragOver, onDragExit } from './dragAndDropHelpers';
import { usePasteImage } from '@utilities/pasteImage';
import { useDragAndDrop } from '@utilities/dragAndDrop';
import { fetchSearch } from '@utilities/search';
import { AutocompleteTriggerTextArea } from '@crayons/AutocompleteTriggerTextArea';

export const EditorBody = ({
  onChange,
  defaultValue,
  switchHelpContext,
  version,
}) => {
  const textAreaRef = useRef(null);

  const { setElement } = useDragAndDrop({
    onDrop: handleImageDrop(
      handleImageUploading(textAreaRef),
      handleImageUploadSuccess(textAreaRef),
      handleImageUploadFailure(textAreaRef),
    ),
    onDragOver,
    onDragExit,
  });

  const setPasteElement = usePasteImage({
    onPaste: handleImagePasted(
      handleImageUploading(textAreaRef),
      handleImageUploadSuccess(textAreaRef),
      handleImageUploadFailure(textAreaRef),
    ),
  });

  useLayoutEffect(() => {
    if (textAreaRef.current) {
      setElement(textAreaRef.current);
      setPasteElement(textAreaRef.current);
    }
  }, [setElement, setPasteElement]);

  // If it's a URL, embed as a URL. Otherwise paste as plain text
  useEffect(() => {
    // Make sure we are in the editor
    const textarea = textAreaRef.current;
    if (!textarea) return;

    const urlHandler = handleURLPasted(textAreaRef);

    // Handle text that were pasted onto the editor
    const onPaste = (e) => {

      // Get the clipboard data
      const dt = e.clipboardData || window.clipboardData;
      const pastedText = dt?.getData?.('text/plain') ?? '';

      if (!pastedText) return; // If no text, do not proceed

      const trimmed = pastedText.trim();

      // If it's a URL, treat it as a URL
      const isProbablyURL = /^(https?:\/\/|www\.)\S+$/i.test(trimmed);
      if (isProbablyURL) {
        urlHandler(e);
        return;
      }

      // Otherwise, paste as plain text, but neutralize '@' so it won't trigger mentions
      // Insert a zero-width space right after '@'
      const neutralized = pastedText.replace(/@/g, '@\u200B');
      
      e.preventDefault();

      // get the cursor index from start to end
      const el = textarea;
      const start = el.selectionStart;
      const end = el.selectionEnd;

      if (typeof el.setRangeText === 'function') {
        el.setRangeText(neutralized, start, end, 'end'); // move to end of inserted text
      } else {
        // Fallback for very old browsers
        const before = el.value.slice(0, start);
        const after = el.value.slice(end);
        el.value = before + neutralized + after;
        el.selectionStart = el.selectionEnd = (before + neutralized).length;
      }

      el.dispatchEvent(new Event('input', { bubbles: true }));
    };

    textarea.addEventListener('paste', onPaste);
    return () => textarea.removeEventListener('paste', onPaste);
  }, []);

  return (
    <div
      data-testid="article-form__body"
      className="crayons-article-form__body drop-area text-padding"
    >
      <Toolbar version={version} textAreaId="article_body_markdown" />
      <AutocompleteTriggerTextArea
        triggerCharacter="@"
        maxSuggestions={6}
        searchInstructionsMessage="Type to search for a user"
        ref={textAreaRef}
        fetchSuggestions={(username) =>
          fetchSearch('usernames', { username }).then(({ result }) =>
            result.map((user) => ({ ...user, value: user.username })),
          )
        }
        autoResize
        onChange={onChange}
        onFocus={switchHelpContext}
        aria-label="Post Content"
        name="body_markdown"
        id="article_body_markdown"
        defaultValue={defaultValue}
        placeholder={locale('core.editor_body_placeholder')}
        className="crayons-textfield crayons-textfield--ghost crayons-article-form__body__field ff-monospace fs-l h-100"
      />
    </div>
  );
};

EditorBody.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
  switchHelpContext: PropTypes.func.isRequired,
  version: PropTypes.string.isRequired,
};

EditorBody.displayName = 'EditorBody';