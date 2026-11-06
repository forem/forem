import { createPopup } from '@picmo/popup-picker';

if (typeof window !== 'undefined') {
  window.Forem = window.Forem || {};
  window.Forem.createEmojiPopup = createPopup;
}

export { createPopup };
