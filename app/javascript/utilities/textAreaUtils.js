import { useLayoutEffect, useRef, useState } from 'preact/hooks';
import { calculateTextAreaHeight } from '@utilities/calculateTextAreaHeight';
import { debounceAction } from '@utilities/debounceAction';

/**
 * A helper function to get the X/Y coordinates of the current cursor position within an element.
 * For a full explanation see the post by Jhey Tompkins: https://medium.com/@jh3y/how-to-where-s-the-caret-getting-the-xy-position-of-the-caret-a24ba372990a
 *
 * @param {args}
 * @param {args.element} input The DOM element the cursor is to be found within
 * @param {args.number} selectionPoint The current cursor position (e.g. either selectionStart or selectionEnd)
 * @param {args.element} relativeToElement The DOM element the position to be calculated relative to. Defaults to the document body
 *
 * @returns {object} An object with x and y properties (e.g. {x: 10, y: 0})
 *
 * @example
 * const coordinates = getCursorXY(elementRef.current, elementRef.current.selectionStart)
 */
export const getCursorXY = ({
  input,
  selectionPoint,
  relativeToElement = document.body,
}) => {
  const bodyRect = relativeToElement.getBoundingClientRect();
  const elementRect = input.getBoundingClientRect();

  const inputY = elementRect.top - bodyRect.top - input.scrollTop;
  const inputX = elementRect.left - bodyRect.left - input.scrollLeft;

  // create a dummy element with the computed style of the input
  const div = document.createElement('div');
  const copyStyle = getComputedStyle(input);

  for (const property of Object.values(copyStyle)) {
    div.style.setProperty(property, copyStyle.getPropertyValue(property));
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
  relativeToElement.appendChild(div);

  // get the marker position, this is the caret position top and left relative to the input
  const { offsetLeft: spanX, offsetTop: spanY } = span;

  // remove dummy element
  relativeToElement.removeChild(div);

  // return object with the x and y of the caret. account for input positioning so that you don't need to wrap the input
  return {
    x: inputX + spanX,
    y: inputY + spanY,
  };
};

// TODO: Remove once MentionAutocompleteTextArea removed
export const getMentionWordData = () => { };

/**
 * A helper function that searches back to the beginning of the currently typed word (indicated by cursor position) and verifies whether it begins with an '@' symbol for user mention
 *
 * @param {element} textArea The text area or input to inspect the current word of
 * @returns {{isTriggered: boolean, indexOfAutocompleteStart: number}} Object with the word's autocomplete data
 *
 * @example
 * const { isTriggered, indexOfAutocompleteStart } = getAutocompleteWordData({textArea, triggerCharacter: '@'});
 * if (isTriggered) {
 *  // Do something
 * }
 */
export const getAutocompleteWordData = ({ textArea, triggerCharacter }) => {
  const { selectionStart, value: valueBeforeKeystroke } = textArea;

  if (selectionStart === 0 || valueBeforeKeystroke === '') {
    return {
      isTriggered: false,
      indexOfAutocompleteStart: -1,
    };
  }

  const indexOfAutocompleteStart = getLastIndexOfCharacter({
    content: valueBeforeKeystroke,
    selectionIndex: selectionStart,
    character: triggerCharacter,
    breakOnCharacters: [' ', '', '\n'],
  });

  return {
    isTriggered: indexOfAutocompleteStart !== -1,
    indexOfAutocompleteStart,
  };
};

/**
 * Searches backwards through text content for the last occurrence of the given character
 *
 * @param {Object} params
 * @param {string} content The chunk of text to search within
 * @param {number} selectionIndex The starting point to search from
 * @param {string} character The character to search for
 * @param {string[]} breakOnCharacters Any characters which should result in an immediate halt to the search
 * @returns {number} Index of the last occurrence of the character, or -1 if it isn't found
 */
export const getLastIndexOfCharacter = ({
  content,
  selectionIndex,
  character,
  breakOnCharacters = [],
}) => {
  const currentCharacter = content.charAt(selectionIndex);
  const previousCharacter = content.charAt(selectionIndex - 1);

  if (currentCharacter === character) {
    return selectionIndex;
  }

  if (selectionIndex !== 0 && !breakOnCharacters.includes(previousCharacter)) {
    return getLastIndexOfCharacter({
      content,
      selectionIndex: selectionIndex - 1,
      character,
      breakOnCharacters,
    });
  }

  return -1;
};

/**
 * Searches forwards through text content for the next occurrence of the given character
 *
 * @param {Object} params
 * @param {string} content The chunk of text to search within
 * @param {number} selectionIndex The starting point to search from
 * @param {string} character The character to search for
 * @param {string[]} breakOnCharacters Any characters which should result in an immediate halt to the search
 * @returns {number} Index of the next occurrence of the character, or -1 if it isn't found
 */
export const getNextIndexOfCharacter = ({
  content,
  selectionIndex,
  character,
  breakOnCharacters = [],
}) => {
  const currentCharacter = content.charAt(selectionIndex);
  const nextCharacter = content.charAt(selectionIndex + 1);

  if (currentCharacter === character) {
    return selectionIndex;
  }

  if (
    selectionIndex <= content.length &&
    !breakOnCharacters.includes(nextCharacter)
  ) {
    return getNextIndexOfCharacter({
      content,
      selectionIndex: selectionIndex + 1,
      character,
      breakOnCharacters,
    });
  }

  return -1;
};

/**
 * Counts how many new lines come immediately before the user's current selection start
 * @param {object} args
 * @param {number} args.selectionStart The index of user's current selection start
 * @param {string} args.value The value of the textarea
 *
 * @returns {number} Number of new lines directly before selection start
 */
export const getNumberOfNewLinesPrecedingSelection = ({
  selectionStart,
  value,
}) => {
  if (selectionStart === 0) {
    return 0;
  }

  let count = 0;
  let searchIndex = selectionStart - 1;

  while (searchIndex >= 0 && value.charAt(searchIndex) === '\n') {
    count++;
    searchIndex--;
  }

  return count;
};

/**
 * Counts how many new lines come immediately after the user's current selection end
 *
 * @param {object} args
 * @param {number} args.selectionEnd The index of user's current selection end
 * @param {string} args.value The value of the textarea
 *
 * @returns {number} the count of new line characters immediately following selection
 */
export const getNumberOfNewLinesFollowingSelection = ({
  selectionEnd,
  value,
}) => {
  if (selectionEnd === value.length) {
    return 0;
  }

  let count = 0;
  let searchIndex = selectionEnd;

  while (searchIndex < value.length && value.charAt(searchIndex) === '\n') {
    count++;
    searchIndex++;
  }

  return count;
};

/**
 * Retrieve data about the user's current text selection
 *
 * @param {Object} params
 * @param {number} selectionStart The start point of user's selection
 * @param {number} selectionEnd The end point of user's selection
 * @param {string} value The current value of the textarea
 * @returns {Object} object containing the text chunks before and after insertion, and the currently selected text
 */
export const getSelectionData = ({ selectionStart, selectionEnd, value }) => ({
  textBeforeSelection: value.substring(0, selectionStart),
  textAfterSelection: value.substring(selectionEnd, value.length),
  selectedText: value.substring(selectionStart, selectionEnd),
});

/**
 * This hook can be used to keep the height of a textarea in step with the current content height, avoiding a scrolling textarea.
 * An optional array of additional elements can be set. If provided, all elements will be set to the greatest content height.
 * Optionally, it can be specified to also constrain the max-height to the content height. Otherwise the max-height will continue to be managed only by the textarea's CSS
 *
 * @example
 *
 * const { setTextArea } = useTextAreaAutoResize();
 * setTextArea(myTextAreaRef.current);
 * setAdditionalElements([myOtherElement.current]);
 */
export const useTextAreaAutoResize = () => {
  const [textArea, setTextArea] = useState(null);
  const [constrainToContentHeight, setConstrainToContentHeight] = useState(false);
  const [additionalElements, setAdditionalElements] = useState([]);
  const rafIdRef = useRef(null);
  const lastAppliedPxRef = useRef('');

  useLayoutEffect(() => {
    if (!textArea) return;

    const allElements = [textArea, ...additionalElements];

    // Apply smoothing once to each element for less "jumpy" visuals.
    allElements.forEach((el) => {
      if (!el) return;
      // Avoid duplicating transitions if already present.
      const needsMinMax = !/min-height|max-height/.test(el.style.transition || '');
      if (needsMinMax) {
        const existing = el.style.transition ? el.style.transition + ', ' : '';
        el.style.transition = `${existing}min-height 120ms ease, max-height 120ms ease`;
      }
      el.style.overflow = 'hidden'; // prevents scrollbar flicker while resizing
      el.style.willChange = (el.style.willChange || '').includes('height') ? el.style.willChange : `${el.style.willChange ? el.style.willChange + ', ' : ''}height`;
    });

    // Measure function that defaults to placeholder height when empty.
    const measureElementHeight = (el) => {
      if (!el) return 0;

      // Use placeholder as the content height when the field is empty so
      // the default height equals what the user sees.
      let height;
      const isTextArea = el.tagName === 'TEXTAREA';
      if (isTextArea && !el.value && el.placeholder) {
        const original = el.value;
        el.value = el.placeholder;
        // Assumes your helper returns { height }
        height = calculateTextAreaHeight(el).height;
        el.value = original;
      } else {
        height = calculateTextAreaHeight(el).height;
      }
      return height;
    };

    const measureAll = () => {
      const heights = allElements.map(measureElementHeight);
      return Math.max(...heights, 0);
    };

    // Batch DOM writes to the next animation frame to avoid per-keystroke jitter.
    const resizeTextArea = () => {
      if (rafIdRef.current) cancelAnimationFrame(rafIdRef.current);
      rafIdRef.current = requestAnimationFrame(() => {
        const height = Math.ceil(measureAll()); // rounding mitigates +/-1px oscillation
        const px = `${height}px`;

        // Avoid redundant writes—prevents transition restarts and "glitch".
        if (lastAppliedPxRef.current === px) return;

        allElements.forEach((el) => {
          if (!el) return;
          el.style.minHeight = px;
          if (constrainToContentHeight) {
            el.style.maxHeight = px;
          } else {
            el.style.removeProperty('max-height');
          }
        });

        lastAppliedPxRef.current = px;
      });
    };

    // Initial measurement before paint (useLayoutEffect) for correct first frame.
    resizeTextArea();

    // Smooth out on typing: tiny debounce so it doesn’t jump every single character,
    // but still feels real-time.
    const debouncedInput = debounceAction(resizeTextArea, 80);
    textArea.addEventListener('input', debouncedInput);

    // Recalculate on element resize/layout shifts
    const resizeObserver = new ResizeObserver(debounceAction(resizeTextArea, 300));
    resizeObserver.observe(textArea);

    // If fonts load async, recalc
    try {
      if (document?.fonts?.ready) {
        document.fonts.ready.then(() => resizeTextArea());
      }
    } catch (_) {
      // ignore
    }

    return () => {
      if (rafIdRef.current) cancelAnimationFrame(rafIdRef.current);
      resizeObserver.disconnect();
      textArea.removeEventListener('input', debouncedInput);
    };
  }, [textArea, additionalElements, constrainToContentHeight]);

  return { setTextArea, setAdditionalElements, setConstrainToContentHeight };
};
