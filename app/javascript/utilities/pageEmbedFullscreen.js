let screenScroll = 0;

const FOCUSABLE_SELECTOR = [
  'iframe',
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled])',
  'select:not([disabled])',
  'textarea:not([disabled])',
  '[tabindex]:not([tabindex="-1"])',
].join(', ');

function getOpenEmbed() {
  return document.querySelector('.js-page-embed.is-fullscreen');
}

export function isPageEmbedFullscreenOpen() {
  return Boolean(getOpenEmbed());
}

function applyBodyOverflowLock(locked) {
  if (!document.body) return;
  document.body.style.overflow = locked ? 'hidden' : '';
}

function getFocusableElements(container) {
  if (!container) return [];

  return Array.from(container.querySelectorAll(FOCUSABLE_SELECTOR)).filter(
    (element) =>
      !element.hasAttribute('disabled') &&
      element.getAttribute('aria-hidden') !== 'true' &&
      element.tabIndex !== -1 &&
      !element.closest('[hidden], .hidden, [aria-hidden="true"]'),
  );
}

function trapFocusKeyDown(event) {
  const openEmbed = getOpenEmbed();
  if (!openEmbed) return;

  const card = openEmbed.querySelector('.ltag__page-card') || openEmbed;
  const focusables = getFocusableElements(card);
  if (focusables.length === 0) {
    event.preventDefault();
    return;
  }

  const first = focusables[0];
  const last = focusables[focusables.length - 1];
  const active = document.activeElement;

  if (!card.contains(active)) {
    event.preventDefault();
    (event.shiftKey ? last : first).focus({ preventScroll: true });
    return;
  }

  if (event.shiftKey && active === first) {
    event.preventDefault();
    last.focus({ preventScroll: true });
  } else if (!event.shiftKey && active === last) {
    event.preventDefault();
    first.focus({ preventScroll: true });
  }
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
  } else if (event.key === 'Tab') {
    trapFocusKeyDown(event);
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
  applyBodyOverflowLock(true);
  toggleGlobalListeners(true);

  if (
    button &&
    typeof button.focus === 'function' &&
    !embed.contains(document.activeElement)
  ) {
    button.focus({ preventScroll: true });
  }
}

export function exitPageEmbedFullscreen({
  restoreScroll = true,
  restoreFocus = true,
} = {}) {
  const openEmbed = getOpenEmbed();
  toggleGlobalListeners(false);
  applyBodyOverflowLock(false);

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
  if (event.pageEmbedFullscreenHandled) return;

  const trigger = event.target?.closest?.('.js-fullscreen-page-action');
  if (!trigger) return;

  const embed = trigger.closest('.js-page-embed');
  if (!embed) return;

  event.pageEmbedFullscreenHandled = true;
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
