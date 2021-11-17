import {
  getMentionWordData,
  getLastIndexOfCharacter,
  getNextIndexOfCharacter,
  getSelectionData,
} from '../textAreaUtils';

describe('getMentionWordData', () => {
  it('returns userMention false for cursor at start of input', () => {
    const inputState = {
      selectionStart: 0,
      value: 'text with @mention',
    };

    const { isUserMention, indexOfMentionStart } =
      getMentionWordData(inputState);
    expect(isUserMention).toBe(false);
    expect(indexOfMentionStart).toEqual(-1);
  });

  it('returns userMention false for empty input value', () => {
    const inputState = {
      selectionStart: 10,
      value: '',
    };

    const { isUserMention, indexOfMentionStart } =
      getMentionWordData(inputState);
    expect(isUserMention).toBe(false);
    expect(indexOfMentionStart).toEqual(-1);
  });

  it('returns userMention false if no @ symbol exists at start of word', () => {
    const inputState = {
      selectionStart: 13,
      value: 'text with no mention',
    };

    const { isUserMention, indexOfMentionStart } =
      getMentionWordData(inputState);
    expect(isUserMention).toBe(false);
    expect(indexOfMentionStart).toEqual(-1);
  });

  it('returns userMention true and correct index for an @ mention at beginning of input', () => {
    const inputState = {
      selectionStart: 3,
      value: '@mention',
    };

    const { isUserMention, indexOfMentionStart } =
      getMentionWordData(inputState);
    expect(isUserMention).toBe(true);
    expect(indexOfMentionStart).toEqual(0);
  });

  it('returns userMention true and correct index for @ mention in middle of input', () => {
    const inputState = {
      selectionStart: 13,
      value: 'text with @mention',
    };

    const { isUserMention, indexOfMentionStart } =
      getMentionWordData(inputState);
    expect(isUserMention).toBe(true);
    expect(indexOfMentionStart).toEqual(10);
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

  it('returns index of the last occurence within a single word', () => {
    expect(
      getLastIndexOfCharacter({
        content: 'abcde',
        selectionIndex: 4,
        character: 'b',
      }),
    ).toEqual(1);
  });

  it('returns index of the last occurence searching through multiple words', () => {
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

  it('returns index of the last occurence within a single word', () => {
    expect(
      getNextIndexOfCharacter({
        content: 'abcde',
        selectionIndex: 0,
        character: 'e',
      }),
    ).toEqual(4);
  });

  it('returns index of the last occurence searching through multiple words', () => {
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
