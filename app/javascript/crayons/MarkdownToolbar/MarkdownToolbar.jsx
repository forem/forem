import { h } from 'preact';
import { useState, useLayoutEffect } from 'preact/hooks';

export const MarkdownToolbar = ({ textAreaId }) => {
  const controls = ['bold', 'italic'];

  const [textArea, setTextArea] = useState(null);

  useLayoutEffect(() => {
    setTextArea(document.getElementById(textAreaId));
  }, [textAreaId]);

  const handleToolbarButtonKeyPress = (event) => {
    const { key, target } = event;
    const {
      nextElementSibling: nextButton,
      previousElementSibling: previousButton,
    } = target;

    switch (key) {
      case 'ArrowRight':
        event.preventDefault();
        target.setAttribute('tabindex', '-1');
        if (nextButton) {
          nextButton.setAttribute('tabindex', 0);
          nextButton.focus();
        } else {
          const firstButton = document.querySelector('.toolbar-btn');
          firstButton.setAttribute('tabindex', '0');
          firstButton.focus();
        }
        break;
      case 'ArrowLeft':
        event.preventDefault();
        target.setAttribute('tabindex', '-1');
        if (previousButton) {
          previousButton.setAttribute('tabindex', 0);
          previousButton.focus();
        } else {
          const allButtons = document.getElementsByClassName('toolbar-btn');
          const lastButton = allButtons[allButtons.length - 1];
          lastButton.setAttribute('tabindex', '0');
          lastButton.focus();
        }
    }
  };

  const getSelectionData = () => {
    const { selectionStart, selectionEnd, value } = textArea;

    const textBeforeInsertion = value.substring(0, selectionStart);
    const textAfterInsertion = value.substring(selectionEnd, value.length);
    const selectedText = value.substring(selectionStart, selectionEnd);

    return {
      textBeforeInsertion,
      textAfterInsertion,
      selectedText,
      selectionStart,
      selectionEnd,
    };
  };

  const insertBold = () => {
    const {
      textBeforeInsertion,
      textAfterInsertion,
      selectedText,
      selectionStart,
      selectionEnd,
    } = getSelectionData();
    const newTextContent = `${textBeforeInsertion}**${selectedText}**${textAfterInsertion}`;

    textArea.value = newTextContent;

    textArea.focus();
    textArea.setSelectionRange(selectionStart + 2, selectionEnd + 2);
  };

  const insertItalic = () => {
    const {
      textBeforeInsertion,
      textAfterInsertion,
      selectedText,
      selectionStart,
      selectionEnd,
    } = getSelectionData();
    const newTextContent = `${textBeforeInsertion}_${selectedText}_${textAfterInsertion}`;

    textArea.value = newTextContent;

    textArea.focus();
    textArea.setSelectionRange(selectionStart + 1, selectionEnd + 1);
  };

  return (
    <div
      aria-label="Markdown formatting toolbar"
      role="toolbar"
      aria-controls={textAreaId}
    >
      {/* First button maintains its tabindex to get us into the toolbar */}
      <button
        className="crayons-btn crayons-btn--secondary toolbar-btn"
        id={controls[0]}
        tabindex="0"
        onClick={insertBold}
        onKeyUp={handleToolbarButtonKeyPress}
      >
        Bold
      </button>

      <button
        className="crayons-btn crayons-btn--secondary toolbar-btn"
        id={controls[1]}
        tabindex="-1"
        onClick={insertItalic}
        onKeyUp={handleToolbarButtonKeyPress}
      >
        Italic
      </button>
    </div>
  );
};
