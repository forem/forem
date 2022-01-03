let isFullScreenModeCodeOn = false;
let screenScroll = 0;
const fullScreenWindow =
  document.getElementsByClassName('js-fullscreen-code')[0];
const { body } = document;

function setAfterFullScreenScrollPosition() {
  window.scrollTo(0, screenScroll);
}

function getBeforeFullScreenScrollPosition() {
  screenScroll = window.scrollY;
}

function onPressEscape(event) {
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
  const codeBlock = event.currentTarget.closest('.js-code-highlight')
    ? event.currentTarget.closest('.js-code-highlight').cloneNode(true)
    : null;
  const codeBlockControls = codeBlock
    ? codeBlock.getElementsByClassName('js-fullscreen-code-action')
    : null;

  if (isFullScreenModeCodeOn) {
    toggleOverflowForDocument(false);
    setAfterFullScreenScrollPosition();
    listenToKeyboardForEscape(false);
    removeFullScreenModeControl(codeBlockControls);

    fullScreenWindow.classList.remove('is-open');
    fullScreenWindow.removeChild(fullScreenWindow.childNodes[0]);

    isFullScreenModeCodeOn = false;
  } else {
    toggleOverflowForDocument(true);
    getBeforeFullScreenScrollPosition();
    listenToKeyboardForEscape(true);
    codeBlock.classList.add('is-fullscreen');
    fullScreenWindow.appendChild(codeBlock);
    fullScreenWindow.classList.add('is-open');

    addFullScreenModeControl(codeBlockControls);

    isFullScreenModeCodeOn = true;
  }
}
