import {
  getIndexOfLineStart,
  getLastIndexOfCharacter,
  getNextIndexOfCharacter,
} from '../../utilities/textAreaUtils';
import {
  Bold,
  Italic,
  Link,
  OrderedList,
  UnorderedList,
  Heading,
  Quote,
  Code,
  CodeBlock,
  Underline,
  Strikethrough,
  Divider,
} from './icons';

// TODO: return exact cursor start/end positions, not just an offset
// TODO: rename getFormatting

const ORDERED_LIST_ITEM_REGEX = /^\d+\.\s+.+/;
const MARKDOWN_LINK_REGEX =
  /^\[([\w\s\d]*)\]\((url|(https?:\/\/[\w\d./?=#]+))\)$/;
const URL_PLACEHOLDER_TEXT = 'url';

const isStringStartAUrl = (string) => {
  const startingText = string.substring(0, 8);
  return startingText === 'https://' || startingText.startsWith('http://');
};

const getSelectionData = ({ selectionStart, selectionEnd, value }) => {
  const textBeforeInsertion = value.substring(0, selectionStart);
  const textAfterInsertion = value.substring(selectionEnd, value.length);

  const selectedText = value.substring(selectionStart, selectionEnd);

  return {
    textBeforeInsertion,
    textAfterInsertion,
    selectedText,
  };
};

export const doesSelectionHaveFormatting = ({
  selectedText,
  textBeforeInsertion,
  textAfterInsertion,
  formattedPrefix,
  formattedSuffix,
}) => {
  const { length: prefixLength } = formattedPrefix;
  const { length: suffixLength } = formattedSuffix;

  if (
    selectedText &&
    selectedText.substring(0, prefixLength) === formattedPrefix &&
    selectedText.substring(selectedText.length - suffixLength) ===
      formattedSuffix
  ) {
    return true;
  }

  if (
    textBeforeInsertion.length < prefixLength ||
    textAfterInsertion < suffixLength
  ) {
    return false;
  }

  const prefix = textBeforeInsertion.substring(
    textBeforeInsertion.length - prefixLength,
  );
  const suffix = textAfterInsertion.substring(0, suffixLength);

  return prefix === formattedPrefix && suffix === formattedSuffix;
};

const undoOrAddFormattingForInlineSyntax = ({
  value,
  selectionStart,
  selectionEnd,
  prefix,
  suffix,
}) => {
  const { length: prefixLength } = prefix;
  const { length: suffixLength } = suffix;
  const { selectedText, textBeforeInsertion, textAfterInsertion } =
    getSelectionData({ selectionStart, selectionEnd, value });

  // Check if selected text has prefix/suffix
  const selectedTextAlreadyFormatted =
    selectedText.substring(0, prefixLength) === prefix &&
    selectedText.substring(selectionEnd - suffixLength) === suffix;

  if (selectedTextAlreadyFormatted) {
    return {
      newTextAreaValue: `${textBeforeInsertion}${selectedText.slice(
        prefixLength,
        selectionEnd - suffixLength,
      )}${textAfterInsertion}`,
      cursorOffsetStart: 0,
      cursorOffsetEnd: -1 * (prefixLength + suffixLength),
    };
  }

  // Check if immediate surrounding content has prefix/suffix
  const surroundingTextHasFormatting =
    textBeforeInsertion.substring(textBeforeInsertion.length - prefixLength) ===
      prefix && textAfterInsertion.substring(0, suffixLength) === suffix;

  if (surroundingTextHasFormatting) {
    return {
      newTextAreaValue: `${textBeforeInsertion.slice(
        0,
        -1 * prefixLength,
      )}${selectedText}${textAfterInsertion.slice(suffixLength)}`,
      cursorOffsetStart: -1 * prefixLength,
      cursorOffsetEnd: -1 * prefixLength,
    };
  }

  // No formatting to undo - format the selected text
  return {
    newTextAreaValue: `${textBeforeInsertion}${prefix}${selectedText}${suffix}${textAfterInsertion}`,
    cursorOffsetStart: prefixLength,
    cursorOffsetEnd: prefixLength,
  };
};

const undoOrAddFormattingForMultilineSyntax = ({
  selectionStart,
  selectionEnd,
  value,
  linePrefix,
  blockPrefix,
  blockSuffix,
}) => {
  const { selectedText, textBeforeInsertion, textAfterInsertion } =
    getSelectionData({ selectionStart, selectionEnd, value });

  let formattedText = selectedText;

  if (linePrefix) {
    const { length: prefixLength } = linePrefix;

    // Split by new lines and check each line has formatting
    const splitByNewLine = selectedText
      .split('\n')
      .filter((line) => line !== '');

    const isAlreadyFormatted =
      splitByNewLine.length > 0 &&
      splitByNewLine.every(
        (line) => line.slice(0, prefixLength) === linePrefix,
      );

    if (isAlreadyFormatted) {
      // Remove the formatting
      const unformattedText = splitByNewLine
        .map((line) => line.slice(prefixLength))
        .join('\n');

      return {
        newTextAreaValue: `${textBeforeInsertion}${unformattedText}${textAfterInsertion}`,
        cursorOffsetStart: 0,
        cursorOffsetEnd: unformattedText.length - selectedText.length,
      };
    }

    // Otherwise add the prefix to each line to create the new formatted text
    formattedText =
      selectedText === ''
        ? linePrefix
        : splitByNewLine.map((line) => `${linePrefix}${line}`).join('\n');
  } else {
    // Uses only block prefix and suffix
    const { length: prefixLength } = blockPrefix;
    const { length: suffixLength } = blockSuffix;

    // does the selection start and end with the prefix/suffix
    const selectionIsFormatted =
      selectedText.slice(0, prefixLength) === blockPrefix &&
      selectedText.slice(-1 * suffixLength) === blockSuffix;

    if (selectionIsFormatted) {
      return {
        newTextAreaValue: `${textBeforeInsertion}${selectedText.slice(
          prefixLength,
          -1 * suffixLength,
        )}${textAfterInsertion}`,
        cursorOffsetStart: 0,
        cursorOffsetEnd: -1 * (prefixLength + suffixLength),
      };
    }

    // or does the prefix/suffix plus new line chars immediately precede and follow the selection
    const surroundingTextIsFormatted =
      textBeforeInsertion.slice(-1 * prefixLength) === blockPrefix &&
      textAfterInsertion.slice(0, suffixLength) === blockSuffix;

    if (surroundingTextIsFormatted) {
      return {
        newTextAreaValue: `${textBeforeInsertion.slice(
          0,
          -1 * prefixLength,
        )}${selectedText}${textAfterInsertion.slice(suffixLength)}`,
        cursorOffsetStart: -1 * prefixLength,
        cursorOffsetEnd: -1 * prefixLength,
      };
    }
  }

  // Add the formatting
  const numberOfNewLinesBeforeSelection = (
    textBeforeInsertion.slice(-2).match(/\n/g) || []
  ).length;

  // Multiline insertions should occur after two new lines (whether added already by user or inserted automatically)
  const newLinesToAddBeforeSelection = 2 - numberOfNewLinesBeforeSelection;
  let newTextBeforeInsertion = textBeforeInsertion;
  Array.from({ length: newLinesToAddBeforeSelection }, () => {
    newTextBeforeInsertion += '\n';
  });

  return {
    newTextAreaValue: `${newTextBeforeInsertion}${
      blockPrefix ? blockPrefix : ''
    }${formattedText}${blockSuffix ? blockSuffix : ''}${textAfterInsertion}`,
    cursorOffsetStart:
      newLinesToAddBeforeSelection + (blockPrefix?.length || 0),
    cursorOffsetEnd:
      formattedText.length -
      selectedText.length +
      newLinesToAddBeforeSelection +
      (blockPrefix?.length || 0),
  };
};

export const coreSyntaxFormatters = {
  bold: {
    icon: Bold,
    label: 'Bold',
    keyboardShortcut: 'ctrl+b',
    keyboardShortcutKeys: `B`,
    getFormatting: ({ selectionStart, selectionEnd, value }) => {
      return undoOrAddFormattingForInlineSyntax({
        selectionStart,
        selectionEnd,
        value,
        prefix: '**',
        suffix: '**',
      });
    },
  },
  italic: {
    icon: Italic,
    label: 'Italic',
    keyboardShortcut: 'ctrl+i',
    keyboardShortcutKeys: `I`,
    getFormatting: ({ selectionStart, selectionEnd, value }) => {
      return undoOrAddFormattingForInlineSyntax({
        selectionStart,
        selectionEnd,
        value,
        prefix: '_',
        suffix: '_',
      });
    },
  },
  link: {
    icon: Link,
    label: 'Link',
    keyboardShortcut: 'ctrl+k',
    keyboardShortcutKeys: `K`,
    getFormatting: ({ selectionStart, selectionEnd, value }) => {
      const { selectedText, textBeforeInsertion, textAfterInsertion } =
        getSelectionData({ selectionStart, selectionEnd, value });

      // Check if we are inside empty link description [](something) and remove it if so
      if (selectedText === '') {
        const directlySurroundedByLinkStructure =
          textBeforeInsertion.slice(-1) === '[' &&
          textAfterInsertion.slice(0, 2) === '](';

        // Search beyond current position to check for the closing bracket of markdown link
        const indexOfLinkStructureEnd = getNextIndexOfCharacter({
          content: value,
          selectionIndex: selectionStart,
          character: ')',
          breakOnCharacters: [' ', '\n'],
        });

        if (
          directlySurroundedByLinkStructure &&
          indexOfLinkStructureEnd !== -1
        ) {
          // Remove the markdown link structure, preserving the link text if it isn't the "url" placeholder
          const urlText = value.slice(
            selectionEnd + 2,
            indexOfLinkStructureEnd,
          );

          return {
            newTextAreaValue: `${textBeforeInsertion.slice(0, -1)}${
              urlText === URL_PLACEHOLDER_TEXT ? '' : urlText
            }${value.slice(indexOfLinkStructureEnd + 1)}`,
            cursorOffsetStart: 0,
            cursorOffsetEnd: 0,
          };
        }
      }

      const isSelectedTextAUrl = isStringStartAUrl(selectedText);

      // If the selected text is a URL or placeholder URL, check if it is already formatted as MD link
      if (isSelectedTextAUrl || selectedText === URL_PLACEHOLDER_TEXT) {
        const directlySurroundedByLinkStructure =
          textBeforeInsertion.slice(-2) === '](' &&
          textAfterInsertion.slice(0, 1) === ')';

        if (directlySurroundedByLinkStructure) {
          // Get the text inside the square brackets
          const indexOfSyntaxOpen = getLastIndexOfCharacter({
            content: value,
            selectionIndex: selectionStart,
            character: '[',
          });

          if (indexOfSyntaxOpen !== -1) {
            // We want to replace the markdown with the link text in square brackets, if available
            let textToReplaceMarkdown = textBeforeInsertion.slice(
              indexOfSyntaxOpen + 1,
              -2,
            );
            // If not available, take the URL as long as it's not the placeholder 'url' text
            if (textToReplaceMarkdown === '') {
              textToReplaceMarkdown =
                selectedText === URL_PLACEHOLDER_TEXT ? '' : selectedText;
            }

            return {
              newTextAreaValue: `${textBeforeInsertion.slice(
                0,
                indexOfSyntaxOpen,
              )}${textToReplaceMarkdown}${textAfterInsertion.slice(1)}`,
              cursorOffsetStart: 0,
              cursorOffsetEnd: 0,
            };
          }
        }
      }

      // If the whole selectedText matches markdown link formatting, undo it
      if (selectedText.match(MARKDOWN_LINK_REGEX)) {
        const linkDescriptionEnd = getNextIndexOfCharacter({
          content: selectedText,
          selectionIndex: selectionStart,
          character: ']',
        });
        let textToReplaceMarkdown = selectedText.slice(1, linkDescriptionEnd);

        // Keep the URL instead if no link description exists
        if (textToReplaceMarkdown === '') {
          textToReplaceMarkdown = selectedText.slice(
            linkDescriptionEnd + 2,
            -1,
          );
        }

        return {
          newTextAreaValue: `${textBeforeInsertion}${textToReplaceMarkdown}${textAfterInsertion}`,
          cursorOffsetStart: 0,
          cursorOffsetEnd: 0,
        };
      }

      // Finally, there is no syntax to undo, so format as a markdown URL
      const markdownText = isSelectedTextAUrl
        ? `[](${selectedText})`
        : `[${selectedText}](${URL_PLACEHOLDER_TEXT})`;

      return {
        newTextAreaValue: `${textBeforeInsertion}${markdownText}${textAfterInsertion}`,
        cursorOffsetStart: selectedText.length + 3,
        cursorOffsetEnd: 6,
      };
    },
  },
  orderedList: {
    icon: OrderedList,
    label: 'Ordered list',
    getFormatting: ({ selectionStart, selectionEnd, value }) => {
      const { selectedText, textBeforeInsertion, textAfterInsertion } =
        getSelectionData({ selectionStart, selectionEnd, value });

      if (selectedText === '') {
        return {
          newTextAreaValue: `${textBeforeInsertion}1. ${textAfterInsertion}`,
          cursorOffsetStart: 3,
          cursorOffsetEnd: 3,
        };
      }

      const splitByNewLine = selectedText.split('\n');

      const isAlreadyAnOrderedList = splitByNewLine.every(
        (line) => line.match(ORDERED_LIST_ITEM_REGEX) || line === '',
      );

      if (isAlreadyAnOrderedList) {
        // Undo formatting
        const newText = splitByNewLine
          .filter((line) => line !== '')
          .map((line) => {
            const indexOfFullStop = line.indexOf('.');
            return line.substring(indexOfFullStop + 2);
          })
          .join('\n');

        return {
          newTextAreaValue: `${textBeforeInsertion}${newText}${textAfterInsertion}`,
          cursorOffsetStart: selectedText.indexOf('.') - 1,
          cursorOffsetEnd: newText.length - selectedText.length,
        };
      }
      // Otherwise convert to an ordered list
      const formattedList = `\n${splitByNewLine
        .map((textChunk, index) => `${index + 1}. ${textChunk}`)
        .join('\n')}\n`;

      return {
        newTextAreaValue: `${textBeforeInsertion}${formattedList}${textAfterInsertion}`,
        cursorOffsetStart: selectedText.length === 0 ? 4 : 1,
        cursorOffsetEnd: formattedList.length - selectedText.length,
      };
    },
  },
  unorderedList: {
    icon: UnorderedList,
    label: 'Unordered list',
    getFormatting: ({ selectionStart, selectionEnd, value }) => {
      return undoOrAddFormattingForMultilineSyntax({
        selectionStart,
        selectionEnd,
        value,
        linePrefix: '- ',
      });
    },
  },
  heading: {
    icon: Heading,
    label: 'Heading',
    getFormatting: ({ selectionStart, selectionEnd, value }) => {
      let currentLineSelectionStart = selectionStart;

      // The 'heading' formatter can edit a previously inserted syntax,
      // so we check if we need adjust the selection to the start of the line
      const indexOfLineStart = getIndexOfLineStart(value, selectionStart);

      if (value.charAt(indexOfLineStart + 1) === '#') {
        currentLineSelectionStart = indexOfLineStart;
      }

      const { selectedText, textBeforeInsertion, textAfterInsertion } =
        getSelectionData({ currentLineSelectionStart, selectionEnd, value });

      let currentHeadingIndex = 0;
      while (selectedText.charAt(currentHeadingIndex) === '#') {
        currentHeadingIndex++;
      }

      //   After h4, revert to no heading at all
      if (currentHeadingIndex === 4) {
        return {
          newTextAreaValue: `${textBeforeInsertion}${selectedText.substring(
            5,
          )}${textAfterInsertion}`,
          cursorOffsetStart: 0,
          cursorOffsetEnd: 0,
        };
      }

      const adjustingHeading = currentHeadingIndex > 0;

      return {
        newTextAreaValue: adjustingHeading
          ? `${textBeforeInsertion}#${selectedText}${textAfterInsertion}`
          : `${textBeforeInsertion}\n## ${selectedText}\n${textAfterInsertion}`,
        cursorOffsetStart: adjustingHeading ? currentHeadingIndex + 2 : 4,
        cursorOffsetEnd: adjustingHeading ? 1 : 4,
      };
    },
  },
  quote: {
    icon: Quote,
    label: 'Quote',
    getFormatting: ({ selectionStart, selectionEnd, value }) =>
      undoOrAddFormattingForMultilineSyntax({
        selectionStart,
        selectionEnd,
        value,
        linePrefix: '> ',
      }),
  },
  code: {
    icon: Code,
    label: 'Code',
    getFormatting: ({ selectionStart, selectionEnd, value }) =>
      undoOrAddFormattingForInlineSyntax({
        selectionStart,
        selectionEnd,
        value,
        prefix: '`',
        suffix: '`',
      }),
  },
  codeBlock: {
    icon: CodeBlock,
    label: 'Code block',
    getFormatting: ({ selectionStart, selectionEnd, value }) =>
      undoOrAddFormattingForMultilineSyntax({
        selectionStart,
        selectionEnd,
        value,
        blockPrefix: '```\n',
        blockSuffix: '\n```',
      }),
  },
};

export const secondarySyntaxFormatters = {
  underline: {
    icon: Underline,
    label: 'Underline',
    keyboardShortcut: 'ctrl+u',
    keyboardShortcutKeys: `U`,
    getFormatting: ({ selectionStart, selectionEnd, value }) =>
      undoOrAddFormattingForInlineSyntax({
        selectionStart,
        selectionEnd,
        value,
        prefix: '<u>',
        suffix: '</u>',
      }),
  },
  strikethrough: {
    icon: Strikethrough,
    label: 'Strikethrough',
    keyboardShortcut: 'ctrl+shift+x',
    keyboardShortcutKeys: `SHIFT + X`,
    getFormatting: ({ selectionStart, selectionEnd, value }) =>
      undoOrAddFormattingForInlineSyntax({
        selectionStart,
        selectionEnd,
        value,
        prefix: '~~',
        suffix: '~~',
      }),
  },
  divider: {
    icon: Divider,
    label: 'Line divider',
    getFormatting: ({ selectionStart, selectionEnd, value }) =>
      undoOrAddFormattingForMultilineSyntax({
        selectionStart,
        selectionEnd,
        value,
        blockPrefix: '---\n',
        blockSuffix: '\n',
      }),
  },
};
