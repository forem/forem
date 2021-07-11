import { isModerationPage } from '@utilities/moderation';

describe('Moderation Utilities', () => {
  it('should return true if on the moderation page', () => {
    expect(isModerationPage('/mod')).toBe(true);
    expect(isModerationPage('/mod/')).toBe(true);
  });

  it('should return false if the path contains part of the moderation page path', () => {
    expect(isModerationPage('/some-user/moderate-post')).toBe(false);
    expect(isModerationPage('/some-user/moderate-post/')).toBe(false);
  });

  it('should return false if the path is not the moderation page', () => {
    expect(isModerationPage('/some-user/some-post')).toBe(false);
  });
});
