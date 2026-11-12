let screenScroll = 0;

function getOpenEmbed() {
  return document.querySelector('.js-page-embed.is-fullscreen');
}

export function isPageEmbedFullscreenOpen() {
  return Boolean(getOpenEmbed());
}

function setBodyOverflowLocked(locked) {
  if (!document.body) return;
  document.body.style.overflow = locked ? 'hidden' : '';
}

function updateButtonState(button, expanded) {
  if (!button) return;

  const nextLabel = expanded
    ? button.dataset.exitLabel || 'Exit fullscreen mode'
    : button.dataset.enterLabel || 'Enter fullscreen mode';

  button.setAttribute('aria-expanded', expanded ? 'true' : 'false');
  button.setAttribute('aria-label', nextLabel);
  button.setAttribute('title', nextLabel);
}

function onKeyDown(event) {
  if (event.key === 'Escape') {
    exitPageEmbedFullscreen({ restoreScroll: true, restoreFocus: true });
  }
}

function onPopstate() {
  exitPageEmbedFullscreen({ restoreScroll: false, restoreFocus: false });
}

function toggleGlobalListeners(active) {
  if (active) {
    document.addEventListener('keydown', onKeyDown);
    globalThis.addEventListener('popstate', onPopstate);
  } else {
    document.removeEventListener('keydown', onKeyDown);
    globalThis.removeEventListener('popstate', onPopstate);
  }
}

export function enterPageEmbedFullscreen(embed) {
  if (!embed) return;

  const existing = getOpenEmbed();
  if (existing && existing !== embed) {
    exitPageEmbedFullscreen({ restoreScroll: false, restoreFocus: false });
  }

  screenScroll = globalThis.scrollY || 0;
  const currentHeight = Math.round(embed.getBoundingClientRect().height);
  if (currentHeight > 0) {
    embed.style.minHeight = `${currentHeight}px`;
  }

  const button = embed.querySelector('.js-fullscreen-page-action');
  embed.classList.add('is-fullscreen');
  updateButtonState(button, true);
  setBodyOverflowLocked(true);
  toggleGlobalListeners(true);
}

export function exitPageEmbedFullscreen({
  restoreScroll = true,
  restoreFocus = true,
} = {}) {
  const openEmbed = getOpenEmbed();
  toggleGlobalListeners(false);
  setBodyOverflowLocked(false);

  if (!openEmbed) return;

  const button = openEmbed.querySelector('.js-fullscreen-page-action');
  openEmbed.classList.remove('is-fullscreen');
  openEmbed.style.minHeight = '';
  updateButtonState(button, false);

  if (restoreScroll && typeof globalThis.scrollTo === 'function') {
    globalThis.scrollTo(0, screenScroll);
  }

  if (restoreFocus && button && typeof button.focus === 'function') {
    button.focus({ preventScroll: true });
  }
}

function handleActionClick(event) {
  const trigger = event.target?.closest?.('.js-fullscreen-page-action');
  if (!trigger) return;

  const embed = trigger.closest('.js-page-embed');
  if (!embed) return;

  event.preventDefault();

  if (embed.classList.contains('is-fullscreen')) {
    exitPageEmbedFullscreen({ restoreScroll: true, restoreFocus: true });
  } else {
    enterPageEmbedFullscreen(embed);
  }
}

export function initializePageEmbedFullscreen(root = document) {
  const target =
    root === document ? document.documentElement || document.body : root;
  if (!target || target.dataset?.pageEmbedFullscreenBound === 'true') {
    return;
  }

  if (target.dataset) {
    target.dataset.pageEmbedFullscreenBound = 'true';
  }
  target.addEventListener('click', handleActionClick);

  if (
    typeof globalThis.InstantClick !== 'undefined' &&
    typeof globalThis.InstantClick.on === 'function' &&
    !globalThis.__foremPageEmbedInstantClickBound
  ) {
    globalThis.__foremPageEmbedInstantClickBound = true;
    globalThis.InstantClick.on('change', () => {
      exitPageEmbedFullscreen({ restoreScroll: false, restoreFocus: false });
    });
  }
}
