import {
  getAutocompleteWordData,
  getLastIndexOfCharacter,
  getNextIndexOfCharacter,
  getSelectionData,
  getNumberOfNewLinesPrecedingSelection,
  getNumberOfNewLinesFollowingSelection,
} from '../textAreaUtils';

describe('getAutocompleteWordData', () => {
  it('returns isTriggered false for cursor at start of input', () => {
    const textArea = {
      selectionStart: 0,
      value: 'text with @mention',
    };

    const { isTriggered, indexOfAutocompleteStart } = getAutocompleteWordData({
      textArea,
      triggerCharacter: '@',
    });
    expect(isTriggered).toBe(false);
    expect(indexOfAutocompleteStart).toEqual(-1);
  });

  it('returns isTriggered false for empty input value', () => {
    const textArea = {
      selectionStart: 10,
      value: '',
    };

    const { isTriggered, indexOfAutocompleteStart } = getAutocompleteWordData({
      textArea,
      triggerCharacter: '@',
    });
    expect(isTriggered).toBe(false);
    expect(indexOfAutocompleteStart).toEqual(-1);
  });

  it('returns isTriggered false if no triggerCharacter exists at start of word', () => {
    const textArea = {
      selectionStart: 13,
      value: 'text with no mention',
    };

    const { isTriggered, indexOfAutocompleteStart } = getAutocompleteWordData({
      textArea,
      triggerCharacter: '@',
    });
    expect(isTriggered).toBe(false);
    expect(indexOfAutocompleteStart).toEqual(-1);
  });

  it('returns isTriggered true and correct index for an @ mention at beginning of input', () => {
    const textArea = {
      selectionStart: 3,
      value: '@mention',
    };

    const { isTriggered, indexOfAutocompleteStart } = getAutocompleteWordData({
      textArea,
      triggerCharacter: '@',
    });
    expect(isTriggered).toBe(true);
    expect(indexOfAutocompleteStart).toEqual(0);
  });

  it('returns isTriggered true and correct index for @ mention in middle of input', () => {
    const textArea = {
      selectionStart: 13,
      value: 'text with @mention',
    };

    const { isTriggered, indexOfAutocompleteStart } = getAutocompleteWordData({
      textArea,
      triggerCharacter: '@',
    });
    expect(isTriggered).toBe(true);
    expect(indexOfAutocompleteStart).toEqual(10);
  });
});

describe('getLastIndexOfCharacter', () => {
  it('returns -1 when content is empty', () => {
    expect(
      getLastIndexOfCharacter({
        content: '',
        selectionIndex: 0,
        character: 'f',
      }),
    ).toEqual(-1);
  });

  it("returns -1 for a character that isn't present", () => {
    expect(
      getLastIndexOfCharacter({
        content: 'abcde',
        selectionIndex: 4,
        character: 'f',
      }),
    ).toEqual(-1);
  });

  it('returns index of the last occurrence within a single word', () => {
    expect(
      getLastIndexOfCharacter({
        content: 'abcde',
        selectionIndex: 4,
        character: 'b',
      }),
    ).toEqual(1);
  });

  it('returns index of the last occurrence searching through multiple words', () => {
    expect(
      getLastIndexOfCharacter({
        content: 'ab cd ef ghi',
        selectionIndex: 10,
        character: 'b',
      }),
    ).toEqual(1);
  });

  it('halts the search when encountering a break character', () => {
    expect(
      getLastIndexOfCharacter({
        content: 'ab cd ef ghi',
        selectionIndex: 10,
        character: 'b',
        breakOnCharacters: [' '],
      }),
    ).toEqual(-1);
  });
});

describe('getNextIndexOfCharacter', () => {
  it('returns -1 when content is empty', () => {
    expect(
      getNextIndexOfCharacter({
        content: '',
        selectionIndex: 0,
        character: 'f',
      }),
    ).toEqual(-1);
  });

  it("returns -1 for a character that isn't present", () => {
    expect(
      getNextIndexOfCharacter({
        content: 'abcde',
        selectionIndex: 1,
        character: 'f',
      }),
    ).toEqual(-1);
  });

  it('returns index of the last occurrence within a single word', () => {
    expect(
      getNextIndexOfCharacter({
        content: 'abcde',
        selectionIndex: 0,
        character: 'e',
      }),
    ).toEqual(4);
  });

  it('returns index of the last occurrence searching through multiple words', () => {
    expect(
      getNextIndexOfCharacter({
        content: 'ab cd ef ghi',
        selectionIndex: 0,
        character: 'f',
      }),
    ).toEqual(7);
  });

  it('halts the search when encountering a break character', () => {
    expect(
      getNextIndexOfCharacter({
        content: 'ab cd ef ghi',
        selectionIndex: 0,
        character: 'f',
        breakOnCharacters: [' '],
      }),
    ).toEqual(-1);
  });
});

describe('getSelectionData', () => {
  it('returns selection data for given inputs', () => {
    expect(
      getSelectionData({
        selectionStart: 4,
        selectionEnd: 7,
        value: 'one two three four',
      }),
    ).toEqual({
      textBeforeSelection: 'one ',
      textAfterSelection: ' three four',
      selectedText: 'two',
    });
  });
});

describe('getNumberOfNewLinesPrecedingSelection', () => {
  it('returns 0 when selection start is 0', () => {
    expect(
      getNumberOfNewLinesPrecedingSelection({
        selectionStart: 0,
        value: 'some text',
      }),
    ).toEqual(0);
  });

  it('returns 0 if no new lines exist before selection', () => {
    expect(
      getNumberOfNewLinesPrecedingSelection({
        selectionStart: 9,
        value: 'some text',
      }),
    ).toEqual(0);
  });

  it('returns count of new lines before selection', () => {
    expect(
      getNumberOfNewLinesPrecedingSelection({
        selectionStart: 6,
        value: 'some\n\ntext',
      }),
    ).toEqual(2);
  });

  it('only returns count of new lines immediately before selection', () => {
    expect(
      getNumberOfNewLinesPrecedingSelection({
        selectionStart: 7,
        value: 'some\n\ntext',
      }),
    ).toEqual(0);
  });

  it('stops counting new lines as soon as any other character occurs', () => {
    expect(
      getNumberOfNewLinesPrecedingSelection({
        selectionStart: 9,
        value: '\n\n\nsome\n\ntext',
      }),
    ).toEqual(2);
  });
});

describe('getNumberOfNewLinesFollowingSelection', () => {
  it('returns 0 when selection end is end of text area value', () => {
    expect(
      getNumberOfNewLinesFollowingSelection({
        selectionEnd: 9,
        value: 'some text',
      }),
    ).toEqual(0);
  });

  it('returns 0 if no new lines exist after selection', () => {
    expect(
      getNumberOfNewLinesFollowingSelection({
        selectionEnd: 1,
        value: 'some text',
      }),
    ).toEqual(0);
  });

  it('returns count of new lines after selection', () => {
    expect(
      getNumberOfNewLinesFollowingSelection({
        selectionEnd: 4,
        value: 'some\n\ntext',
      }),
    ).toEqual(2);
  });

  it('only returns count of new lines immediately after selection', () => {
    expect(
      getNumberOfNewLinesFollowingSelection({
        selectionEnd: 1,
        value: 'some\n\ntext',
      }),
    ).toEqual(0);
  });

  it('stops counting new lines as soon as any other character occurs', () => {
    expect(
      getNumberOfNewLinesFollowingSelection({
        selectionEnd: 0,
        value: '\n\n\nsome\n\ntext',
      }),
    ).toEqual(3);
  });
});
