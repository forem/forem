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
    keyboardShortcut: 'ctrl+b',
    keyboardShortcutKeys: `B`,
    getFormatting: (selection) => ({
      formattedText: `**${selection}**`,
      cursorOffsetStart: 2,
      cursorOffsetEnd: 2,
    }),
  },
  italic: {
    icon: Italic,
    label: 'Italic',
    keyboardShortcut: 'ctrl+i',
    keyboardShortcutKeys: `I`,
    getFormatting: (selection) => ({
      formattedText: `_${selection}_`,
      cursorOffsetStart: 1,
      cursorOffsetEnd: 1,
    }),
  },
  link: {
    icon: Link,
    label: 'Link',
    keyboardShortcut: 'ctrl+k',
    keyboardShortcutKeys: `K`,
    getFormatting: (selection) => {
      const isUrl = isStringStartAUrl(selection);
      const selectionLength = selection.length;
      return {
        formattedText: isUrl ? `[](${selection})` : `[${selection}](url)`,
        cursorOffsetStart: isUrl ? 1 : selectionLength + 3,
        cursorOffsetEnd: isUrl
          ? -1 * (selectionLength - 1)
          : selectionLength - 2,
      };
    },
  },
  orderedList: {
    icon: OrderedList,
    label: 'Ordered list',
    getFormatting: (selection) => {
      let newString = selection
        .split('\n')
        .map((textChunk, index) => `${index + 1}. ${textChunk}`)
        .join('\n');

      if (selection !== '') {
        newString += '\n';
      }

      return {
        formattedText: newString,
        cursorOffsetStart: selection.length === 0 ? 3 : 0,
        cursorOffsetEnd: newString.length - selection.length,
        insertOnNewLine: true,
      };
    },
  },
  unorderedList: {
    icon: UnorderedList,
    label: 'Unordered list',
    getFormatting: (selection) => {
      let newString = `- ${selection}`.replace(/\n/g, '\n- ');

      if (selection !== '') {
        newString += '\n';
      }

      return {
        formattedText: newString,
        cursorOffsetStart: selection.length === 0 ? 2 : 0,
        cursorOffsetEnd: newString.length - selection.length,
        insertOnNewLine: true,
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
        formattedText: adjustingHeading ? `#${selection}` : `## ${selection}`,
        cursorOffsetStart: adjustingHeading ? currentHeadingIndex + 2 : 3,
        cursorOffsetEnd: adjustingHeading ? 1 : 3,
      };
    },
  },
  quote: {
    icon: Quote,
    label: 'Quote',
    getFormatting: (selection) => {
      const newString = `> ${selection}`.replace(/\n/g, '\n> ');
      return {
        formattedText: newString,
        cursorOffsetStart: 2,
        cursorOffsetEnd:
          selection === '' ? 2 : newString.length - selection.length,
        insertOnNewLine: true,
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
      formattedText: `\`\`\`\n${selection}\n\`\`\`\n`,
      cursorOffsetStart: 4,
      cursorOffsetEnd: 4,
      insertOnNewLine: true,
    }),
  },
};

export const secondarySyntaxFormatters = {
  underline: {
    icon: Underline,
    label: 'Underline',
    keyboardShortcut: 'ctrl+u',
    keyboardShortcutKeys: `U`,
    getFormatting: (selection) => ({
      formattedText: `<u>${selection}</u>`,
      cursorOffsetStart: 3,
      cursorOffsetEnd: 3,
    }),
  },
  strikethrough: {
    icon: Strikethrough,
    label: 'Strikethrough',
    keyboardShortcut: 'ctrl+shift+x',
    keyboardShortcutKeys: `SHIFT + X`,
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
