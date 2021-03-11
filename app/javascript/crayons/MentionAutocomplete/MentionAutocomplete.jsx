import { h, render } from 'preact';
import { useState, useEffect, useCallback } from 'preact/hooks';
import { getCursorXY } from '@utilities/textAreaUtils';
import { useMediaQuery, BREAKPOINTS } from '@components/useMediaQuery';

/**
 * A component which listens for an '@' keypress, and encompasses the MentionAutocomplete functionality.
 * When an autocomplete suggestion is selected, it is inserted into the textarea.
 *
 * @param {object} props
 * @param {object} props.textAreaRef A reference to the text area where an '@' mention can take place
 * @param {function} props.fetchSuggestions The callback to search for suggestions
 *
 * @example
 * <Fragment>
 *    <textarea
 *      ref={textAreaRef}
 *      aria-label="test text area"/>
 *    <MentionAutocomplete
 *      textAreaRef={textAreaRef}
 *      fetchSuggestions={fetchUsers}
 *    />
 * </Fragment>
 */
export const addMentionAutocomplete = ({ textAreaRef, fetchSuggestions }) => {
  // Copy all properties from the text area provided
  // Render the Combobox with all properties copied, replacing the textArea via 3rd arg

  const element = textAreaRef.current;
  const container = element.parentElement;

  if (container.getAttribute('data-autocomplete-initialized') !== 'true') {
    import('./MentionAutocompleteCombobox').then(
      ({ MentionAutocompleteCombobox }) => {
        render(
          <MentionAutocompleteCombobox replaceElement={element} />,
          container,
          element,
        );
      },
    );
  }
  container.setAttribute('data-autocomplete-initialized', 'true');

  //   const [isAutocompleteActive, setIsAutocompleteActive] = useState(false);
  //   const [cursorPlacementData, setCursorPlacementData] = useState({});

  //   const isSmallScreen = useMediaQuery(`(max-width: ${BREAKPOINTS.Small}px)`);

  //   const handleSearchTermChange = useCallback(
  //     (searchTerm) => {
  //       const { textBefore, textAfter } = cursorPlacementData;
  //       const { current: textArea } = textAreaRef;

  //       const newValue = `${textBefore}${searchTerm}${textAfter}`;
  //       textArea.value = newValue;

  //       const {
  //         y: currentYPlacement,
  //         x: currentXPlacement,
  //       } = cursorPlacementData;
  //       const { y: newY, x: newX } = getCursorXY(
  //         textArea,
  //         textArea.selectionStart,
  //       );
  //       if (currentYPlacement !== newY) {
  //         // Line has wrapped mid-way through typing username
  //         setCursorPlacementData({
  //           ...cursorPlacementData,
  //           y: newY,
  //           x: isSmallScreen ? currentXPlacement : newX,
  //         });
  //       }
  //     },
  //     [cursorPlacementData, textAreaRef, isSmallScreen],
  //   );

  //   const handleSelection = useCallback(
  //     (selection) => {
  //       const { textBefore, textAfter } = cursorPlacementData;
  //       const newValueUntilEndOfSearch = `${textBefore}${selection}`;
  //       textAreaRef.current.value = `${newValueUntilEndOfSearch}${textAfter}`;

  //       const nextCursorPosition = newValueUntilEndOfSearch.length;

  //       setIsAutocompleteActive(false);

  //       textAreaRef.current.setSelectionRange(
  //         nextCursorPosition,
  //         nextCursorPosition,
  //       );
  //     },
  //     [cursorPlacementData, textAreaRef],
  //   );

  //   useEffect(() => {
  //     const keyEventListener = ({ key }) => {
  //       if (key === '@') {
  //         if (!shouldKeyPressTriggerSearch(textAreaRef.current)) {
  //           return;
  //         }

  //         const textAreaX = textAreaRef.current.offsetLeft;
  //         const cursorCoords = getCursorXY(
  //           textAreaRef.current,
  //           textAreaRef.current.selectionStart,
  //         );

  //         const coords = {
  //           y: cursorCoords.y,
  //           x: isSmallScreen ? textAreaX : cursorCoords.x,
  //         };

  //         setCursorPlacementData({
  //           ...coords,
  //           textBefore: textAreaRef.current.value.substring(
  //             0,
  //             textAreaRef.current.selectionStart,
  //           ),
  //           textAfter: textAreaRef.current.value.substring(
  //             textAreaRef.current.selectionStart,
  //           ),
  //         });
  //         setIsAutocompleteActive(true);
  //       }
  //     };

  //     const textArea = textAreaRef.current;

  //     if (textArea) {
  //       textArea.addEventListener('keydown', keyEventListener);
  //       return () => textArea.removeEventListener('keydown', keyEventListener);
  //     }
  //   }, [textAreaRef, isSmallScreen]);

  //   useEffect(() => {
  //     const container = document.getElementById('mention-autocomplete-container');
  //     if (!container) {
  //       return;
  //     }
  //     if (isAutocompleteActive) {
  //       import('./MentionAutocompleteCombobox').then(
  //         ({ MentionAutocompleteCombobox }) => {
  //           render(
  //             <MentionAutocompleteCombobox
  //               onSelect={handleSelection}
  //               fetchSuggestions={fetchSuggestions}
  //               placementCoords={cursorPlacementData}
  //               onSearchTermChange={handleSearchTermChange}
  //             />,
  //             container,
  //           );
  //         },
  //       );
  //     } else {
  //       render(null, container);
  //       textAreaRef.current.focus();
  //     }
  //   }, [
  //     cursorPlacementData,
  //     fetchSuggestions,
  //     handleSearchTermChange,
  //     handleSelection,
  //     isAutocompleteActive,
  //     textAreaRef,
  //   ]);

  //   return <span id="mention-autocomplete-container" />;
  // };

  // const VALID_PREVIOUS_CHAR_REGEX = new RegExp(/[^A-Za-z0-9]/);
  // const shouldKeyPressTriggerSearch = (textArea) => {
  //   const { selectionStart, value: valueBeforeKeystroke } = textArea;

  //   const previousCharacter = valueBeforeKeystroke.charAt(selectionStart - 1);

  //   return (
  //     previousCharacter === '' ||
  //     VALID_PREVIOUS_CHAR_REGEX.test(previousCharacter)
  //   );
};
