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

function openLightbox(src, alt) {
  const { overlay, closeBtn, img } = getOrBuildOverlay();

  img.src = src;
  img.alt = alt || '';

  overlay.classList.add('image-lightbox--visible');
  document.documentElement.classList.add('image-lightbox-open');

  // rAF ensures the element is painted before focus, which is required for
  // keyboard users to be able to dismiss the overlay immediately with Escape.
  requestAnimationFrame(() => closeBtn.focus());

  function handleKeydown(e) {
    if (e.key === 'Escape') closeLightbox();
  }

  function handleOverlayClick(e) {
    if (e.target === overlay || e.target === closeBtn) closeLightbox();
  }

  overlay.addEventListener('click', handleOverlayClick);
  document.addEventListener('keydown', handleKeydown);

  overlay._cleanup = () => {
    overlay.removeEventListener('click', handleOverlayClick);
    document.removeEventListener('keydown', handleKeydown);
    delete overlay._cleanup;
  };
}

function closeLightbox() {
  const overlay = document.getElementById(OVERLAY_ID);
  if (!overlay) return;

  overlay.classList.remove('image-lightbox--visible');
  document.documentElement.classList.remove('image-lightbox-open');

  if (typeof overlay._cleanup === 'function') overlay._cleanup();

  // Clear src after the CSS transition completes so the previous image
  // does not flash when the next one is loading.
  setTimeout(() => {
    const img = overlay.querySelector('.image-lightbox__img');
    if (img) img.src = '';
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
}