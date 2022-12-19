import { h } from 'preact';
import {
  getLastIndexOfCharacter,
  getNextIndexOfCharacter,
  getNumberOfNewLinesFollowingSelection,
  getNumberOfNewLinesPrecedingSelection,
  getSelectionData,
} from '../../utilities/textAreaUtils';
import { getOSKeyboardModifierKeyString } from '@utilities/runtime';
import BoldIcon from '@images/bold.svg';
import ItalicIcon from '@images/italic.svg';
import LinkIcon from '@images/link.svg';
import OrderedListIcon from '@images/list-ordered.svg';
import UnorderedListIcon from '@images/list-unordered.svg';
import HeadingIcon from '@images/heading.svg';
import QuoteIcon from '@images/quote.svg';
import CodeIcon from '@images/code.svg';
import CodeBlockIcon from '@images/codeblock.svg';
import EmbedIcon from '@images/lightning.svg';
import UnderlineIcon from '@images/underline.svg';
import StrikethroughIcon from '@images/strikethrough.svg';
import DividerIcon from '@images/divider.svg';
import { Icon } from '@crayons';

const ORDERED_LIST_ITEM_REGEX = /^\d+\.\s+.*/;
const MARKDOWN_LINK_REGEX =
  /^\[([\w\s\d]*)\]\((url|(https?:\/\/[\w\d./?=#]+))\)$/;
const URL_PLACEHOLDER_TEXT = 'url';

const NUMBER_OF_NEW_LINES_BEFORE_BLOCK_SYNTAX = 2;
const NUMBER_OF_NEW_LINES_BEFORE_AFTER_SYNTAX = 1;

const getNewLinePrefixSuffixes = ({ selectionStart, selectionEnd, value }) => {
  const numberOfNewLinesBeforeSelection = getNumberOfNewLinesPrecedingSelection(
    { selectionStart, value },
  );
  const numberOfNewLinesFollowingSelection =
    getNumberOfNewLinesFollowingSelection({ selectionEnd, value });

  // We only add new lines if we're not at the beginning of the text area
  const numberOfNewLinesNeededAtStart =
    selectionStart === 0
      ? 0
      : NUMBER_OF_NEW_LINES_BEFORE_BLOCK_SYNTAX -
        numberOfNewLinesBeforeSelection;

  const newLinesPrefix = String.prototype.padStart(
    numberOfNewLinesNeededAtStart,
    '\n',
  );

  const newLinesSuffix =
    numberOfNewLinesFollowingSelection >=
    NUMBER_OF_NEW_LINES_BEFORE_AFTER_SYNTAX
      ? ''
      : '\n';

  return { newLinesPrefix, newLinesSuffix };
};

const handleLinkFormattingForEmptyTextSelection = ({
  textBeforeSelection,
  textAfterSelection,
  value,
  selectionStart,
  selectionEnd,
}) => {
  const basicFormattingForEmptySelection = {
    editSelectionStart: selectionStart,
    editSelectionEnd: selectionEnd,
    replaceSelectionWith: `[](${URL_PLACEHOLDER_TEXT})`,
    newCursorStart: selectionStart + 3,
    newCursorEnd: selectionEnd + 6,
  };

  // Directly after inserting a link with a URL highlighted, cursor is inside the link description '[]'
  // Check if we are inside empty link description remove the link syntax if so
  const directlySurroundedByLinkStructure =
    textBeforeSelection.slice(-1) === '[' &&
    textAfterSelection.slice(0, 2) === '](';

  if (!directlySurroundedByLinkStructure)
    return basicFormattingForEmptySelection;

  // Search for the closing bracket of markdown link
  const indexOfLinkStructureEnd = getNextIndexOfCharacter({
    content: value,
    selectionIndex: selectionStart,
    character: ')',
    breakOnCharacters: [' ', '\n'],
  });

  if (indexOfLinkStructureEnd === -1) return basicFormattingForEmptySelection;

  // Remove the markdown link structure, preserving the link text if it isn't the "url" placeholder
  const urlText = value.slice(selectionEnd + 2, indexOfLinkStructureEnd);

  return {
    editSelectionStart: selectionStart - 1,
    editSelectionEnd: indexOfLinkStructureEnd + 1,
    replaceSelectionWith: urlText === URL_PLACEHOLDER_TEXT ? '' : urlText,
    newCursorStart: selectionStart - 1,
    newCursorEnd: selectionEnd - 1,
  };
};

const handleLinkFormattingForUrlSelection = ({
  textBeforeSelection,
  textAfterSelection,
  value,
  selectionStart,
  selectionEnd,
  selectedText,
}) => {
  const basicFormattingForLinkSelection = {
    editSelectionStart: selectionStart,
    editSelectionEnd: selectionEnd,
    replaceSelectionWith: `[](${selectedText})`,
    newCursorStart: selectionStart + 1,
    newCursorEnd: selectionStart + 1,
  };

  // Check if the text selection is likely inside a currently formatted markdown link
  const directlySurroundedByLinkStructure =
    textBeforeSelection.slice(-2) === '](' &&
    textAfterSelection.slice(0, 1) === ')';

  if (!directlySurroundedByLinkStructure)
    return basicFormattingForLinkSelection;

  // Get the index of where the current link opens so we can get the text inside the square brackets
  const indexOfSyntaxOpen = getLastIndexOfCharacter({
    content: value,
    selectionIndex: selectionStart,
    character: '[',
  });

  // If link syntax is incomplete, format the selection as a link
  if (indexOfSyntaxOpen === -1) return basicFormattingForLinkSelection;

  // Replace the markdown with the link text in square brackets, if available
  let textToReplaceMarkdown = textBeforeSelection.slice(
    indexOfSyntaxOpen + 1,
    -2,
  );

  // If not available, take the URL as long as it's not the placeholder 'url' text
  if (textToReplaceMarkdown === '') {
    textToReplaceMarkdown =
      selectedText === URL_PLACEHOLDER_TEXT ? '' : selectedText;
  }

  return {
    editSelectionStart: indexOfSyntaxOpen,
    editSelectionEnd: selectionEnd + 1,
    replaceSelectionWith: textToReplaceMarkdown,
    newCursorStart: indexOfSyntaxOpen,
    newCursorEnd: indexOfSyntaxOpen + textToReplaceMarkdown.length,
  };
};

const handleUndoMarkdownLinkSelection = ({
  selectedText,
  selectionStart,
  selectionEnd,
}) => {
  const linkDescriptionEnd = getNextIndexOfCharacter({
    content: selectedText,
    selectionIndex: 0,
    character: ']',
  });

  let textToReplaceMarkdown = selectedText.slice(1, linkDescriptionEnd);

  // Keep the URL instead if no link description exists
  if (textToReplaceMarkdown === '') {
    const linkText = selectedText.slice(linkDescriptionEnd + 2, -1);
    textToReplaceMarkdown = linkText === URL_PLACEHOLDER_TEXT ? '' : linkText;
  }

  return {
    editSelectionStart: selectionStart,
    editSelectionEnd: selectionEnd,
    replaceSelectionWith: textToReplaceMarkdown,
    newCursorStart: selectionStart,
    newCursorEnd: selectionStart + textToReplaceMarkdown.length,
  };
};

const isStringStartAUrl = (string) => {
  const startingText = string.substring(0, 8);
  return startingText === 'https://' || startingText.startsWith('http://');
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
  const { selectedText, textBeforeSelection, textAfterSelection } =
    getSelectionData({ selectionStart, selectionEnd, value });

  // Check if selected text has prefix/suffix
  const selectedTextAlreadyFormatted =
    selectedText.slice(0, prefixLength) === prefix &&
    selectedText.slice(-1 * suffixLength) === suffix;

  if (selectedTextAlreadyFormatted) {
    return {
      editSelectionStart: selectionStart,
      editSelectionEnd: selectionEnd,
      replaceSelectionWith: selectedText.slice(prefixLength, -1 * suffixLength),
      newCursorStart: selectionStart,
      newCursorEnd: selectionEnd - (prefixLength + suffixLength),
    };
  }

  // Check if immediate surrounding content has prefix/suffix
  const surroundingTextHasFormatting =
    textBeforeSelection.substring(textBeforeSelection.length - prefixLength) ===
      prefix && textAfterSelection.substring(0, suffixLength) === suffix;

  if (surroundingTextHasFormatting) {
    return {
      editSelectionStart: selectionStart - prefixLength,
      editSelectionEnd: selectionEnd + suffixLength,
      replaceSelectionWith: selectedText,
      newCursorStart: selectionStart - prefixLength,
      newCursorEnd: selectionEnd - prefixLength,
    };
  }

  // No formatting to undo - format the selected text
  return {
    editSelectionStart: selectionStart,
    editSelectionEnd: selectionEnd,
    replaceSelectionWith: `${prefix}${selectedText}${suffix}`,
    newCursorStart: selectionStart + prefixLength,
    newCursorEnd: selectionEnd + prefixLength,
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
  const { selectedText, textBeforeSelection, textAfterSelection } =
    getSelectionData({ selectionStart, selectionEnd, value });

  let formattedText = selectedText;

  if (linePrefix) {
    const { length: prefixLength } = linePrefix;

    // If no selection, check if we're in a freshly inserted syntax
    if (selectedText === '') {
      const lastNewLine =
        textBeforeSelection === ''
          ? -1
          : getLastIndexOfCharacter({
              content: value,
              selectionIndex: selectionStart - 1,
              character: '\n',
            });

      const lineStart = lastNewLine === -1 ? 0 : lastNewLine + 1;

      if (
        textBeforeSelection.slice(lineStart, lineStart + prefixLength) ===
        linePrefix
      ) {
        // Remove the list formatting

        return {
          editSelectionStart: lineStart,
          editSelectionEnd: lineStart + prefixLength,
          replaceSelectionWith: '',
          newCursorStart: selectionStart - prefixLength,
          newCursorEnd: selectionEnd - prefixLength,
        };
      }
    }

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
        editSelectionStart: selectionStart,
        editSelectionEnd: selectionEnd,
        replaceSelectionWith: unformattedText,
        newCursorStart: selectionStart,
        newCursorEnd:
          selectionEnd + (unformattedText.length - selectedText.length),
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
        editSelectionStart: selectionStart,
        editSelectionEnd: selectionEnd,
        replaceSelectionWith: selectedText.slice(
          prefixLength,
          -1 * suffixLength,
        ),
        newCursorStart: selectionStart,
        newCursorEnd: selectionEnd - prefixLength - suffixLength,
      };
    }

    // or does the prefix/suffix plus new line chars immediately precede and follow the selection
    const surroundingTextIsFormatted =
      textBeforeSelection.slice(-1 * prefixLength) === blockPrefix &&
      textAfterSelection.slice(0, suffixLength) === blockSuffix;

    if (surroundingTextIsFormatted) {
      return {
        editSelectionStart: selectionStart - prefixLength,
        editSelectionEnd: selectionEnd + suffixLength,
        replaceSelectionWith: selectedText,
        newCursorStart: selectionStart - prefixLength,
        newCursorEnd: selectionEnd - prefixLength,
      };
    }
  }

  // Add the formatting

  const { newLinesPrefix, newLinesSuffix } = getNewLinePrefixSuffixes({
    selectionStart,
    selectionEnd,
    value,
  });
  const { length: newLinePrefixLength } = newLinesPrefix;

  const cursorStartBaseline = selectionStart + newLinePrefixLength;
  const cursorStartBlockPrefixOffset = blockPrefix ? blockPrefix.length : 0;
  const cursorStartLinePrefixOffset =
    selectedText === '' && linePrefix ? linePrefix.length : 0;

  return {
    editSelectionStart: selectionStart,
    editSelectionEnd: selectionEnd,
    replaceSelectionWith: `${newLinesPrefix}${
      blockPrefix ? blockPrefix : ''
    }${formattedText}${blockSuffix ? blockSuffix : ''}${newLinesSuffix}`,
    newCursorStart:
      cursorStartBaseline +
      cursorStartBlockPrefixOffset +
      cursorStartLinePrefixOffset,
    newCursorEnd:
      selectionEnd +
      formattedText.length -
      selectedText.length +
      newLinePrefixLength +
      (blockPrefix?.length || 0),
  };
};

export const getNewTextAreaValueWithEdits = ({
  textAreaValue,
  editSelectionStart,
  editSelectionEnd,
  replaceSelectionWith,
}) =>
  `${textAreaValue.substring(
    0,
    editSelectionStart,
  )}${replaceSelectionWith}${textAreaValue.substring(editSelectionEnd)}`;

export const markdownSyntaxFormatters = {
  bold: {
    icon: () => <Icon src={BoldIcon} />,
    label: 'Bold',
    getKeyboardShortcut: () => {
      const modifier = getOSKeyboardModifierKeyString();
      return {
        command: `${modifier}+b`,
        tooltipHint: `${modifier.toUpperCase()} + B`,
      };
    },
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
    icon: () => <Icon src={ItalicIcon} />,
    label: 'Italic',
    getKeyboardShortcut: () => {
      const modifier = getOSKeyboardModifierKeyString();
      return {
        command: `${modifier}+i`,
        tooltipHint: `${modifier.toUpperCase()} + I`,
      };
    },
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
    icon: () => <Icon src={LinkIcon} />,
    label: 'Link',
    getKeyboardShortcut: () => {
      const modifier = getOSKeyboardModifierKeyString();
      return {
        command: `${modifier}+k`,
        tooltipHint: `${modifier.toUpperCase()} + K`,
      };
    },
    getFormatting: ({ selectionStart, selectionEnd, value }) => {
      const { selectedText, textBeforeSelection, textAfterSelection } =
        getSelectionData({ selectionStart, selectionEnd, value });

      if (selectedText === '') {
        return handleLinkFormattingForEmptyTextSelection({
          textBeforeSelection,
          textAfterSelection,
          value,
          selectionStart,
          selectionEnd,
        });
      }

      if (
        isStringStartAUrl(selectedText) ||
        selectedText === URL_PLACEHOLDER_TEXT
      ) {
        return handleLinkFormattingForUrlSelection({
          textBeforeSelection,
          textAfterSelection,
          value,
          selectionStart,
          selectedText,
          selectionEnd,
        });
      }

      // If the whole selectedText matches markdown link formatting, undo it
      if (selectedText.match(MARKDOWN_LINK_REGEX)) {
        return handleUndoMarkdownLinkSelection({
          selectedText,
          selectionStart,
          selectionEnd,
          textBeforeSelection,
          textAfterSelection,
        });
      }

      // Finally, handle the case where link syntax is inserted for a selection other than a URL
      return {
        editSelectionStart: selectionStart,
        editSelectionEnd: selectionEnd,
        replaceSelectionWith: `[${selectedText}](${URL_PLACEHOLDER_TEXT})`,
        newCursorStart: selectionStart + selectedText.length + 3,
        newCursorEnd: selectionEnd + 6,
      };
    },
  },
  orderedList: {
    icon: () => <Icon src={OrderedListIcon} />,
    label: 'Ordered list',
    getFormatting: ({ selectionStart, selectionEnd, value }) => {
      const { selectedText, textBeforeSelection } = getSelectionData({
        selectionStart,
        selectionEnd,
        value,
      });

      const { newLinesPrefix, newLinesSuffix } = getNewLinePrefixSuffixes({
        selectionStart,
        selectionEnd,
        value,
      });
      const { length: newLinePrefixLength } = newLinesPrefix;
      const { length: newLineSuffixLength } = newLinesSuffix;

      if (selectedText === '') {
        // Check start of line for whether we're in an empty ordered list
        const lastNewLine =
          textBeforeSelection === ''
            ? -1
            : getLastIndexOfCharacter({
                content: value,
                selectionIndex: selectionStart - 1,
                character: '\n',
              });

        const lineStart = lastNewLine === -1 ? 0 : lastNewLine + 1;

        if (textBeforeSelection.slice(lineStart, lineStart + 3) === '1. ') {
          // Remove the list formatting
          return {
            editSelectionStart: lineStart,
            editSelectionEnd: lineStart + 3,
            replaceSelectionWith: '',
            newCursorStart: selectionStart - 3,
            newCursorEnd: selectionEnd - 3,
          };
        }
      }

      if (selectedText === '') {
        // Otherwise insert an empty list for an empty selection
        return {
          editSelectionStart: selectionStart,
          editSelectionEnd: selectionEnd,
          replaceSelectionWith: `${newLinesPrefix}1. ${newLinesSuffix}`,
          newCursorStart: selectionStart + 3 + newLinePrefixLength,
          newCursorEnd: selectionEnd + 3 + newLinePrefixLength,
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
          editSelectionStart: selectionStart,
          editSelectionEnd: selectionEnd,
          replaceSelectionWith: newText,
          newCursorStart: selectionStart + selectedText.indexOf('.') - 1,
          newCursorEnd: selectionEnd + newText.length - selectedText.length,
        };
      }
      // Otherwise convert to an ordered list
      const formattedList = `${newLinesPrefix}${splitByNewLine
        .map((textChunk, index) => `${index + 1}. ${textChunk}`)
        .join('\n')}${newLinesSuffix}`;

      const cursorOffsetStart =
        selectedText.length === 0 ? 4 : newLinePrefixLength;

      return {
        editSelectionStart: selectionStart,
        editSelectionEnd: selectionEnd,
        replaceSelectionWith: formattedList,
        newCursorStart: selectionStart + cursorOffsetStart,
        newCursorEnd:
          selectionStart + formattedList.length - newLineSuffixLength,
      };
    },
  },
  unorderedList: {
    icon: () => <Icon src={UnorderedListIcon} />,
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
    icon: () => <Icon src={HeadingIcon} />,
    label: 'Heading',
    getFormatting: ({ selectionStart, selectionEnd, value }) => {
      let currentLineSelectionStart = selectionStart;

      // The 'heading' formatter changes insertion based on the existing heading level of the current line
      // So we find the start of the current line and check for '#' characters
      if (selectionStart > 0) {
        const lastNewLine = getLastIndexOfCharacter({
          content: value,
          selectionIndex: selectionStart - 1,
          character: '\n',
        });

        const indexOfFirstLineCharacter =
          lastNewLine === -1 ? 0 : lastNewLine + 1;

        if (value.charAt(indexOfFirstLineCharacter) === '#') {
          currentLineSelectionStart = indexOfFirstLineCharacter;
        }
      }

      const { selectedText } = getSelectionData({
        selectionStart: currentLineSelectionStart,
        selectionEnd,
        value,
      });

      let currentHeadingIndex = 0;
      while (selectedText.charAt(currentHeadingIndex) === '#') {
        currentHeadingIndex++;
      }

      //   After h4, revert to no heading at all
      if (currentHeadingIndex >= 4) {
        return {
          editSelectionStart: currentLineSelectionStart,
          editSelectionEnd: selectionEnd,
          replaceSelectionWith: selectedText.substring(5),
          newCursorStart: selectionStart - 5,
          newCursorEnd: selectionEnd - 5,
        };
      }

      const { newLinesPrefix, newLinesSuffix } = getNewLinePrefixSuffixes({
        selectionStart,
        selectionEnd,
        value,
      });
      const { length: newLinePrefixLength } = newLinesPrefix;

      const adjustingHeading = currentHeadingIndex > 0;
      const cursorOffset = adjustingHeading ? 1 : 3 + newLinePrefixLength;

      return {
        editSelectionStart: adjustingHeading
          ? currentLineSelectionStart
          : selectionStart,
        editSelectionEnd: selectionEnd,
        replaceSelectionWith: adjustingHeading
          ? `#${selectedText}`
          : `${newLinesPrefix}## ${selectedText}${newLinesSuffix}`,
        newCursorStart: selectionStart + cursorOffset,
        newCursorEnd: selectionEnd + cursorOffset,
      };
    },
  },
  quote: {
    icon: () => <Icon src={QuoteIcon} />,
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
    icon: () => <Icon src={CodeIcon} />,
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
    icon: () => <Icon src={CodeBlockIcon} />,
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
  embed: {
    icon: () => <Icon src={EmbedIcon} />,
    label: 'Embed',
    getKeyboardShortcut: () => {
      const modifier = getOSKeyboardModifierKeyString();
      return {
        command: `${modifier}+shift+k`,
        tooltipHint: `${modifier.toUpperCase()} + SHIFT + K`,
      };
    },
    getFormatting: ({ selectionStart, selectionEnd, value }) =>
      undoOrAddFormattingForInlineSyntax({
        value,
        selectionStart,
        selectionEnd,
        prefix: '{% embed ',
        suffix: ' %}',
      }),
  },
  underline: {
    icon: () => <Icon src={UnderlineIcon} />,
    label: 'Underline',
    getKeyboardShortcut: () => {
      const modifier = getOSKeyboardModifierKeyString();
      return {
        command: `${modifier}+u`,
        tooltipHint: `${modifier.toUpperCase()} + U`,
      };
    },
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
    icon: () => <Icon src={StrikethroughIcon} />,
    label: 'Strikethrough',
    getKeyboardShortcut: () => {
      const modifier = getOSKeyboardModifierKeyString();
      return {
        command: `${modifier}+shift+x`,
        tooltipHint: `${modifier.toUpperCase()} + SHIFT + X`,
      };
    },
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
    icon: () => <Icon src={DividerIcon} />,
    label: 'Line divider',
    getFormatting: ({ selectionStart, selectionEnd, value }) =>
      undoOrAddFormattingForMultilineSyntax({
        selectionStart,
        selectionEnd,
        value,
        blockPrefix: '---\n',
        blockSuffix: '',
      }),
  },
};
