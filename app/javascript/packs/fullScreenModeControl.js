import { addFullScreenModeControl } from '../utilities/codeFullscreenModeSwitcher';

document.addEventListener('DOMContentLoaded', () => {
  const fullscreenActionElements = document.querySelectorAll(
    '.js-fullscreen-code-action',
  );

  if (fullscreenActionElements) {
    addFullScreenModeControl(fullscreenActionElements);
  }
});
