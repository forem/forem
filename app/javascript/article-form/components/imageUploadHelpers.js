import { handleImageFailure } from './dragAndDropHelpers';

// Placeholder text displayed while an image is uploading
const UPLOADING_IMAGE_PLACEHOLDER = '![Uploading image](...)';

/**
 * Handles image uploading by showing UPLOADING_IMAGE_PLACEHOLDER text.
 *
 * @param {useRef} textAreaRef The reference of the text area with content.
 */
export function handleImageUploading(textAreaRef) {
  return function () {
    // Function is within the component to be able to access
    // textarea ref.
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
}

/**
 * Handles image upload successfully by replacing UPLOADING_IMAGE_PLACEHOLDER with image link.
 *
 * @param {useRef} textAreaRef The reference of the text area with content.
 */
export function handleImageUploadSuccess(textAreaRef) {
  return function (response) {
    // Function is within the component to be able to access
    // textarea ref.
    const editableBodyElement = textAreaRef.current;
    const { links } = response;

    const markdownImageLink = `![Image description](${links[0]})\n`;
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

    // Dispatching a new event so that linkstate, https://github.com/developit/linkstate,
    // the function used to create the onChange prop gets called correctly.
    editableBodyElement.dispatchEvent(new Event('input'));
  };
}

/**
 * Handles image upload failure by removing UPLOADING_IMAGE_PLACEHOLDER text and showing error.
 *
 * @param {useRef} textAreaRef The reference of the text area with content.
 */
export function handleImageUploadFailure(textAreaRef) {
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
}
