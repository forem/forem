import { h } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import { MentionAutocomplete } from '@crayons/MentionAutocomplete';

export const MentionAutocompleteListener = ({
  textAreaRef,
  fetchSuggestions,
}) => {
  const [isAutocompleteActive, setIsAutocompleteActive] = useState(false);
  const [cursorPlacementData, setCursorPlacementData] = useState({});

  useEffect(() => {
    const keyEventListener = ({ key }) => {
      if (key === '@') {
        const coords = getCursorXY(
          textAreaRef.current,
          textAreaRef.current.selectionStart,
        );

        setCursorPlacementData({
          ...coords,
          textBefore: textAreaRef.current.value.substring(
            0,
            textAreaRef.current.selectionStart,
          ),
          textAfter: textAreaRef.current.value.substring(
            textAreaRef.current.selectionStart,
          ),
        });
        setIsAutocompleteActive(true);
      }

      if (key === ' ') {
        setIsAutocompleteActive(false);
      }
    };

    const textArea = textAreaRef.current;

    if (textArea) {
      textArea.onkeypress = keyEventListener;
      return () => (textArea.onkeypress = null);
    }
  }, [textAreaRef]);

  const handleSearchTermChange = (searchTerm) => {
    const { textBefore, textAfter } = cursorPlacementData;

    const newValue = `${textBefore}@${searchTerm}${textAfter}`;
    textAreaRef.current.value = newValue;
  };

  const handleSelection = () => {};

  return isAutocompleteActive ? (
    <MentionAutocomplete
      onSelect={handleSelection}
      fetchSuggestions={fetchSuggestions}
      placementCoords={cursorPlacementData}
      onSearchTermChange={handleSearchTermChange}
    />
  ) : null;
};

const getCursorXY = (input, selectionPoint) => {
  const { offsetLeft: inputX, offsetTop: inputY } = input;
  // create a dummy element that will be a clone of our input
  const div = top.document.createElement('div');

  // get the computed style of the input and clone it onto the dummy element
  const copyStyle = getComputedStyle(input);
  for (const prop of copyStyle) {
    div.style[prop] = copyStyle[prop];
  }
  // we need a character that will replace whitespace when filling our dummy element if it's a single line <input/>
  const swap = '.';
  const inputValue =
    input.tagName === 'INPUT' ? input.value.replace(/ /g, swap) : input.value;
  // set the div content to that of the textarea up until selection
  const textContent = inputValue.substr(0, selectionPoint);
  // set the text content of the dummy element div
  div.textContent = textContent;
  if (input.tagName === 'TEXTAREA') div.style.height = 'auto';
  // if a single line input then the div needs to be single line and not break out like a text area
  if (input.tagName === 'INPUT') div.style.width = 'auto';
  // create a marker element to obtain caret position
  const span = top.document.createElement('span');
  // give the span the textContent of remaining content so that the recreated dummy element is as close as possible
  span.textContent = inputValue.substr(selectionPoint) || '.';
  // append the span marker to the div
  div.appendChild(span);
  // append the dummy element to the body
  top.document.body.appendChild(div);
  // get the marker position, this is the caret position top and left relative to the input
  const { offsetLeft: spanX, offsetTop: spanY } = span;
  // lastly, remove that dummy element
  // NOTE:: can comment this out for debugging purposes if you want to see where that span is rendered
  top.document.body.removeChild(div);
  // return an object with the x and y of the caret. account for input positioning so that you don't need to wrap the input
  return {
    x: inputX + spanX,
    y: inputY + spanY,
  };
};
