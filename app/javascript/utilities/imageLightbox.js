const OVERLAY_ID = 'image-lightbox-overlay';

function createOverlay() {
  const overlay = document.createElement('div');
  overlay.id = OVERLAY_ID;
  overlay.setAttribute('role', 'dialog');
  overlay.setAttribute('aria-modal', 'true');
  overlay.setAttribute('aria-label', 'Image preview');

  const closeBtn = document.createElement('button');
  closeBtn.className = 'image-lightbox__close';
  closeBtn.setAttribute('aria-label', 'Close image preview');
  closeBtn.setAttribute('type', 'button');
  closeBtn.innerHTML = '&times;';

  const imgWrapper = document.createElement('div');
  imgWrapper.className = 'image-lightbox__img-wrapper';
  imgWrapper.setAttribute('role', 'presentation');

  const img = document.createElement('img');
  img.className = 'image-lightbox__img';
  img.setAttribute('alt', '');

  imgWrapper.appendChild(img);
  overlay.appendChild(closeBtn);
  overlay.appendChild(imgWrapper);

  return { overlay, closeBtn, img };
}

function getOrBuildOverlay() {
  const existing = document.getElementById(OVERLAY_ID);
  if (existing) {
    return {
      overlay: existing,
      closeBtn: existing.querySelector('.image-lightbox__close'),
      img: existing.querySelector('.image-lightbox__img'),
    };
  }

  const elements = createOverlay();
  document.body.appendChild(elements.overlay);
  return elements;
}

function handleKeydown(e) {
  if (e.key === 'Escape') closeLightbox();
}

function handleOverlayClick(e) {
  const overlay = document.getElementById(OVERLAY_ID);
  const closeBtn = document.querySelector('.image-lightbox__close');
  if (e.target === overlay || e.target === closeBtn) closeLightbox();
}

function openLightbox(src, alt) {
  const { overlay, closeBtn, img } = getOrBuildOverlay();

  // If a timeout was queued from a previous close operation, clear it
  // so the new image doesn't instantly vanish mid-view.
  if (overlay._timeout) {
    clearTimeout(overlay._timeout);
    overlay._timeout = null;
  }

  // Clear any existing listeners first to prevent orphaned closures
  // from piling up if openLightbox is called sequentially.
  if (typeof overlay._cleanup === 'function') overlay._cleanup();

  // Cache the element that triggered the modal for a11y focus restoration
  overlay._triggerElement = document.activeElement;

  img.src = src;
  img.alt = alt || '';

  overlay.classList.add('image-lightbox--visible');
  document.documentElement.classList.add('image-lightbox-open');

  // rAF ensures the element is painted before focus, which is required for
  // keyboard users to be able to dismiss the overlay immediately with Escape.
  requestAnimationFrame(() => closeBtn.focus());

  overlay.addEventListener('click', handleOverlayClick);
  document.addEventListener('keydown', handleKeydown);

  overlay._cleanup = () => {
    overlay.removeEventListener('click', handleOverlayClick);
    document.removeEventListener('keydown', handleKeydown);
  };
}

export function closeLightbox() {
  const overlay = document.getElementById(OVERLAY_ID);
  if (!overlay) return;

  overlay.classList.remove('image-lightbox--visible');
  document.documentElement.classList.remove('image-lightbox-open');

  if (typeof overlay._cleanup === 'function') {
    overlay._cleanup();
    delete overlay._cleanup;
  }

  // Restore focus to the triggering element (A11y)
  if (overlay._triggerElement && typeof overlay._triggerElement.focus === 'function') {
    overlay._triggerElement.focus();
    delete overlay._triggerElement;
  }

  // Clear src after the CSS transition completes so the previous image
  // does not flash when the next one is loading.
  overlay._timeout = setTimeout(() => {
    const img = overlay.querySelector('.image-lightbox__img');
    if (img) img.src = '';
    overlay._timeout = null;
  }, 350);
}

/**
 * Attaches a delegated click listener that intercepts clicks on any
 * `.article-body-image-wrapper` anchor and opens that specific image in a
 * lightbox overlay instead of navigating to the CDN URL.
 *
 * Safe to call multiple times; subsequent calls are no-ops.
 *
 * @param {Document|HTMLElement} [rootEl=document]
 */
export function initializeImageLightbox(rootEl = document) {
  const listenerTarget = rootEl === document ? document.body : rootEl;

  if (listenerTarget.dataset.imageLightboxInit === 'true') return;
  listenerTarget.dataset.imageLightboxInit = 'true';

  listenerTarget.addEventListener('click', (e) => {
    const anchor = e.target.closest('a.article-body-image-wrapper');
    if (!anchor) return;

    e.preventDefault();
    e.stopPropagation();

    const img = anchor.querySelector('img');
    const src = anchor.getAttribute('href') || (img && img.src) || '';
    const alt = (img && img.getAttribute('alt')) || '';

    if (src) openLightbox(src, alt);
  });

  // Ensure lightbox closes when InstantClick navigates to a new page,
  // preventing users from being trapped with `overflow: hidden` on the next view.
  if (window.InstantClick && !closeLightbox.isBound) {
    closeLightbox.isBound = true;
    window.InstantClick.on('change', closeLightbox);
  }
}