import { createAssetBundleLoader } from './loadAssetBundle';

const emojiPickerBundleLoader = createAssetBundleLoader({
  metaName: 'emoji-picker-script',
  fallbackSrc: '/assets/emojiPicker.js',
  dataAttribute: 'emojiPickerBundle',
  getReadyValue: () => window.Forem?.createEmojiPopup || null,
  errorMessage:
    'emojiPicker bundle loaded without registering createEmojiPopup',
});

/**
 * Dynamically loads the emojiPicker pack when a user clicks the "Insert Emoji" button.
 *
 * @returns {Promise<Function|null>} Resolves with `createPopup` from `@picmo/popup-picker`.
 */
export function loadEmojiPopupPicker() {
  return emojiPickerBundleLoader.load();
}

export function resetEmojiPickerLoaderForTests() {
  emojiPickerBundleLoader.reset();
}
