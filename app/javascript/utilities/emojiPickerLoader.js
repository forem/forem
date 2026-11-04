let pendingEmojiPickerPromise = null;

/**
 * Dynamically loads the emojiPicker pack when a user clicks the "Insert Emoji" button.
 *
 * @returns {Promise<Function|null>} Resolves with `createPopup` from `@picmo/popup-picker`.
 */
export function loadEmojiPopupPicker() {
  if (typeof window !== 'undefined' && window.Forem?.createEmojiPopup) {
    return Promise.resolve(window.Forem.createEmojiPopup);
  }

  if (pendingEmojiPickerPromise) {
    return pendingEmojiPickerPromise;
  }

  const metaTag = document.querySelector('meta[name="emoji-picker-script"]');
  const scriptSrc = metaTag?.content || '/assets/emojiPicker.js';

  pendingEmojiPickerPromise = new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.src = scriptSrc;
    script.defer = true;
    script.dataset.emojiPickerBundle = 'true';

    script.addEventListener(
      'load',
      () => {
        if (window.Forem?.createEmojiPopup) {
          resolve(window.Forem.createEmojiPopup);
        } else {
          pendingEmojiPickerPromise = null;
          script.remove();
          reject(
            new Error(
              'emojiPicker bundle loaded without registering createEmojiPopup',
            ),
          );
        }
      },
      { once: true },
    );

    script.addEventListener(
      'error',
      () => {
        pendingEmojiPickerPromise = null;
        script.remove();
        reject(new Error(`Failed to load ${scriptSrc}`));
      },
      { once: true },
    );

    document.head.appendChild(script);
  });

  return pendingEmojiPickerPromise;
}

export function resetEmojiPickerLoaderForTests() {
  pendingEmojiPickerPromise = null;
}
