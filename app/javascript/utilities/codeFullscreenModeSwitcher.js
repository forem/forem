let screenScroll = 0;

function getFullScreenWindow() {
  return document.getElementsByClassName('js-fullscreen-code')[0];
}

export function getFullScreenModeStatus() {
  // derive from the DOM so state can never desync from a stale module flag
  return Boolean(getFullScreenWindow()?.classList.contains('is-open'));
}

function setAfterFullScreenScrollPosition() {
  globalThis.scrollTo(0, screenScroll);
}

function getBeforeFullScreenScrollPosition() {
  screenScroll = globalThis.scrollY;
}

export function onPressEscape(event) {
  if (event.key == 'Escape') {
    fullScreenModeControl(event);
  }
}

function listenToKeyboardForEscape(listen) {
  if (listen) {
    document.body.addEventListener('keyup', onPressEscape);
  } else {
    document.body.removeEventListener('keyup', onPressEscape);
  }
}

export function onPopstate() {
  fullScreenModeControl();
}

function listenToWindowForPopstate(listen) {
  if (listen) {
    globalThis.addEventListener('popstate', onPopstate);
  } else {
    globalThis.removeEventListener('popstate', onPopstate);
  }
}

function toggleOverflowForDocument(overflow) {
  // read document.body live; a cached reference goes stale after a soft navigation
  document.body.style.overflow = overflow ? 'hidden' : '';
}

export function addFullScreenModeControl(elements) {
  if (elements) {
    for (const element of elements) {
      element.addEventListener('click', fullScreenModeControl);
    }
  }
}

function removeFullScreenModeControl(elements) {
  if (elements) {
    for (const element of elements) {
      element.removeEventListener('click', fullScreenModeControl);
    }
  }
}

function fullScreenModeControl(event) {
  const fullScreenWindow = getFullScreenWindow();
  const codeBlock = event?.currentTarget.closest('.js-code-highlight')
    ? event.currentTarget.closest('.js-code-highlight').cloneNode(true)
    : null;
  const codeBlockControls = codeBlock
    ? codeBlock.getElementsByClassName('js-fullscreen-code-action')
    : null;

  if (getFullScreenModeStatus()) {
    toggleOverflowForDocument(false);
    setAfterFullScreenScrollPosition();
    listenToKeyboardForEscape(false);
    listenToWindowForPopstate(false);
    removeFullScreenModeControl(codeBlockControls);

    fullScreenWindow.classList.remove('is-open');
    // clears an already-emptied container and any stale leftovers alike
    fullScreenWindow.replaceChildren();
  } else {
    if (!codeBlock || !fullScreenWindow) {
      // popstate/escape fire with no event; an interrupted session must still
      // release the scroll lock and its listeners (all idempotent)
      toggleOverflowForDocument(false);
      listenToKeyboardForEscape(false);
      listenToWindowForPopstate(false);
      return;
    }

    toggleOverflowForDocument(true);
    getBeforeFullScreenScrollPosition();
    listenToKeyboardForEscape(true);
    listenToWindowForPopstate(true);

    codeBlock.classList.add('is-fullscreen');
    fullScreenWindow.appendChild(codeBlock);
    fullScreenWindow.classList.add('is-open');

    addFullScreenModeControl(codeBlockControls);
  }
}
