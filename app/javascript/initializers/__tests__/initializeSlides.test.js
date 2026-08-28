import { initializeSlides } from '../initializeSlides';

function renderCarousel() {
  document.body.innerHTML = `
    <div class="ltag-slides ltag-slides--carousel">
      <div class="ltag-slides__viewport">
        <div class="ltag-slides__track" style="column-gap: 16px" tabindex="0">
          <div class="ltag-slide"></div>
          <div class="ltag-slide"></div>
          <div class="ltag-slide"></div>
        </div>
        <button class="ltag-slides__nav--prev" disabled></button>
        <button class="ltag-slides__nav--next" disabled></button>
      </div>
      <div class="ltag-slides__progress">
        <span class="ltag-slides__progress-thumb"></span>
      </div>
    </div>
  `;

  const container = document.querySelector('.ltag-slides');
  const track = container.querySelector('.ltag-slides__track');
  const slides = container.querySelectorAll('.ltag-slide');

  Object.defineProperties(track, {
    clientWidth: { configurable: true, value: 300 },
    scrollWidth: { configurable: true, value: 900 },
    scrollLeft: { configurable: true, value: 0, writable: true },
  });
  track.scrollTo = jest.fn();
  slides.forEach((slide) => {
    slide.getBoundingClientRect = jest.fn(() => ({ width: 240 }));
  });

  return { container, track, slides };
}

describe('initializeSlides', () => {
  beforeEach(() => {
    window.matchMedia = jest.fn(() => ({ matches: false }));
  });

  afterEach(() => {
    document.body.innerHTML = '';
    jest.restoreAllMocks();
  });

  it('initializes card metadata and the scroll controls', () => {
    const { container, track, slides } = renderCarousel();

    initializeSlides();

    expect(container.dataset.slidesInitialized).toBe('true');
    expect(slides[1].getAttribute('role')).toBe('group');
    expect(slides[1].getAttribute('aria-posinset')).toBe('2');
    expect(slides[1].getAttribute('aria-setsize')).toBe('3');
    expect(
      container
        .querySelector('.ltag-slides__nav--prev')
        .getAttribute('aria-disabled'),
    ).toBe('true');
    expect(
      container
        .querySelector('.ltag-slides__nav--next')
        .getAttribute('aria-disabled'),
    ).toBe('false');
    expect(container.querySelector('.ltag-slides__nav--prev').disabled).toBe(
      false,
    );
    expect(container.querySelector('.ltag-slides__nav--next').disabled).toBe(
      false,
    );
    expect(
      container.querySelector('.ltag-slides__progress-thumb').style.width,
    ).toBe('33.33333333333333%');
    expect(track.scrollTo).not.toHaveBeenCalled();
  });

  it('scrolls by one card plus the gap without tracking an index', () => {
    const { container, track } = renderCarousel();
    initializeSlides();

    container.querySelector('.ltag-slides__nav--next').click();

    expect(track.scrollTo).toHaveBeenCalledWith({
      left: 256,
      behavior: 'smooth',
    });
  });

  it('updates disabled controls and progress from the native scroll position', () => {
    const { container, track } = renderCarousel();
    initializeSlides();
    track.scrollLeft = 600;

    track.dispatchEvent(new Event('scroll'));

    expect(
      container
        .querySelector('.ltag-slides__nav--prev')
        .getAttribute('aria-disabled'),
    ).toBe('false');
    expect(
      container
        .querySelector('.ltag-slides__nav--next')
        .getAttribute('aria-disabled'),
    ).toBe('true');
    expect(
      container.querySelector('.ltag-slides__progress-thumb').style.left,
    ).toBe('66.66666666666667%');
  });

  it('uses instant scrolling when reduced motion is preferred', () => {
    const { container, track } = renderCarousel();
    window.matchMedia = jest.fn(() => ({ matches: true }));
    initializeSlides();

    container.querySelector('.ltag-slides__nav--next').click();

    expect(track.scrollTo).toHaveBeenCalledWith({
      left: 256,
      behavior: 'auto',
    });
  });

  it('scrolls one card when the track or its controls have keyboard focus', () => {
    const { container, track } = renderCarousel();
    initializeSlides();
    const nextButton = container.querySelector('.ltag-slides__nav--next');

    track.focus();
    track.dispatchEvent(
      new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true }),
    );

    nextButton.focus();
    nextButton.dispatchEvent(
      new KeyboardEvent('keydown', { key: 'ArrowLeft', bubbles: true }),
    );

    expect(track.scrollTo).toHaveBeenNthCalledWith(1, {
      left: 256,
      behavior: 'smooth',
    });
    expect(track.scrollTo).toHaveBeenNthCalledWith(2, {
      left: 0,
      behavior: 'smooth',
    });
  });

  it('keeps a disabled end control focused so arrow keys can reverse', () => {
    const { container, track } = renderCarousel();
    initializeSlides();
    const nextButton = container.querySelector('.ltag-slides__nav--next');
    nextButton.focus();
    track.scrollLeft = 600;

    track.dispatchEvent(new Event('scroll'));

    expect(nextButton.getAttribute('aria-disabled')).toBe('true');
    expect(document.activeElement).toBe(nextButton);

    nextButton.dispatchEvent(
      new KeyboardEvent('keydown', { key: 'ArrowLeft', bubbles: true }),
    );
    expect(track.scrollTo).toHaveBeenLastCalledWith({
      left: 344,
      behavior: 'smooth',
    });
  });

  it('accumulates rapid key presses against a bounded pending target', () => {
    const { container, track } = renderCarousel();
    initializeSlides();
    const nextButton = container.querySelector('.ltag-slides__nav--next');
    nextButton.focus();

    ['ArrowRight', 'ArrowRight', 'ArrowRight', 'ArrowLeft', 'ArrowLeft'].forEach(
      (key) => {
        nextButton.dispatchEvent(
          new KeyboardEvent('keydown', { key, bubbles: true }),
        );
      },
    );

    expect(track.scrollTo.mock.calls.map(([options]) => options.left)).toEqual([
      256, 512, 600, 344, 88,
    ]);
    expect(document.activeElement).toBe(nextButton);
  });

  it('does not attach duplicate controls when initialized again', () => {
    const { container, track } = renderCarousel();
    initializeSlides();
    initializeSlides();

    container.querySelector('.ltag-slides__nav--next').click();

    expect(track.scrollTo).toHaveBeenCalledTimes(1);
  });
});
