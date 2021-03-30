import { useEffect, useState } from 'preact/hooks';
import { calculateTextAreaHeight } from '@utilities/calculateTextAreaHeight';

/**
 * A helper function to get the X/Y coordinates of the current cursor position within an element.
 * For a full explanation see the post by Jhey Tompkins: https://medium.com/@jh3y/how-to-where-s-the-caret-getting-the-xy-position-of-the-caret-a24ba372990a
 *
 * @param {element} input The DOM element the cursor is to be found within
 * @param {number} selectionPoint The current cursor position (e.g. either selectionStart or selectionEnd)
 *
 * @returns {object} An object with x and y properties (e.g. {x: 10, y: 0})
 *
 * @example
 * const coordinates = getCursorXY(elementRef.current, elementRef.current.selectionStart)
 */
export const getCursorXY = (input, selectionPoint) => {
  const bodyRect = document.body.getBoundingClientRect();
  const elementRect = input.getBoundingClientRect();

  const inputY = elementRect.top - bodyRect.top;
  const inputX = elementRect.left - bodyRect.left;

  // create a dummy element with the computed style of the input
  const div = document.createElement('div');
  const copyStyle = getComputedStyle(input);
  for (const prop of copyStyle) {
    div.style[prop] = copyStyle[prop];
  }

  // set the div to the correct position
  div.style['position'] = 'absolute';
  div.style['top'] = `${inputY}px`;
  div.style['left'] = `${inputX}px`;
  div.style['opacity'] = 0;

  // replace whitespace with '.' when filling the dummy element if it's a single line <input/>
  const swap = '.';
  const inputValue =
    input.tagName === 'INPUT' ? input.value.replace(/ /g, swap) : input.value;

  // set the div content to that of the textarea up until selection point
  div.textContent = inputValue.substr(0, selectionPoint);

  if (input.tagName === 'TEXTAREA') div.style.height = 'auto';
  // if a single line input then the div needs to be single line and not break out like a text area
  if (input.tagName === 'INPUT') div.style.width = 'auto';

  // marker element to obtain caret position
  const span = document.createElement('span');
  // give the span the textContent of remaining content so that the recreated dummy element is as close as possible
  span.textContent = inputValue.substr(selectionPoint) || '.';

  // append the span marker to the div and the dummy element to the body
  div.appendChild(span);
  document.body.appendChild(div);

  // get the marker position, this is the caret position top and left relative to the input
  const { offsetLeft: spanX, offsetTop: spanY } = span;

  // remove dummy element
  document.body.removeChild(div);

  // return object with the x and y of the caret. account for input positioning so that you don't need to wrap the input
  return {
    x: inputX + spanX,
    y: inputY + spanY,
  };
};

/**
 * A helper function that searches back to the beginning of the currently typed word (indicated by cursor position) and verifies whether it begins with an '@' symbol for user mention
 *
 * @param {element} textArea The text area or input to inspect the current word of
 * @returns {{isUserMention: boolean, indexOfMentionStart: number}} Object with the word's mention data
 *
 * @example
 * const { isUserMention, indexOfMentionStart } = getMentionWordData(textArea);
 * if (isUserMention) {
 *  // Do something
 * }
 */
export const getMentionWordData = (textArea) => {
  const { selectionStart, value: valueBeforeKeystroke } = textArea;

  if (selectionStart === 0 || valueBeforeKeystroke === '') {
    return {
      isUserMention: false,
      indexOfMentionStart: -1,
    };
  }

  const indexOfAutocompleteStart = getIndexOfCurrentWordAutocompleteSymbol(
    valueBeforeKeystroke,
    selectionStart,
  );

  return {
    isUserMention: indexOfAutocompleteStart !== -1,
    indexOfMentionStart: indexOfAutocompleteStart,
  };
};

const getIndexOfCurrentWordAutocompleteSymbol = (content, selectionIndex) => {
  const currentCharacter = content.charAt(selectionIndex);
  const previousCharacter = content.charAt(selectionIndex - 1);

  if (selectionIndex !== 0 && ![' ', '', '\n'].includes(previousCharacter)) {
    return getIndexOfCurrentWordAutocompleteSymbol(content, selectionIndex - 1);
  }

  if (currentCharacter === '@') {
    return selectionIndex;
  }

  return -1;
};

/**
 * This hook can be used to keep the height of a textarea in step with the current content height, avoiding a scrolling textarea.
 * An optional array of additional elements can be set. If provided, all additional elements will receive the same height.
 *
 * @example
 *
 * const { setTextArea } = useTextAreaAutoResize();
 * setTextArea(myTextAreaRef.current);
 * setAdditionalElements([myOtherElement.current]);
 */
export const useTextAreaAutoResize = () => {
  const [textArea, setTextArea] = useState(null);
  const [additionalElements, setAdditionalElements] = useState([]);

  useEffect(() => {
    if (!textArea) {
      return;
    }

    const resizeTextArea = () => {
      const { height } = calculateTextAreaHeight(textArea);
      const newHeight = `${height}px`;
      textArea.style['min-height'] = newHeight;
      additionalElements.forEach((element) => {
        element.style['min-height'] = newHeight;
      });
    };

    // Resize on first attach
    resizeTextArea();
    // Resize on subsequent value changes
    textArea.addEventListener('input', resizeTextArea);

    return () => textArea.removeEventListener('input', resizeTextArea);
  }, [textArea, additionalElements]);

  return { setTextArea, setAdditionalElements };
};
