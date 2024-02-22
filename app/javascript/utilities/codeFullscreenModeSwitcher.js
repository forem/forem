let isFullScreenModeCodeOn = false;
let screenScroll = 0;
const { body } = document;

export function getFullScreenModeStatus() {
  return isFullScreenModeCodeOn;
}

function setAfterFullScreenScrollPosition() {
  window.scrollTo(0, screenScroll);
}

function getBeforeFullScreenScrollPosition() {
  screenScroll = window.scrollY;
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
    window.addEventListener('popstate', onPopstate);
  } else {
    window.removeEventListener('popstate', onPopstate);
  }
}

function toggleOverflowForDocument(overflow) {
  if (overflow) {
    body.style.overflow = 'hidden';
  } else {
    body.style.overflow = '';
  }
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
  const fullScreenWindow =
    document.getElementsByClassName('js-fullscreen-code')[0];
  const codeBlock = event?.currentTarget.closest('.js-code-highlight')
    ? event.currentTarget.closest('.js-code-highlight').cloneNode(true)
    : null;
  const codeBlockControls = codeBlock
    ? codeBlock.getElementsByClassName('js-fullscreen-code-action')
    : null;

  if (isFullScreenModeCodeOn) {
    toggleOverflowForDocument(false);
    setAfterFullScreenScrollPosition();
    listenToKeyboardForEscape(false);
    listenToWindowForPopstate(false);
    removeFullScreenModeControl(codeBlockControls);

    fullScreenWindow.classList.remove('is-open');
    fullScreenWindow.removeChild(fullScreenWindow.childNodes[0]);

    isFullScreenModeCodeOn = false;
  } else {
    toggleOverflowForDocument(true);
    getBeforeFullScreenScrollPosition();
    listenToKeyboardForEscape(true);
    listenToWindowForPopstate(true);

    codeBlock.classList.add('is-fullscreen');
    fullScreenWindow.appendChild(codeBlock);
    fullScreenWindow.classList.add('is-open');

    addFullScreenModeControl(codeBlockControls);

    isFullScreenModeCodeOn = true;
  }
}
