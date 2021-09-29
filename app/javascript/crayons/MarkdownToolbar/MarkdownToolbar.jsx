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
    getCursorOffsetStart: () => 2,
    getCursorOffsetEnd: () => 2,
  },
  italic: {
    label: 'Italic',
    insertSyntax: (selection) => `_${selection}_`,
    getCursorOffsetStart: () => 1,
    getCursorOffsetEnd: () => 1,
  },
  underline: {
    label: 'Underline',
    insertSyntax: (selection) => `<u>${selection}</u>`,
    getCursorOffsetStart: () => 3,
    getCursorOffsetEnd: () => 3,
  },
  strikethrough: {
    label: 'Strikethrough',
    insertSyntax: (selection) => `~~${selection}~~`,
    getCursorOffsetStart: () => 2,
    getCursorOffsetEnd: () => 2,
  },
  link: {
    label: 'Link',
    insertSyntax: (selection) =>
      isStringStartAUrl(selection) ? `[](${selection})` : `[${selection}](url)`,
    getCursorOffsetStart: (selection) => (isStringStartAUrl(selection) ? 3 : 1),
    getCursorOffsetEnd: (selection) => (isStringStartAUrl(selection) ? 3 : 1),
  },
  unorderedList: {
    label: 'Unordered list',
    insertSyntax: (selection) => `- ${selection}`.replace(/\n/g, '\n- '),
    getCursorOffsetStart: (selection) => (selection.length === 0 ? 1 : 0),
    getCursorOffsetEnd: (selection) =>
      `- ${selection}`.replace(/\n/g, '\n- ').length - selection.length,
    insertOnNewLine: true,
  },
  orderedList: {
    label: 'Ordered list',
    insertSyntax: (selection) =>
      selection
        .split('\n')
        .map((textChunk, index) => `${index + 1}. ${textChunk}`)
        .join('\n'),
    getCursorOffsetStart: (selection) => (selection.length === 0 ? 1 : 0),
    getCursorOffsetEnd: (selection) =>
      selection
        .split('\n')
        .map((textChunk, index) => `${index + 1}. ${textChunk}`)
        .join('\n').length - selection.length,
    insertOnNewLine: true,
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
    const {
      insertSyntax,
      getCursorOffsetStart,
      getCursorOffsetEnd,
      insertOnNewLine,
    } = markdownSyntaxFormatters[syntaxName];

    const requiresANewLine = selectionStart !== 0 && insertOnNewLine;

    const syntaxCursorOffsetStart = getCursorOffsetStart(selectedText);
    const syntaxCursorOffsetEnd = getCursorOffsetEnd(selectedText);

    const newLineOffset = requiresANewLine ? 1 : 0;

    const newTextContent = `${textBeforeInsertion}${
      requiresANewLine ? '\n' : ''
    }${insertSyntax(selectedText)}${textAfterInsertion}`;

    textArea.value = newTextContent;
    textArea.focus();
    textArea.setSelectionRange(
      selectionStart + syntaxCursorOffsetStart + newLineOffset,
      selectionEnd + syntaxCursorOffsetEnd + newLineOffset,
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
