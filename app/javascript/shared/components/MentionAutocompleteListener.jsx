import { h } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import { MentionAutocomplete } from '@crayons/MentionAutocomplete';
import { getCursorXY } from '@utilities/textAreaUtils';

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

  const handleSelection = (selection) => {
    handleSearchTermChange(selection);
    setIsAutocompleteActive(false);
    textAreaRef.current.focus();
  };

  return isAutocompleteActive ? (
    <MentionAutocomplete
      onSelect={handleSelection}
      fetchSuggestions={fetchSuggestions}
      placementCoords={cursorPlacementData}
      onSearchTermChange={handleSearchTermChange}
    />
  ) : null;
};
