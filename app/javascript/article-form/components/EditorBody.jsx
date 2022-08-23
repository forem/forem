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
import { AutocompleteTriggerTextArea } from '@crayons/AutocompleteTriggerTextArea';

// Placeholder text displayed while an image is uploading
const UPLOADING_IMAGE_PLACEHOLDER = '![Uploading image](...)';

const handleImageUploading = (textAreaRef) => {
  return function () {
    // Function is within the component to be able to access
    // textarea ref.

    // Update this case:
    // If a string is selected, then the markdownImageLink should be added at the end of that selection
    // and selection should be removed.
    const editableBodyElement = textAreaRef.current;

    const { selectionStart, selectionEnd, value } = editableBodyElement;
    const before = value.substring(0, selectionStart);
    const after = value.substring(selectionEnd, value.length);
    const newSelectionStart = `${before}\n${UPLOADING_IMAGE_PLACEHOLDER}`
      .length;

    editableBodyElement.value = `${before}\n${UPLOADING_IMAGE_PLACEHOLDER}\n${after}`;
    editableBodyElement.selectionStart = newSelectionStart;
    editableBodyElement.selectionEnd = newSelectionStart;
  };
};

const handleImageSuccess = (textAreaRef) => {
  return function (response) {
    // Function is within the component to be able to access
    // textarea ref.
    const editableBodyElement = textAreaRef.current;
    const { links } = response;

    const markdownImageLink = `![Image description](${links[0]})`;
    const { selectionStart, selectionEnd, value } = editableBodyElement;
    if (value.includes(UPLOADING_IMAGE_PLACEHOLDER)) {
      const newSelectedStart =
        value.indexOf(UPLOADING_IMAGE_PLACEHOLDER, 0) +
        markdownImageLink.length;

      editableBodyElement.value = value.replace(
        UPLOADING_IMAGE_PLACEHOLDER,
        markdownImageLink,
      );
      editableBodyElement.selectionStart = newSelectedStart;
      editableBodyElement.selectionEnd = newSelectedStart;
    } else {
      const before = value.substring(0, selectionStart);
      const after = value.substring(selectionEnd, value.length);

      editableBodyElement.value = `${before}\n${markdownImageLink}\n${after}`;
      editableBodyElement.selectionStart =
        selectionStart + markdownImageLink.length;
      editableBodyElement.selectionEnd = editableBodyElement.selectionStart;
    }
  };
};

const handleImageUploadFailure = (textAreaRef) => {
  return function (message) {
    // Function is within the component to be able to access
    // textarea ref.
    handleImageFailure(message);
    const editableBodyElement = textAreaRef.current;

    const { value } = editableBodyElement;
    if (value.includes(`\n${UPLOADING_IMAGE_PLACEHOLDER}\n`)) {
      const newSelectionStart = value.indexOf(
        `\n${UPLOADING_IMAGE_PLACEHOLDER}\n`,
        0,
      );

      editableBodyElement.value = value.replace(
        `\n${UPLOADING_IMAGE_PLACEHOLDER}\n`,
        '',
      );
      editableBodyElement.selectionStart = newSelectionStart;
      editableBodyElement.selectionEnd = newSelectionStart;
    }
  };
};

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
      handleImageSuccess(textAreaRef),
      handleImageUploadFailure(textAreaRef),
    ),
    onDragOver,
    onDragExit,
  });

  const setPasteElement = usePasteImage({
    onPaste: handleImagePasted(
      handleImageUploading(textAreaRef),
      handleImageSuccess(textAreaRef),
      handleImageUploadFailure(textAreaRef),
    ),
  });

  useLayoutEffect(() => {
    if (textAreaRef.current) {
      setElement(textAreaRef.current);
      setPasteElement(textAreaRef.current);
    }
  });

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
        placeholder="Write your post content here..."
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
