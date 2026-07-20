const CAROUSEL_SELECTOR = '.ltag-slides--carousel';

function initializeCarousel(container) {
  if (container.dataset.slidesInitialized === 'true') return;

  const track = container.querySelector('.ltag-slides__track');
  const slides = Array.from(container.querySelectorAll('.ltag-slide'));
  const previousButton = container.querySelector('.ltag-slides__nav--prev');
  const nextButton = container.querySelector('.ltag-slides__nav--next');
  const progressThumb = container.querySelector(
    '.ltag-slides__progress-thumb',
  );
  let requestedScrollPosition = null;
  let requestedScrollReset;

  if (
    !track ||
    slides.length === 0 ||
    !previousButton ||
    !nextButton ||
    !progressThumb
  ) {
    return;
  }

  // Existing pages may contain carousel HTML rendered before controls used
  // aria-disabled. Remove the native attribute so initialization can preserve
  // focus at either endpoint.
  previousButton.disabled = false;
  nextButton.disabled = false;

  container.dataset.slidesInitialized = 'true';
  slides.forEach((slide, index) => {
    slide.setAttribute('role', 'group');
    slide.setAttribute('aria-posinset', index + 1);
    slide.setAttribute('aria-setsize', slides.length);
  });

  const updateControls = () => {
    const maximumScroll = Math.max(track.scrollWidth - track.clientWidth, 0);
    const scrollPosition = Math.min(Math.max(track.scrollLeft, 0), maximumScroll);
    const visibleRatio = track.scrollWidth
      ? Math.min(track.clientWidth / track.scrollWidth, 1)
      : 1;
    const progress = maximumScroll ? scrollPosition / maximumScroll : 0;

    previousButton.setAttribute('aria-disabled', scrollPosition <= 1);
    nextButton.setAttribute(
      'aria-disabled',
      scrollPosition >= maximumScroll - 1,
    );
    progressThumb.style.width = `${visibleRatio * 100}%`;
    progressThumb.style.left = `${progress * (1 - visibleRatio) * 100}%`;
  };

  const cardStep = () => {
    const gap = parseFloat(window.getComputedStyle(track).columnGap) || 0;
    const cardWidth = slides[0].getBoundingClientRect().width;
    return cardWidth + gap;
  };

  const scrollOneCard = (direction) => {
    const maximumScroll = Math.max(track.scrollWidth - track.clientWidth, 0);
    const startingPosition =
      requestedScrollPosition ??
      Math.min(Math.max(track.scrollLeft, 0), maximumScroll);
    requestedScrollPosition = Math.min(
      Math.max(startingPosition + direction * cardStep(), 0),
      maximumScroll,
    );
    const reduceMotion = window.matchMedia?.(
      '(prefers-reduced-motion: reduce)',
    ).matches;
    track.scrollTo({
      left: requestedScrollPosition,
      behavior: reduceMotion ? 'auto' : 'smooth',
    });

    window.clearTimeout(requestedScrollReset);
    requestedScrollReset = window.setTimeout(() => {
      requestedScrollPosition = null;
    }, 1000);
  };

  previousButton.addEventListener('click', () => {
    if (previousButton.getAttribute('aria-disabled') !== 'true') {
      scrollOneCard(-1);
    }
  });
  nextButton.addEventListener('click', () => {
    if (nextButton.getAttribute('aria-disabled') !== 'true') {
      scrollOneCard(1);
    }
  });
  container.addEventListener('keydown', (event) => {
    if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') return;

    event.preventDefault();
    scrollOneCard(event.key === 'ArrowLeft' ? -1 : 1);
  });
  track.addEventListener('scroll', updateControls, { passive: true });

  if (typeof ResizeObserver !== 'undefined') {
    const resizeObserver = new ResizeObserver(() => {
      if (!container.isConnected) {
        resizeObserver.disconnect();
        return;
      }
      updateControls();
    });
    resizeObserver.observe(track);
  }

  updateControls();
}

export function initializeSlides(root = document) {
  root.querySelectorAll(CAROUSEL_SELECTOR).forEach(initializeCarousel);
}
