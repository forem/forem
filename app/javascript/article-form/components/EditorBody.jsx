import { h } from 'preact';
import PropTypes from 'prop-types';
import { useLayoutEffect, useRef } from 'preact/hooks';
import { Toolbar } from './Toolbar';
import { handleImagePasted } from './pasteImageHelpers';
import {
  handleImageDrop,
  handleImageFailure,
  onDragOver,
  onDragExit,
} from './dragAndDropHelpers';
import { usePasteImage } from '@utilities/pasteImage';
import { useDragAndDrop } from '@utilities/dragAndDrop';
import { fetchSearch } from '@utilities/search';
import { useTextAreaAutoResize } from '@utilities/textAreaUtils';
import { MentionAutocompleteTextArea } from '@crayons/MentionAutocompleteTextArea';

function handleImageSuccess(textAreaRef) {
  return function (response) {
    // Function is within the component to be able to access
    // textarea ref.
    const editableBodyElement = textAreaRef.current;
    const { links, image } = response;
    const altText = image[0]
      ? image[0].name.replace(/\.[^.]+$/, '')
      : 'alt text';
    const markdownImageLink = `![${altText}](${links[0]})\n`;
    const { selectionStart, selectionEnd, value } = editableBodyElement;
    const before = value.substring(0, selectionStart);
    const after = value.substring(selectionEnd, value.length);

    editableBodyElement.value = `${before + markdownImageLink} ${after}`;
    editableBodyElement.selectionStart =
      selectionStart + markdownImageLink.length;
    editableBodyElement.selectionEnd = editableBodyElement.selectionStart;

    // Dispatching a new event so that linkstate, https://github.com/developit/linkstate,
    // the function used to create the onChange prop gets called correctly.
    editableBodyElement.dispatchEvent(new Event('input'));
  };
}

export const EditorBody = ({
  onChange,
  defaultValue,
  switchHelpContext,
  version,
}) => {
  const textAreaRef = useRef(null);

  const { setElement } = useDragAndDrop({
    onDrop: handleImageDrop(
      handleImageSuccess(textAreaRef),
      handleImageFailure,
    ),
    onDragOver,
    onDragExit,
  });

  const setPasteElement = usePasteImage({
    onPaste: handleImagePasted(
      handleImageSuccess(textAreaRef),
      handleImageFailure,
    ),
  });

  const { setTextArea } = useTextAreaAutoResize();

  useLayoutEffect(() => {
    if (textAreaRef.current) {
      setElement(textAreaRef.current);
      setPasteElement(textAreaRef.current);
      setTextArea(textAreaRef.current);
    }
  });

  return (
    <div
      data-testid="article-form__body"
      className="crayons-article-form__body drop-area text-padding"
    >
      <Toolbar version={version} />
      <MentionAutocompleteTextArea
        ref={textAreaRef}
        fetchSuggestions={(username) => fetchSearch('usernames', { username })}
        inputProps={{
          onChange,
          onFocus: switchHelpContext,
          'aria-label': 'Post Content',
          name: 'body_markdown',
          defaultValue,
          placeholder: 'Write your post content here...',
          id: 'article_body_markdown',
          className:
            'crayons-textfield crayons-textfield--ghost crayons-article-form__body__field ff-monospace fs-l',
        }}
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
