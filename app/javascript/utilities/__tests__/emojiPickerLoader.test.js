import {
  loadEmojiPopupPicker,
  resetEmojiPickerLoaderForTests,
} from '@utilities/emojiPickerLoader';

describe('loadEmojiPopupPicker', () => {
  beforeEach(() => {
    resetEmojiPickerLoaderForTests();
    document.head.innerHTML =
      '<meta name="emoji-picker-script" content="/assets/emojiPicker-test.js">';
    document.body.innerHTML = '';
    window.Forem = {};
  });

  it('resolves immediately when window.Forem.createEmojiPopup is already registered', async () => {
    const fakeCreatePopup = jest.fn();
    window.Forem.createEmojiPopup = fakeCreatePopup;

    const result = await loadEmojiPopupPicker();
    expect(result).toBe(fakeCreatePopup);
    expect(
      document.querySelector('script[data-emoji-picker-bundle="true"]'),
    ).toBeNull();
  });

  it('loads the emojiPicker script on demand and resolves createEmojiPopup', async () => {
    const promise = loadEmojiPopupPicker();
    const script = document.querySelector(
      'script[data-emoji-picker-bundle="true"]',
    );
    expect(script).not.toBeNull();
    expect(script.getAttribute('src')).toEqual('/assets/emojiPicker-test.js');

    const fakeCreatePopup = jest.fn();
    window.Forem.createEmojiPopup = fakeCreatePopup;
    script.dispatchEvent(new Event('load'));

    await expect(promise).resolves.toBe(fakeCreatePopup);
  });

  it('removes the script on error so subsequent clicks can retry', async () => {
    const failedPromise = loadEmojiPopupPicker();
    const firstScript = document.querySelector(
      'script[data-emoji-picker-bundle="true"]',
    );
    firstScript.dispatchEvent(new Event('error'));

    await expect(failedPromise).rejects.toThrow(
      'Failed to load /assets/emojiPicker-test.js',
    );
    expect(
      document.querySelector('script[data-emoji-picker-bundle="true"]'),
    ).toBeNull();
  });
});
