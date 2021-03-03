import { h, render } from 'preact';
import { useState, useEffect, useCallback } from 'preact/hooks';
import { getCursorXY } from '@utilities/textAreaUtils';

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
export const MentionAutocomplete = ({ textAreaRef, fetchSuggestions }) => {
  const [isAutocompleteActive, setIsAutocompleteActive] = useState(false);
  const [cursorPlacementData, setCursorPlacementData] = useState({});

  const handleSearchTermChange = useCallback(
    (searchTerm) => {
      const { textBefore, textAfter } = cursorPlacementData;

      const newValue = `${textBefore}@${searchTerm}${textAfter}`;
      textAreaRef.current.value = newValue;
    },
    [cursorPlacementData, textAreaRef],
  );

  const handleSelection = useCallback(
    (selection) => {
      const { textBefore, textAfter } = cursorPlacementData;
      const newValueUntilEndOfSearch = `${textBefore}@${selection}`;
      textAreaRef.current.value = `${newValueUntilEndOfSearch}${textAfter}`;

      const nextCursorPosition = newValueUntilEndOfSearch.length;
      setIsAutocompleteActive(false);
      textAreaRef.current.focus();
      textAreaRef.current.setSelectionRange(
        nextCursorPosition,
        nextCursorPosition,
      );
    },
    [cursorPlacementData, textAreaRef],
  );

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
    };

    const textArea = textAreaRef.current;

    if (textArea) {
      textArea.onkeypress = keyEventListener;
      return () => (textArea.onkeypress = null);
    }
  }, [textAreaRef]);

  useEffect(() => {
    const container = document.getElementById('mention-autocomplete-container');
    if (!container) {
      return;
    }
    if (isAutocompleteActive) {
      import('./MentionAutocompleteCombobox').then(
        ({ MentionAutocompleteCombobox }) => {
          render(
            <MentionAutocompleteCombobox
              onSelect={handleSelection}
              fetchSuggestions={fetchSuggestions}
              placementCoords={cursorPlacementData}
              onSearchTermChange={handleSearchTermChange}
            />,
            container,
          );
        },
      );
    } else {
      render(null, container);
    }
  }, [
    cursorPlacementData,
    fetchSuggestions,
    handleSearchTermChange,
    handleSelection,
    isAutocompleteActive,
  ]);

  return <span id="mention-autocomplete-container" />;
};
