import { getMentionWordData } from '../textAreaUtils';

describe('getMentionWordData', () => {
  it('returns userMention false for cursor at start of input', () => {
    const inputState = {
      selectionStart: 0,
      value: 'text with @mention',
    };

    const { isUserMention, indexOfMentionStart } = getMentionWordData(
      inputState,
    );
    expect(isUserMention).toBe(false);
    expect(indexOfMentionStart).toEqual(-1);
  });

  it('returns userMention false for empty input value', () => {
    const inputState = {
      selectionStart: 10,
      value: '',
    };

    const { isUserMention, indexOfMentionStart } = getMentionWordData(
      inputState,
    );
    expect(isUserMention).toBe(false);
    expect(indexOfMentionStart).toEqual(-1);
  });

  it('returns userMention false if no @ symbol exists at start of word', () => {
    const inputState = {
      selectionStart: 13,
      value: 'text with no mention',
    };

    const { isUserMention, indexOfMentionStart } = getMentionWordData(
      inputState,
    );
    expect(isUserMention).toBe(false);
    expect(indexOfMentionStart).toEqual(-1);
  });

  it('returns userMention true and correct index for an @ mention at beginning of input', () => {
    const inputState = {
      selectionStart: 3,
      value: '@mention',
    };

    const { isUserMention, indexOfMentionStart } = getMentionWordData(
      inputState,
    );
    expect(isUserMention).toBe(true);
    expect(indexOfMentionStart).toEqual(0);
  });

  it('returns userMention true and correct index for @ mention in middle of input', () => {
    const inputState = {
      selectionStart: 13,
      value: 'text with @mention',
    };

    const { isUserMention, indexOfMentionStart } = getMentionWordData(
      inputState,
    );
    expect(isUserMention).toBe(true);
    expect(indexOfMentionStart).toEqual(10);
  });
});
