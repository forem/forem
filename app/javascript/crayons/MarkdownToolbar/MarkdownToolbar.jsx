import { h } from 'preact';
import { useState, useLayoutEffect } from 'preact/hooks';
import {
  coreSyntaxFormatters,
  secondarySyntaxFormatters,
} from './markdownSyntaxFormatters';
import { Button } from '@crayons';

const getIndexOfLineStart = (text, cursorStart) => {
  const currentCharacter = text.charAt(cursorStart);
  if (currentCharacter === '\n') {
    return cursorStart;
  }

  if (cursorStart !== 0) {
    return getIndexOfLineStart(text, cursorStart - 1);
  }

  return 0;
};

export const MarkdownToolbar = ({ textAreaId }) => {
  const [textArea, setTextArea] = useState(null);

  const markdownSyntaxFormatters = {
    ...coreSyntaxFormatters,
    ...secondarySyntaxFormatters,
  };

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

  const getSelectionData = (syntaxName) => {
    const {
      selectionStart: initialSelectionStart,
      selectionEnd,
      value,
    } = textArea;

    let selectionStart = initialSelectionStart;

    // The 'heading' formatter can edit a previously inserted syntax,
    // so we check if we need adjust the selection to the start of the line
    if (syntaxName === 'heading') {
      const startOfLine = getIndexOfLineStart(
        textArea.value,
        initialSelectionStart,
      );

      if (textArea.value.charAt(startOfLine + 1) === '#') {
        selectionStart = startOfLine + 1;
      }
    }

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
    } = getSelectionData(syntaxName);

    const {
      formattedText,
      cursorOffsetStart,
      cursorOffsetEnd,
      insertOnNewLine,
    } = markdownSyntaxFormatters[syntaxName].getFormatting(selectedText);

    const requiresANewLine = selectionStart !== 0 && insertOnNewLine;
    const newLineOffset = requiresANewLine ? 1 : 0;

    const newTextContent = `${textBeforeInsertion}${
      requiresANewLine ? '\n' : ''
    }${formattedText}${textAfterInsertion}`;

    textArea.value = newTextContent;
    textArea.focus();
    textArea.setSelectionRange(
      selectionStart + cursorOffsetStart + newLineOffset,
      selectionEnd + cursorOffsetEnd + newLineOffset,
    );
  };

  return (
    <div
      className="editor-toolbar"
      aria-label="Markdown formatting toolbar"
      role="toolbar"
      aria-controls={textAreaId}
    >
      {Object.keys(coreSyntaxFormatters).map((controlName, index) => {
        const { icon, label } = coreSyntaxFormatters[controlName];
        return (
          <Button
            key={`${controlName}-btn`}
            variant="ghost"
            contentType="icon"
            icon={icon}
            className="toolbar-btn"
            tabindex={index === 0 ? '0' : '-1'}
            onClick={() => insertSyntax(controlName)}
            onKeyUp={handleToolbarButtonKeyPress}
            aria-label={label}
          >
            {icon}
          </Button>
        );
      })}
    </div>
  );
};
