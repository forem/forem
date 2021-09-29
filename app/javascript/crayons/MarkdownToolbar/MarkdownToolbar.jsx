import { h } from 'preact';
import { useState, useLayoutEffect } from 'preact/hooks';

const isStringStartAUrl = (string) => {
  const startingText = string.substring(0, 8);
  return startingText === 'https://' || startingText.startsWith('http://');
};

const markdownSyntaxFormatters = {
  bold: {
    label: 'Bold',
    insertSyntax: (selection) => `**${selection}**`,
    cursorOffset: 2,
  },
  italic: {
    label: 'Italic',
    insertSyntax: (selection) => `_${selection}_`,
    getCursorOffset: () => 1,
  },
  underline: {
    label: 'Underline',
    insertSyntax: (selection) => `<u>${selection}</u>`,
    getCursorOffset: () => 3,
  },
  strikethrough: {
    label: 'Strikethrough',
    insertSyntax: (selection) => `~~${selection}~~`,
    getCursorOffset: () => 2,
  },
  link: {
    label: 'Link',
    insertSyntax: (selection) =>
      isStringStartAUrl(selection) ? `[](${selection})` : `[${selection}](url)`,
    getCursorOffset: (selection) => (isStringStartAUrl(selection) ? 3 : 1),
  },
};

export const MarkdownToolbar = ({ textAreaId }) => {
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

  const insertSyntax = (syntaxName) => {
    const {
      textBeforeInsertion,
      textAfterInsertion,
      selectedText,
      selectionStart,
      selectionEnd,
    } = getSelectionData();
    const { insertSyntax, getCursorOffset } =
      markdownSyntaxFormatters[syntaxName];
    const cursorOffset = getCursorOffset(selectedText);

    const newTextContent = `${textBeforeInsertion}${insertSyntax(
      selectedText,
    )}${textAfterInsertion}`;
    textArea.value = newTextContent;

    textArea.focus();
    textArea.setSelectionRange(
      selectionStart + cursorOffset,
      selectionEnd + cursorOffset,
    );
  };

  return (
    <div
      aria-label="Markdown formatting toolbar"
      role="toolbar"
      aria-controls={textAreaId}
    >
      {Object.keys(markdownSyntaxFormatters).map((controlName, index) => {
        return (
          <button
            key={`${controlName}-btn`}
            className="crayons-btn crayons-btn--secondary toolbar-btn"
            tabindex={index === 0 ? '0' : '-1'}
            onClick={() => insertSyntax(controlName)}
            onKeyUp={handleToolbarButtonKeyPress}
          >
            {controlName}
          </button>
        );
      })}
    </div>
  );
};
