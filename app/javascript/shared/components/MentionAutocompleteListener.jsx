import { h, render } from 'preact';
import { useState, useEffect, useCallback } from 'preact/hooks';
import { getCursorXY } from '@utilities/textAreaUtils';

export const MentionAutocompleteListener = ({
  textAreaRef,
  fetchSuggestions,
}) => {
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
      import('@crayons/MentionAutocomplete').then(({ MentionAutocomplete }) => {
        render(
          <MentionAutocomplete
            onSelect={handleSelection}
            fetchSuggestions={fetchSuggestions}
            placementCoords={cursorPlacementData}
            onSearchTermChange={handleSearchTermChange}
          />,
          container,
        );
      });
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
