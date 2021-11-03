/* global Runtime */
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

const isStringStartAUrl = (string) => {
  const startingText = string.substring(0, 8);
  return startingText === 'https://' || startingText.startsWith('http://');
};

export const coreSyntaxFormatters = {
  bold: {
    icon: Bold,
    label: 'Bold',
    getKeyboardShortcut: () => {
      const modifier = Runtime.getOSKeyboardModifierKeyString();
      return {
        command: `${modifier}+b`,
        tooltipHint: `${modifier.toUpperCase()} + B`,
      };
    },
    getFormatting: (selection) => ({
      formattedText: `**${selection}**`,
      cursorOffsetStart: 2,
      cursorOffsetEnd: 2,
    }),
  },
  italic: {
    icon: Italic,
    label: 'Italic',
    getKeyboardShortcut: () => {
      const modifier = Runtime.getOSKeyboardModifierKeyString();
      return {
        command: `${modifier}+i`,
        tooltipHint: `${modifier.toUpperCase()} + I`,
      };
    },
    getFormatting: (selection) => ({
      formattedText: `_${selection}_`,
      cursorOffsetStart: 1,
      cursorOffsetEnd: 1,
    }),
  },
  link: {
    icon: Link,
    label: 'Link',
    getKeyboardShortcut: () => {
      const modifier = Runtime.getOSKeyboardModifierKeyString();
      return {
        command: `${modifier}+k`,
        tooltipHint: `${modifier.toUpperCase()} + K`,
      };
    },
    getFormatting: (selection) => {
      const isUrl = isStringStartAUrl(selection);
      const selectionLength = selection.length;

      if (selectionLength === 0) {
        return {
          formattedText: '[](url)',
          cursorOffsetStart: 1,
          cursorOffsetEnd: 1,
        };
      }

      return {
        formattedText: isUrl ? `[](${selection})` : `[${selection}](url)`,
        cursorOffsetStart: isUrl ? 1 : selectionLength + 3,
        cursorOffsetEnd: isUrl ? -1 * (selectionLength - 1) : 6,
      };
    },
  },
  orderedList: {
    icon: OrderedList,
    label: 'Ordered list',
    getFormatting: (selection) => {
      let newString = `\n${selection
        .split('\n')
        .map((textChunk, index) => `${index + 1}. ${textChunk}`)
        .join('\n')}`;

      if (selection !== '') {
        newString += '\n';
      }

      return {
        formattedText: newString,
        cursorOffsetStart: selection.length === 0 ? 4 : 1,
        cursorOffsetEnd: newString.length - selection.length,
      };
    },
  },
  unorderedList: {
    icon: UnorderedList,
    label: 'Unordered list',
    getFormatting: (selection) => {
      const bulletedSelection = selection.replace(/\n/g, '\n- ');
      let newString = `\n- ${bulletedSelection}`;

      if (selection !== '') {
        newString += '\n';
      }

      return {
        formattedText: newString,
        cursorOffsetStart: selection.length === 0 ? 3 : 1,
        cursorOffsetEnd: newString.length - selection.length,
      };
    },
  },
  heading: {
    icon: Heading,
    label: 'Heading',
    getFormatting: (selection) => {
      let currentHeadingIndex = 0;
      while (selection.charAt(currentHeadingIndex) === '#') {
        currentHeadingIndex++;
      }

      //   Only allow up to h4
      if (currentHeadingIndex === 4) {
        return {
          formattedText: selection,
          cursorOffsetStart: 5,
          cursorOffsetEnd: 0,
        };
      }

      const adjustingHeading = currentHeadingIndex > 0;

      return {
        formattedText: adjustingHeading
          ? `#${selection}`
          : `\n## ${selection}\n`,
        cursorOffsetStart: adjustingHeading ? currentHeadingIndex + 2 : 4,
        cursorOffsetEnd: adjustingHeading ? 1 : 4,
      };
    },
  },
  quote: {
    icon: Quote,
    label: 'Quote',
    getFormatting: (selection) => {
      const quotedSelection = selection.replace(/\n/g, '\n> ');
      const newString = `\n> ${quotedSelection}\n`;
      return {
        formattedText: newString,
        cursorOffsetStart: 3,
        cursorOffsetEnd:
          selection === '' ? 3 : newString.length - selection.length,
      };
    },
  },
  code: {
    icon: Code,
    label: 'Code',
    getFormatting: (selection) => ({
      formattedText: `\`${selection}\``,
      cursorOffsetStart: 1,
      cursorOffsetEnd: 1,
    }),
  },
  codeBlock: {
    icon: CodeBlock,
    label: 'Code block',
    getFormatting: (selection) => ({
      formattedText: `\n\`\`\`\n${selection}\n\`\`\`\n`,
      cursorOffsetStart: 5,
      cursorOffsetEnd: 5,
    }),
  },
};

export const secondarySyntaxFormatters = {
  underline: {
    icon: Underline,
    label: 'Underline',
    getKeyboardShortcut: () => {
      const modifier = Runtime.getOSKeyboardModifierKeyString();
      return {
        command: `${modifier}+u`,
        tooltipHint: `${modifier.toUpperCase()} + U`,
      };
    },
    getFormatting: (selection) => ({
      formattedText: `<u>${selection}</u>`,
      cursorOffsetStart: 3,
      cursorOffsetEnd: 3,
    }),
  },
  strikethrough: {
    icon: Strikethrough,
    label: 'Strikethrough',
    getKeyboardShortcut: () => {
      const modifier = Runtime.getOSKeyboardModifierKeyString();
      return {
        command: `${modifier}+shift+x`,
        tooltipHint: `${modifier.toUpperCase()} + SHIFT + X`,
      };
    },
    getFormatting: (selection) => ({
      formattedText: `~~${selection}~~`,
      cursorOffsetStart: 2,
      cursorOffsetEnd: 2,
    }),
  },
  divider: {
    icon: Divider,
    label: 'Line divider',
    getFormatting: (selection) => ({
      formattedText: `${selection}\n---\n`,
      cursorOffsetStart: selection.length + 5,
      cursorOffsetEnd: selection.length + 5,
    }),
  },
};
