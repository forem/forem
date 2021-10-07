import {
  coreSyntaxFormatters,
  secondarySyntaxFormatters,
} from '../markdownSyntaxFormatters';

describe('markdownSntaxFormatters', () => {
  const exampleTextSelection = 'selection';

  it('formats bold text', () => {
    expect(
      coreSyntaxFormatters['bold'].getFormatting(exampleTextSelection),
    ).toEqual({
      formattedText: '**selection**',
      cursorOffsetStart: 2,
      cursorOffsetEnd: 2,
    });
  });

  it('formats italic text', () => {
    expect(
      coreSyntaxFormatters['italic'].getFormatting(exampleTextSelection),
    ).toEqual({
      formattedText: '_selection_',
      cursorOffsetStart: 1,
      cursorOffsetEnd: 1,
    });
  });

  it('formats a link with an empty selection', () => {
    expect(coreSyntaxFormatters['link'].getFormatting('')).toEqual({
      formattedText: '[](url)',
      cursorOffsetStart: 1,
      cursorOffsetEnd: 1,
    });
  });

  it('formats a link with a non-URL selection', () => {
    expect(
      coreSyntaxFormatters['link'].getFormatting(exampleTextSelection),
    ).toEqual({
      formattedText: '[selection](url)',
      cursorOffsetStart: 1,
      cursorOffsetEnd: 1,
    });
  });

  it('formats a link with an http URL selection', () => {
    expect(
      coreSyntaxFormatters['link'].getFormatting('http://myurl.com'),
    ).toEqual({
      formattedText: '[](http://myurl.com)',
      cursorOffsetStart: 3,
      cursorOffsetEnd: 3,
    });
  });

  it('formats a link with an https URL selection', () => {
    expect(
      coreSyntaxFormatters['link'].getFormatting('https://myurl.com'),
    ).toEqual({
      formattedText: '[](https://myurl.com)',
      cursorOffsetStart: 3,
      cursorOffsetEnd: 3,
    });
  });

  it('formats an unordered list from an empty selection', () => {
    expect(coreSyntaxFormatters['unorderedList'].getFormatting('')).toEqual({
      formattedText: '- ',
      cursorOffsetStart: 2,
      cursorOffsetEnd: 2,
      insertOnNewLine: true,
    });
  });

  it('formats an unordered list from a single line selection', () => {
    expect(
      coreSyntaxFormatters['unorderedList'].getFormatting(exampleTextSelection),
    ).toEqual({
      formattedText: '- selection',
      cursorOffsetStart: 0,
      cursorOffsetEnd: 2,
      insertOnNewLine: true,
    });
  });

  it('formats an unordered list from a multi-line selection', () => {
    expect(
      coreSyntaxFormatters['unorderedList'].getFormatting('one\ntwo'),
    ).toEqual({
      formattedText: '- one\n- two',
      cursorOffsetStart: 0,
      cursorOffsetEnd: 4,
      insertOnNewLine: true,
    });
  });

  it('formats an ordered list from an empty selection', () => {
    expect(coreSyntaxFormatters['orderedList'].getFormatting('')).toEqual({
      formattedText: '1. ',
      cursorOffsetStart: 3,
      cursorOffsetEnd: 3,
      insertOnNewLine: true,
    });
  });

  it('formats an ordered list from a single line selection', () => {
    expect(
      coreSyntaxFormatters['orderedList'].getFormatting(exampleTextSelection),
    ).toEqual({
      formattedText: '1. selection',
      cursorOffsetStart: 0,
      cursorOffsetEnd: 3,
      insertOnNewLine: true,
    });
  });

  it('formats an ordered list from a multi-line selection', () => {
    expect(
      coreSyntaxFormatters['orderedList'].getFormatting('one\ntwo'),
    ).toEqual({
      formattedText: '1. one\n2. two',
      cursorOffsetStart: 0,
      cursorOffsetEnd: 6,
      insertOnNewLine: true,
    });
  });

  it('Formats a heading from an empty selection', () => {
    expect(coreSyntaxFormatters['heading'].getFormatting('')).toEqual({
      formattedText: '## ',
      cursorOffsetStart: 3,
      cursorOffsetEnd: 3,
    });
  });

  it('Formats a heading from a selection with no heading level', () => {
    expect(
      coreSyntaxFormatters['heading'].getFormatting(exampleTextSelection),
    ).toEqual({
      formattedText: '## selection',
      cursorOffsetStart: 3,
      cursorOffsetEnd: 3,
    });
  });

  it('Formats a heading from a selection with a heading level 2', () => {
    expect(
      coreSyntaxFormatters['heading'].getFormatting('## selection'),
    ).toEqual({
      formattedText: '### selection',
      cursorOffsetStart: 4,
      cursorOffsetEnd: 1,
    });
  });

  it('Formats a heading from a selection with a heading level 3', () => {
    expect(
      coreSyntaxFormatters['heading'].getFormatting('### selection'),
    ).toEqual({
      formattedText: '#### selection',
      cursorOffsetStart: 5,
      cursorOffsetEnd: 1,
    });
  });

  it('Formats a heading from a selection with a heading level 4 by returning same selection', () => {
    expect(
      coreSyntaxFormatters['heading'].getFormatting('#### selection'),
    ).toEqual({
      formattedText: '#### selection',
      cursorOffsetStart: 5,
      cursorOffsetEnd: 0,
    });
  });

  it('formats a quote with empty selection', () => {
    expect(coreSyntaxFormatters['quote'].getFormatting('')).toEqual({
      formattedText: '> ',
      cursorOffsetStart: 2,
      cursorOffsetEnd: 2,
      insertOnNewLine: true,
    });
  });

  it('formats a quote on a single-line selection', () => {
    expect(
      coreSyntaxFormatters['quote'].getFormatting(exampleTextSelection),
    ).toEqual({
      formattedText: '> selection',
      cursorOffsetStart: 2,
      cursorOffsetEnd: 2,
      insertOnNewLine: true,
    });
  });

  it('formats a quote on a multi-line selection', () => {
    expect(coreSyntaxFormatters['quote'].getFormatting('one\ntwo')).toEqual({
      formattedText: '> one\n> two',
      cursorOffsetStart: 2,
      cursorOffsetEnd: 4,
      insertOnNewLine: true,
    });
  });

  it('formats inline code', () => {
    expect(
      coreSyntaxFormatters['code'].getFormatting(exampleTextSelection),
    ).toEqual({
      formattedText: '`selection`',
      cursorOffsetStart: 1,
      cursorOffsetEnd: 1,
    });
  });

  it('formats a code block', () => {
    expect(
      coreSyntaxFormatters['codeBlock'].getFormatting(exampleTextSelection),
    ).toEqual({
      formattedText: '```\nselection\n```',
      cursorOffsetStart: 4,
      cursorOffsetEnd: 4,
      insertOnNewLine: true,
    });
  });

  it('formats underline text', () => {
    expect(
      secondarySyntaxFormatters['underline'].getFormatting(
        exampleTextSelection,
      ),
    ).toEqual({
      formattedText: '<u>selection</u>',
      cursorOffsetStart: 3,
      cursorOffsetEnd: 3,
    });
  });

  it('formats strikethrough text', () => {
    expect(
      secondarySyntaxFormatters['strikethrough'].getFormatting(
        exampleTextSelection,
      ),
    ).toEqual({
      formattedText: '~~selection~~',
      cursorOffsetStart: 2,
      cursorOffsetEnd: 2,
    });
  });

  it('adds a line divider when selection is empty', () => {
    expect(secondarySyntaxFormatters['divider'].getFormatting('')).toEqual({
      formattedText: '\n---\n',
      cursorOffsetStart: 5,
      cursorOffsetEnd: 5,
    });
  });

  it('adds a line divider after given selection ', () => {
    expect(
      secondarySyntaxFormatters['divider'].getFormatting(exampleTextSelection),
    ).toEqual({
      formattedText: 'selection\n---\n',
      cursorOffsetStart: 14,
      cursorOffsetEnd: 14,
    });
  });
});
