import {
  coreSyntaxFormatters,
  secondarySyntaxFormatters,
} from '../markdownSyntaxFormatters';

describe('markdownSyntaxFormatters', () => {
  describe('inline formatters', () => {
    describe('bold', () => {
      it('Formats selected text as bold, keeping selected text highlighted', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one **two** three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['bold'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats an empty selection as bold, keeping cursor inside formatting', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one ****two three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['bold'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 4,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(newCursorStart).toEqual(6);
        expect(newCursorEnd).toEqual(6);
      });

      it('Unformats a selection that starts and ends with bold formatting', () => {
        const textAreaValue = 'one **two** three';
        const expectedNewTextAreaValue = 'one two three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['bold'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 11,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats a selection as bold, when only the start of the selection already has bold formatting', () => {
        const textAreaValue = 'one **two three';
        const expectedNewTextAreaValue = 'one ****two** three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['bold'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 9,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('**two');
      });

      it('Formats a selection as bold, when only the end of the selection already has bold formatting', () => {
        const textAreaValue = 'one two** three';
        const expectedNewTextAreaValue = 'one **two**** three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['bold'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 9,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two**');
      });

      it('Unformats a selection when text immediately before and after have bold formatting', () => {
        const textAreaValue = 'one **two** three';
        const expectedNewTextAreaValue = 'one two three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['bold'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 11,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats a selection as bold, when only the text immediately before already has bold formatting', () => {
        const textAreaValue = 'one **two three';
        const expectedNewTextAreaValue = 'one ****two** three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['bold'].getFormatting({
            value: textAreaValue,
            selectionStart: 6,
            selectionEnd: 9,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats a selection as bold, when only the text immediately after already has bold formatting', () => {
        const textAreaValue = 'one two** three';
        const expectedNewTextAreaValue = 'one **two**** three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['bold'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });
    });

    describe('italic', () => {
      it('Formats selected text as italic, keeping selected text highlighted', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one _two_ three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['italic'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats an empty selection as italic, keeping cursor inside formatting', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one __two three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['italic'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 4,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(newCursorStart).toEqual(5);
        expect(newCursorEnd).toEqual(5);
      });

      it('Unformats a selection that starts and ends with italic formatting', () => {
        const textAreaValue = 'one _two_ three';
        const expectedNewTextAreaValue = 'one two three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['italic'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 9,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats a selection as italic, when only the start of the selection already has italic formatting', () => {
        const textAreaValue = 'one _two three';
        const expectedNewTextAreaValue = 'one __two_ three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['italic'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 8,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('_two');
      });

      it('Formats a selection as italic, when only the end of the selection already has italic formatting', () => {
        const textAreaValue = 'one two_ three';
        const expectedNewTextAreaValue = 'one _two__ three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['italic'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 8,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two_');
      });

      it('Unformats a selection when text immediately before and after have italic formatting', () => {
        const textAreaValue = 'one _two_ three';
        const expectedNewTextAreaValue = 'one two three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['italic'].getFormatting({
            value: textAreaValue,
            selectionStart: 5,
            selectionEnd: 8,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats a selection as italic, when only the text immediately before already has italic formatting', () => {
        const textAreaValue = 'one _two three';
        const expectedNewTextAreaValue = 'one __two_ three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['italic'].getFormatting({
            value: textAreaValue,
            selectionStart: 5,
            selectionEnd: 8,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats a selection as italic, when only the text immediately after already has italic formatting', () => {
        const textAreaValue = 'one two_ three';
        const expectedNewTextAreaValue = 'one _two__ three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['italic'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });
    });

    describe('code', () => {
      it('Formats selected text as code, keeping selected text highlighted', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one `two` three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['code'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats an empty selection as code, keeping cursor inside formatting', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one ``two three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['code'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 4,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(newCursorStart).toEqual(5);
        expect(newCursorEnd).toEqual(5);
      });

      it('Unformats a selection that starts and ends with code formatting', () => {
        const textAreaValue = 'one `two` three';
        const expectedNewTextAreaValue = 'one two three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['code'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 9,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats a selection as code, when only the start of the selection already has code formatting', () => {
        const textAreaValue = 'one `two three';
        const expectedNewTextAreaValue = 'one ``two` three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['code'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 8,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('`two');
      });

      it('Formats a selection as code, when only the end of the selection already has code formatting', () => {
        const textAreaValue = 'one two` three';
        const expectedNewTextAreaValue = 'one `two`` three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['code'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 8,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two`');
      });

      it('Unformats a selection when text immediately before and after have code formatting', () => {
        const textAreaValue = 'one `two` three';
        const expectedNewTextAreaValue = 'one two three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['code'].getFormatting({
            value: textAreaValue,
            selectionStart: 5,
            selectionEnd: 8,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats a selection as code, when only the text immediately before already has italic formatting', () => {
        const textAreaValue = 'one `two three';
        const expectedNewTextAreaValue = 'one ``two` three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['code'].getFormatting({
            value: textAreaValue,
            selectionStart: 5,
            selectionEnd: 8,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats a selection as code, when only the text immediately after already has code formatting', () => {
        const textAreaValue = 'one two` three';
        const expectedNewTextAreaValue = 'one `two`` three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['code'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });
    });

    describe('underline', () => {
      it('Formats selected text as underline, keeping selected text highlighted', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one <u>two</u> three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['underline'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats an empty selection as underline, keeping cursor inside formatting', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one <u></u>two three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['underline'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 4,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(newCursorStart).toEqual(7);
        expect(newCursorEnd).toEqual(7);
      });

      it('Unformats a selection that starts and ends with underline formatting', () => {
        const textAreaValue = 'one <u>two</u> three';
        const expectedNewTextAreaValue = 'one two three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['underline'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 14,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats a selection as underline, when only the start of the selection already has underline formatting', () => {
        const textAreaValue = 'one <u>two three';
        const expectedNewTextAreaValue = 'one <u><u>two</u> three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['underline'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 10,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('<u>two');
      });

      it('Formats a selection as underline, when only the end of the selection already has underline formatting', () => {
        const textAreaValue = 'one two</u> three';
        const expectedNewTextAreaValue = 'one <u>two</u></u> three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['underline'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 11,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two</u>');
      });

      it('Unformats a selection when text immediately before and after have underline formatting', () => {
        const textAreaValue = 'one <u>two</u> three';
        const expectedNewTextAreaValue = 'one two three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['underline'].getFormatting({
            value: textAreaValue,
            selectionStart: 7,
            selectionEnd: 10,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats a selection as underline, when only the text immediately before already has underline formatting', () => {
        const textAreaValue = 'one <u>two three';
        const expectedNewTextAreaValue = 'one <u><u>two</u> three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['underline'].getFormatting({
            value: textAreaValue,
            selectionStart: 7,
            selectionEnd: 10,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats a selection as underline, when only the text immediately after already has underline formatting', () => {
        const textAreaValue = 'one two</u> three';
        const expectedNewTextAreaValue = 'one <u>two</u></u> three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['underline'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });
    });

    describe('strikethrough', () => {
      it('Formats selected text as strikethrough, keeping selected text highlighted', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one ~~two~~ three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['strikethrough'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats an empty selection as strikethrough, keeping cursor inside formatting', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one ~~~~two three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['strikethrough'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 4,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(newCursorStart).toEqual(6);
        expect(newCursorEnd).toEqual(6);
      });

      it('Unformats a selection that starts and ends with strikethrough formatting', () => {
        const textAreaValue = 'one ~~two~~ three';
        const expectedNewTextAreaValue = 'one two three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['strikethrough'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 11,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats a selection as strikethrough, when only the start of the selection already has strikethrough formatting', () => {
        const textAreaValue = 'one ~~two three';
        const expectedNewTextAreaValue = 'one ~~~~two~~ three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['strikethrough'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 9,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('~~two');
      });

      it('Formats a selection as strikethrough, when only the end of the selection already has strikethrough formatting', () => {
        const textAreaValue = 'one two~~ three';
        const expectedNewTextAreaValue = 'one ~~two~~~~ three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['strikethrough'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 9,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two~~');
      });

      it('Unformats a selection when text immediately before and after have strikethrough formatting', () => {
        const textAreaValue = 'one ~~two~~ three';
        const expectedNewTextAreaValue = 'one two three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['strikethrough'].getFormatting({
            value: textAreaValue,
            selectionStart: 6,
            selectionEnd: 9,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats a selection as strikethrough, when only the text immediately before already has strikethrough formatting', () => {
        const textAreaValue = 'one ~~two three';
        const expectedNewTextAreaValue = 'one ~~~~two~~ three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['strikethrough'].getFormatting({
            value: textAreaValue,
            selectionStart: 6,
            selectionEnd: 9,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('Formats a selection as strikethrough, when only the text immediately after already has strikethrough formatting', () => {
        const textAreaValue = 'one two~~ three';
        const expectedNewTextAreaValue = 'one ~~two~~~~ three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['strikethrough'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });
    });

    // TODO:
    describe('link', () => {
      it.todo(
        'inserts placeholder link, and highlights url when no selection is given',
      );

      it.todo(
        'inserts link markdown, and highlights url when selected text does not begin with http:// or https://',
      );

      it.todo(
        'inserts link markdown, and places cursor inside [], when selected text begins with http://',
      );

      it.todo(
        'inserts link markdown, and places cursor inside [], when selected text begins with https://',
      );

      it.todo(
        'removes link markdown when no text selected, cursor inside [], and markdown formatting present',
      );

      it.todo(
        'removes link markdown when placeholder url is selected, and full markdown formatting present',
      );

      it.todo(
        'removes link markdown when selected text is a url and full markdown formatting present',
      );

      it.todo(
        'removes link markdown when full markdown syntax is selected, preserving link description',
      );

      it.todo(
        'removes link markdown when full markdown syntax is selected, preserving URL if link description does not exist',
      );

      it.todo(
        'removes link markdown when full markdown syntax is selected, preserving no content if no link description exists, and URL is placeholder',
      );
    });
  });

  describe('multiline formatters', () => {
    describe('orderedList', () => {
      it('formats a single line selection as an ordered list', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one \n\n1. two\n three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['orderedList'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('1. two');
      });

      it('formats multiple lines of text as an ordered list', () => {
        const textAreaValue = 'one\ntwo\nthree';
        const expectedNewTextAreaValue = '\n\n1. one\n2. two\n3. three\n';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['orderedList'].getFormatting({
            value: textAreaValue,
            selectionStart: 0,
            selectionEnd: 13,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('1. one\n2. two\n3. three');
      });

      it('inserts an empty list when no selection is provided', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one \n\n1. \ntwo three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['orderedList'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 4,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('');
      });

      it('unformats a single line of text if selection starts with ordered list format', () => {
        const textAreaValue = 'one\n1. two\nthree';
        const expectedNewTextAreaValue = 'one\ntwo\nthree';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['orderedList'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 10,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      // TODO:
      it.todo(
        'unformats a single line of text if no selection is given, and current line only contains 1. ',
      );

      it('unformats multiple lines of text if every line starts with ordered list format', () => {
        const textAreaValue = '1. one\n2. two\n3. three';
        const expectedNewTextAreaValue = 'one\ntwo\nthree';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['orderedList'].getFormatting({
            value: textAreaValue,
            selectionStart: 0,
            selectionEnd: 22,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual(expectedNewTextAreaValue);
      });

      it("formats as an ordered list if at least one line of selection doesn't match ordered list format", () => {
        const textAreaValue = '1. one\ntwo\n3. three';
        const expectedNewTextAreaValue = '\n\n1. 1. one\n2. two\n3. 3. three\n';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['orderedList'].getFormatting({
            value: textAreaValue,
            selectionStart: 0,
            selectionEnd: 19,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('1. 1. one\n2. two\n3. 3. three');
      });
    });

    describe('unorderedList', () => {
      it('formats a single line selection as an unordered list', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one \n\n- two\n three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['unorderedList'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('- two');
      });

      it('formats multiple lines of text as an unordered list', () => {
        const textAreaValue = 'one\ntwo\nthree';
        const expectedNewTextAreaValue = '\n\n- one\n- two\n- three\n';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['unorderedList'].getFormatting({
            value: textAreaValue,
            selectionStart: 0,
            selectionEnd: 13,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('- one\n- two\n- three');
      });

      it('inserts an empty list when no selection is provided', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one \n\n- \ntwo three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['unorderedList'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 4,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('');
      });

      it('unformats a single line of text if selection starts with unordered list format', () => {
        const textAreaValue = 'one\n- two\nthree';
        const expectedNewTextAreaValue = 'one\ntwo\nthree';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['unorderedList'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 9,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      // TODO:
      it.todo(
        'unformats a single line of text if no selection is given, and current line only contains - ',
      );

      it('unformats multiple lines of text if every line starts with unordered list format', () => {
        const textAreaValue = '- one\n- two\n- three';
        const expectedNewTextAreaValue = 'one\ntwo\nthree';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['unorderedList'].getFormatting({
            value: textAreaValue,
            selectionStart: 0,
            selectionEnd: 20,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual(newTextAreaValue);
      });

      it("formats as an unordered list if at least one line of selection doesn't match unordered list format", () => {
        const textAreaValue = '- one\ntwo\n- three';
        const expectedNewTextAreaValue = '\n\n- - one\n- two\n- - three\n';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['unorderedList'].getFormatting({
            value: textAreaValue,
            selectionStart: 0,
            selectionEnd: 17,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('- - one\n- two\n- - three');
      });
    });

    describe('heading', () => {
      it('inserts a level 2 heading when no selection given, and no current heading on the same line', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one \n\n## \ntwo three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['heading'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 4,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(newCursorStart).toEqual(9);
        expect(newCursorEnd).toEqual(9);
      });

      it('inserts a level 2 heading when text selected and line does not include a heading level', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one \n\n## two\n three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['heading'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(newCursorStart).toEqual(9);
        expect(newCursorEnd).toEqual(12);
      });

      it('changes a level 2 to a level 3 heading when no selection given, and line begins with ##', () => {
        const textAreaValue = 'one\n\n## two\nthree';
        const expectedNewTextAreaValue = 'one\n\n### two\nthree';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['heading'].getFormatting({
            value: textAreaValue,
            selectionStart: 11,
            selectionEnd: 11,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(newCursorStart).toEqual(12);
        expect(newCursorEnd).toEqual(12);
      });

      it('changes a level 2 to a level 3 heading when text selected, and line begins with ##', () => {
        const textAreaValue = 'one\n\n## two\nthree';
        const expectedNewTextAreaValue = 'one\n\n### two\nthree';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['heading'].getFormatting({
            value: textAreaValue,
            selectionStart: 8,
            selectionEnd: 11,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(newCursorStart).toEqual(9);
        expect(newCursorEnd).toEqual(12);
      });

      it('changes a level 3 to a level 4 heading when no selection given, and line begins with ###', () => {
        const textAreaValue = 'one\n\n### two\nthree';
        const expectedNewTextAreaValue = 'one\n\n#### two\nthree';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['heading'].getFormatting({
            value: textAreaValue,
            selectionStart: 12,
            selectionEnd: 12,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(newCursorStart).toEqual(13);
        expect(newCursorEnd).toEqual(13);
      });

      it('changes a level 3 to a level 4 heading when text selected, and line begins with ###', () => {
        const textAreaValue = 'one\n\n### two\nthree';
        const expectedNewTextAreaValue = 'one\n\n#### two\nthree';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['heading'].getFormatting({
            value: textAreaValue,
            selectionStart: 9,
            selectionEnd: 12,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(newCursorStart).toEqual(10);
        expect(newCursorEnd).toEqual(13);
      });

      it('removes a heading when no text selected and line begins with ####', () => {
        const textAreaValue = 'one\n\n#### two\nthree';
        const expectedNewTextAreaValue = 'one\n\ntwo\nthree';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['heading'].getFormatting({
            value: textAreaValue,
            selectionStart: 13,
            selectionEnd: 13,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(newCursorStart).toEqual(8);
        expect(newCursorEnd).toEqual(8);
      });

      it('removes a heading when text selected and line begins with ####', () => {
        const textAreaValue = 'one\n\n#### two\nthree';
        const expectedNewTextAreaValue = 'one\n\ntwo\nthree';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['heading'].getFormatting({
            value: textAreaValue,
            selectionStart: 10,
            selectionEnd: 13,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(newCursorStart).toEqual(5);
        expect(newCursorEnd).toEqual(8);
      });
    });

    describe('quote', () => {
      it('formats a single line selection as a quote', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one \n\n> two\n three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['quote'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('> two');
      });

      it('formats multiple lines of text as a quote', () => {
        const textAreaValue = 'one\ntwo\nthree';
        const expectedNewTextAreaValue = '\n\n> one\n> two\n> three\n';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['quote'].getFormatting({
            value: textAreaValue,
            selectionStart: 0,
            selectionEnd: 13,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('> one\n> two\n> three');
      });

      it('inserts an empty quote when no selection is provided', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one \n\n> \ntwo three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['quote'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 4,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('');
      });

      it('unformats a single line of text if selection starts with quote format', () => {
        const textAreaValue = 'one\n> two\nthree';
        const expectedNewTextAreaValue = 'one\ntwo\nthree';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['quote'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 9,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      // TODO:
      it.todo(
        'unformats a single line of text if no selection is given, and current line only contains > ',
      );

      it('unformats multiple lines of text if every line starts with quote format', () => {
        const textAreaValue = '> one\n> two\n> three';
        const expectedNewTextAreaValue = 'one\ntwo\nthree';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['quote'].getFormatting({
            value: textAreaValue,
            selectionStart: 0,
            selectionEnd: 20,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual(newTextAreaValue);
      });

      it("formats as a quote if at least one line of selection doesn't match quote format", () => {
        const textAreaValue = '> one\ntwo\n> three';
        const expectedNewTextAreaValue = '\n\n> > one\n> two\n> > three\n';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['quote'].getFormatting({
            value: textAreaValue,
            selectionStart: 0,
            selectionEnd: 17,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('> > one\n> two\n> > three');
      });
    });

    describe('codeBlock', () => {
      it('formats a single line selection as a code block', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one \n\n```\ntwo\n```\n three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['codeBlock'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('formats multiple lines of text as a code block', () => {
        const textAreaValue = 'one\ntwo\nthree';
        const expectedNewTextAreaValue = '\n\n```\none\ntwo\nthree\n```\n';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['codeBlock'].getFormatting({
            value: textAreaValue,
            selectionStart: 0,
            selectionEnd: 13,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('one\ntwo\nthree');
      });

      it('inserts an empty code block when no selection is provided', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one \n\n```\n\n```\ntwo three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['codeBlock'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 4,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('');
      });

      it('unformats a single line of text if selection is wrapped in a code block', () => {
        const textAreaValue = 'one\n\n```\ntwo\n```\nthree';
        const expectedNewTextAreaValue = 'one\n\ntwo\nthree';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['codeBlock'].getFormatting({
            value: textAreaValue,
            selectionStart: 9,
            selectionEnd: 12,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('unformats multiple lines of text if selection is wrapped in a code block', () => {
        const textAreaValue = 'one\n\n```\ntwo\nthree\n```\nfour';
        const expectedNewTextAreaValue = 'one\n\ntwo\nthree\nfour';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['codeBlock'].getFormatting({
            value: textAreaValue,
            selectionStart: 9,
            selectionEnd: 18,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two\nthree');
      });

      it('unformats if no selection is given, but cursor is wrapped in a code block', () => {
        const textAreaValue = 'one\n\n```\n\n```\ntwo';
        const expectedNewTextAreaValue = 'one\n\n\ntwo';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['codeBlock'].getFormatting({
            value: textAreaValue,
            selectionStart: 9,
            selectionEnd: 9,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('');
      });

      it('unformats if selection starts and ends with code block formatting', () => {
        const textAreaValue = 'one\n\n```\ntwo\n```\nthree';
        const expectedNewTextAreaValue = 'one\n\ntwo\nthree';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          coreSyntaxFormatters['codeBlock'].getFormatting({
            value: textAreaValue,
            selectionStart: 5,
            selectionEnd: 16,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });
    });

    describe('divider', () => {
      it('inserts a divider if no selection is given', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one \n\n---\n\ntwo three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['divider'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 4,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('');
      });

      it('inserts any selected text after the divider', () => {
        const textAreaValue = 'one two three';
        const expectedNewTextAreaValue = 'one \n\n---\ntwo\n three';

        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['divider'].getFormatting({
            value: textAreaValue,
            selectionStart: 4,
            selectionEnd: 7,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });

      it('removes the divider if no selected text, and cursor directly preceded by line formatting', () => {
        const textAreaValue = 'one\n\n---\ntwo';
        const expectedNewTextAreaValue = 'one\n\ntwo';
        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['divider'].getFormatting({
            value: textAreaValue,
            selectionStart: 9,
            selectionEnd: 9,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('');
      });

      it('removes the divider if selected text is directly preceded by line formatting', () => {
        const textAreaValue = 'one\n\n---\ntwo three';
        const expectedNewTextAreaValue = 'one\n\ntwo three';
        const { newTextAreaValue, newCursorStart, newCursorEnd } =
          secondarySyntaxFormatters['divider'].getFormatting({
            value: textAreaValue,
            selectionStart: 9,
            selectionEnd: 12,
          });

        expect(newTextAreaValue).toEqual(expectedNewTextAreaValue);
        expect(
          newTextAreaValue.substring(newCursorStart, newCursorEnd),
        ).toEqual('two');
      });
    });
  });
});
